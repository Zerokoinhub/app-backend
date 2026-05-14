const User = require('../models/User');
const crypto = require('crypto');
const { getTodayUTC, getNextSessionUnlockTime, SESSIONS_PER_DAY, SESSION_INTERVAL } = require('../utils/session');
const geoip = require('geoip-lite');
const { getName } = require('country-list');
const NotificationService = require('../services/notificationService');
const notificationService = new NotificationService();

const generateInviteCode = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let code = '';
  for (let i = 0; i < 34; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

/* =========================
   🔥 RANK SYSTEM (SINGLE SOURCE)
========================= */

const getUserRank = async (firebaseUid) => {
  const users = await User.find({})
    .sort({ balance: -1 })
    .select('firebaseUid')
    .lean();

  const index = users.findIndex(u => u.firebaseUid === firebaseUid);
  return index === -1 ? null : index + 1;
};

const sendBonusNotification = async (user, rank, bonusAmount) => {
  try {
    console.log(`📱 Attempting to send notification to ${user.email}`);
    
    const activeTokens = user.fcmTokens?.filter(t => t.isActive && t.token) || [];
    
    if (activeTokens.length === 0) {
      console.log(`⚠️ No active FCM tokens for user ${user.email}`);
      return;
    }
    
    for (const tokenInfo of activeTokens) {
      const result = await notificationService.sendRankBonusNotificationWithActions(
        tokenInfo.token,
        rank,
        bonusAmount,
        user.name || 'Miner'
      );
      console.log(`📱 Result: ${JSON.stringify(result)}`);
    }
    
    console.log(`✅ Bonus notification sent to ${user.email} for rank ${rank}`);
  } catch (error) {
    console.error('Failed to send bonus notification:', error);
  }
};

/* =========================
   🎁 BONUS ENGINE (CORE FIXED LOGIC)
========================= */

const checkAndGiveBonusOnRankChange = async (firebaseUid) => {
  try {
    const user = await User.findOne({ firebaseUid });
    if (!user) return false;

    const currentRank = await getUserRank(firebaseUid);
    const previousRank = user.lastBonusRank || 999;

    console.log("📊 Rank Check:", { currentRank, previousRank, user: user.email });

    // Update rank always
    user.lastBonusRank = currentRank;

    const rankImproved = currentRank && currentRank <= 3 && currentRank < previousRank;

    if (!rankImproved) {
      await user.save();
      return false;
    }

    const bonusAmount = currentRank === 1 ? 20 : currentRank === 2 ? 10 : currentRank === 3 ? 5 : 0;

    if (bonusAmount <= 0) {
      await user.save();
      return false;
    }

    // Prevent overwrite bug
    if (user.pendingBonus && !user.pendingBonus.claimed) {
      console.log("⚠️ Pending bonus already exists, skipping");
      await user.save();
      return false;
    }

    user.pendingBonus = {
      amount: bonusAmount,
      rank: currentRank,
      claimed: false,
      earnedAt: new Date()
    };

    user.markModified('pendingBonus');
    user.lastBonusClaimTime = null;

    await user.save();

    console.log("✅ Bonus Created:", user.pendingBonus);
    
    // Send notification
    await sendBonusNotification(user, currentRank, bonusAmount);

    return true;

  } catch (err) {
    console.error("❌ Bonus Error:", err);
    return false;
  }
};

/* =========================
   🎁 CLAIM BONUS (FIXED)
========================= */

const claimBonusFromNotification = async (req, res) => {
  try {
    const { uid } = req.user;

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    if (!user.pendingBonus || user.pendingBonus.claimed) {
      return res.status(400).json({
        success: false,
        message: "No pending bonus"
      });
    }

    const bonus = user.pendingBonus.amount;
    const rank = user.pendingBonus.rank;

    user.balance = (user.balance || 0) + bonus;

    user.pendingBonus.claimed = true;
    user.pendingBonus.claimedAt = new Date();
    user.lastBonusClaimTime = new Date();
    user.lastBonusRank = rank;
    user.lastBonusAmount = bonus;

    await user.save();

    console.log(`✅ Bonus claimed: +${bonus} coins to ${user.email}, new balance: ${user.balance}`);

    return res.json({
      success: true,
      message: `+${bonus} coins added`,
      data: {
        bonusAmount: bonus,
        rank: rank,
        newBalance: user.balance
      }
    });

  } catch (err) {
    console.error('Claim error:', err);
    res.status(500).json({ error: err.message });
  }
};

const cancelBonusFromNotification = async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    if (!user.pendingBonus || user.pendingBonus.claimed) {
      return res.status(400).json({ 
        success: false, 
        message: 'No pending bonus to cancel' 
      });
    }
    
    user.pendingBonus = null;
    await user.save();
    
    res.json({
      success: true,
      message: 'Bonus cancelled',
      data: {
        newBalance: user.balance
      }
    });
    
  } catch (error) {
    console.error('Error cancelling bonus:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

/* =========================
   📊 BONUS STATUS CHECK
========================= */

const checkBonusStatus = async (req, res) => {
  try {
    const { uid } = req.user;

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ success: false });
    }

    const rank = await getUserRank(uid);
    const pending = user.pendingBonus;

    const isInTop3 = rank >= 1 && rank <= 3;
    const hasPendingBonus = pending && pending.claimed === false;
    const canClaim = isInTop3 && hasPendingBonus;

    res.json({
      success: true,
      data: {
        rank: rank || 0,
        isInTop3,
        hasPendingBonus,
        canClaim,
        bonusAmount: pending?.amount || 0,
        alreadyClaimed: alreadyClaimed: user.pendingBonus?.claimed === true
        hoursLeft: 0,
        lastBonusRank: user.lastBonusRank,
        rankImproved: hasPendingBonus
      }
    });

  } catch (err) {
    console.error('checkBonusStatus error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* =========================
   💰 UPDATE BALANCE (FIXED)
========================= */

const updateUserBalance = async (req, res) => {
  try {
    const { uid } = req.user;
    const { amount } = req.body;

    if (typeof amount !== "number") {
      return res.status(400).json({ message: "Amount must be number" });
    }

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) return res.status(404).json({ message: "User not found" });

    user.balance = (user.balance || 0) + amount;
    await user.save();

    // 🔥 IMPORTANT: pass ONLY UID
    await checkAndGiveBonusOnRankChange(uid);

    res.json({
      success: true,
      newBalance: user.balance
    });

  } catch (err) {
    console.error('Update balance error:', err);
    res.status(500).json({ error: err.message });
  }
};

/* =========================
   🏆 LEADERBOARD (FIXED)
========================= */

const getCompleteLeaderboard = async (req, res) => {
  try {
    const allUsers = await User.find({})
      .select('name email balance photoURL')
      .sort({ balance: -1 })
      .lean();

    const formattedUsers = allUsers.map((user, index) => ({
      rank: index + 1,
      id: user._id,
      name: user.name || 'Anonymous',
      email: user.email,
      balance: Number(user.balance) || 0,
      photoURL: user.photoURL || null,
    }));

    const top10Users = formattedUsers.slice(0, 10);

    res.json({
      success: true,
      data: {
        topUsers: top10Users,
        allUsers: formattedUsers,
        stats: {
          totalUsers: formattedUsers.length,
          highestBalance: formattedUsers[0]?.balance || 0,
          lastUpdated: new Date().toISOString()
        }
      }
    });

  } catch (error) {
    console.error('❌ Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

/* =========================
   🔧 ADMIN UPDATE BALANCE
========================= */

const updateUserBalanceByAdmin = async (req, res) => {
  try {
    const { userId, newBalance } = req.body;
    
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false });
    }
    
    user.balance = newBalance;
    await user.save();
    
    const bonusCreated = await checkAndGiveBonusOnRankChange(user.firebaseUid);
    
    res.json({ 
      success: true, 
      message: 'Balance updated successfully',
      bonusCreated: bonusCreated
    });
    
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

/* =========================
   🔄 SYNC USER RANK
========================= */

const syncUserRank = async (req, res) => {
  try {
    const { userId } = req.body;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    const bonusCreated = await checkAndGiveBonusOnRankChange(user.firebaseUid);
    
    res.json({ success: true, bonusCreated });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

const claimDailyBonus = async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const currentRank = await getUserRank(uid);

    if (currentRank < 1 || currentRank > 3) {
      return res.json({ success: false, message: 'You are not in top 3' });
    }

    const now = new Date();

    if (user.lastBonusClaimTime) {
      const hours = (now - new Date(user.lastBonusClaimTime)) / (1000 * 60 * 60);
      if (hours < 24) {
        return res.json({ success: false, message: `Wait ${Math.ceil(24 - hours)} hours` });
      }
    }

    let bonusAmount = 0;
    if (currentRank === 1) bonusAmount = 20;
    else if (currentRank === 2) bonusAmount = 10;
    else if (currentRank === 3) bonusAmount = 5;

    user.balance = (user.balance || 0) + bonusAmount;
    user.lastBonusClaimTime = now;
    user.lastBonusRank = currentRank;
    user.lastBonusAmount = bonusAmount;

    await user.save();

    res.json({
      success: true,
      message: `+${bonusAmount} coins added`,
      data: { rank: currentRank, bonusAmount, newBalance: user.balance }
    });

  } catch (error) {
    console.error('❌ Claim bonus error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

const triggerRankBonusNotification = async (req, res) => {
  try {
    const { uid } = req.user;
    const bonusCreated = await checkAndGiveBonusOnRankChange(uid);
    
    res.json({ 
      success: bonusCreated, 
      message: bonusCreated ? 'Bonus created' : 'No bonus created'
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

/* =========================
   📤 EXPORTS (CLEAN)
========================= */

// Auth & User
exports.registerUser = async (req, res) => {
  try {
    let inviteCode = generateInviteCode();
    while (await User.findOne({ inviteCode })) {
      inviteCode = generateInviteCode();
    }
    const user = new User({ inviteCode });
    await user.save();
    res.status(201).json({ inviteCode });
  } catch (error) {
    res.status(500).json({ message: 'Error registering user' });
  }
};

exports.syncFirebaseUser = async (req, res) => {
  try {
    const { uid, email, name } = req.user;
    let user = await User.findOne({ firebaseUid: uid });
    const ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
    const geo = geoip.lookup(ip);
    const country = geo ? getName(geo.country) : null;

    if (user) {
      user.name = name || user.name;
      user.email = email || user.email;
      user.country = country;
      await user.save();

      res.status(200).json({
        message: 'User data updated successfully',
        user: {
          firebaseUid: user.firebaseUid,
          name: user.name,
          email: user.email,
          inviteCode: user.inviteCode,
          recentAmount: user.recentAmount,
          balance: user.balance,
          walletAddresses: user.walletAddresses,
          country: user.country
        }
      });
    } else {
      let inviteCode = generateInviteCode();
      while (await User.findOne({ inviteCode })) {
        inviteCode = generateInviteCode();
      }

      const newUser = new User({
        firebaseUid: uid,
        name,
        email,
        inviteCode,
        country
      });

      await newUser.save();

      res.status(201).json({
        message: 'User created successfully',
        user: {
          firebaseUid: newUser.firebaseUid,
          name: newUser.name,
          email: newUser.email,
          inviteCode: newUser.inviteCode,
          recentAmount: newUser.recentAmount,
          balance: newUser.balance,
          walletAddresses: newUser.walletAddresses,
          country: newUser.country
        }
      });
    }
  } catch (error) {
    console.error('Firebase user sync error:', error.message);
    res.status(500).json({ message: 'Error syncing user data', error: error.message });
  }
};

exports.getUserProfile = async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json({ user });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching user profile', error: error.message });
  }
};

exports.updateUserProfile = async (req, res) => {
  try {
    const { displayName, photoURL } = req.body;
    const userId = req.user.uid;
    const userEmail = req.user.email;

    if (!displayName || displayName.trim() === '') {
      return res.status(400).json({ success: false, message: "Display name is required" });
    }

    let user = await User.findOne({ firebaseUid: userId });
    
    if (!user) {
      let inviteCode = generateInviteCode();
      while (await User.findOne({ inviteCode })) {
        inviteCode = generateInviteCode();
      }

      user = new User({
        firebaseUid: userId,
        name: displayName.trim(),
        email: userEmail,
        inviteCode: inviteCode,
        photoURL: photoURL || null,
        balance: 0,
        calculatorUsage: 0,
        sessionsCompleted: [],
        createdAt: new Date(),
        updatedAt: new Date()
      });

      await user.save();
    } else {
      user.name = displayName.trim();
      if (photoURL !== undefined) user.photoURL = photoURL;
      user.updatedAt = new Date();
      await user.save();
    }

    res.status(200).json({ success: true, message: "Profile updated successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: "Internal server error", error: error.message });
  }
};

exports.uploadProfilePicture = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'No file uploaded' });
    }

    const userId = req.user.uid;
    const photoURL = req.file.path;
    let user = await User.findOne({ firebaseUid: userId });

    if (!user) {
      user = new User({
        firebaseUid: userId,
        email: req.user.email || '',
        name: req.user.name || '',
        photoURL: photoURL,
        createdAt: new Date(),
        updatedAt: new Date()
      });
    } else {
      user.photoURL = photoURL;
      user.updatedAt = new Date();
    }

    await user.save();

    res.json({ success: true, message: 'Profile picture uploaded successfully', photoURL });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to upload profile picture' });
  }
};

exports.getUserDetails = async (req, res) => {
  try {
    const userId = req.user.uid;
    const user = await User.findOne({ firebaseUid: userId });
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    res.json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, error: 'Failed to get user details' });
  }
};

// Referral
exports.getInviteDetails = async (req, res) => {
  try {
    const { inviteCode } = req.params;
    const user = await User.findOne({ inviteCode });
    if (!user) return res.status(404).json({ message: 'Invite not found' });
    res.json({ inviteCode, recentAmount: user.recentAmount });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching invite details' });
  }
};

exports.processReferral = async (req, res) => {
  try {
    const { inviteCode, referredBy } = req.body;
    const referrer = await User.findOne({ inviteCode: referredBy });
    if (!referrer) return res.status(400).json({ message: 'Invalid referrer invite code' });

    let newInviteCode = generateInviteCode();
    while (await User.findOne({ inviteCode: newInviteCode })) {
      newInviteCode = generateInviteCode();
    }

    const newUser = new User({ inviteCode: newInviteCode, referredBy });
    await newUser.save();

    referrer.recentAmount += 50;
    referrer.balance = (referrer.balance || 0) + 50;
    await referrer.save();

    res.status(200).json({ message: 'Referral processed', recentAmount: referrer.recentAmount });
  } catch (error) {
    console.error('Referral error:', error.message);
    res.status(500).json({ message: 'Error processing referral', error: error.message });
  }
};

// Sessions
exports.getUserSessions = async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (!user.sessions || user.sessions.length === 0) {
      user.sessions = [];
      for (let i = 1; i <= SESSIONS_PER_DAY; i++) {
        user.sessions.push({
          sessionNumber: i,
          unlockedAt: i === 1 ? new Date() : null,
          completedAt: null,
          nextUnlockAt: null,
          isClaimed: false,
          isLocked: i > 1
        });
      }
      await user.save();
    }

    const now = new Date();
    let sessionsUpdated = false;

    for (let session of user.sessions) {
      if (session.isLocked && session.nextUnlockAt && now >= session.nextUnlockAt) {
        session.isLocked = false;
        session.unlockedAt = new Date();
        session.nextUnlockAt = null;
        sessionsUpdated = true;
      }
    }

    if (sessionsUpdated) {
      await user.save();
    }

    res.status(200).json({ sessions: user.sessions });
  } catch (error) {
    console.error('Get user sessions error:', error.message);
    res.status(500).json({ message: 'Error fetching user sessions', error: error.message });
  }
};

exports.unlockNextSession = async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const nextSession = user.sessions.find(session => !session.unlockedAt);
    if (!nextSession) {
      return res.status(400).json({ message: 'No more sessions to unlock' });
    }

    nextSession.unlockedAt = new Date();
    await user.save();

    res.status(200).json({ message: 'Session unlocked successfully', session: nextSession });
  } catch (error) {
    console.error('Unlock session error:', error.message);
    res.status(500).json({ message: 'Error unlocking session', error: error.message });
  }
};

exports.completeSession = async (req, res) => {
  try {
    const { uid } = req.user;
    const { sessionNumber } = req.body;

    if (!sessionNumber || sessionNumber < 1 || sessionNumber > 4) {
      return res.status(400).json({ message: 'Valid sessionNumber (1-4) is required' });
    }

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const session = user.sessions.find(s => s.sessionNumber === sessionNumber);
    if (!session) {
      return res.status(404).json({ message: 'Session not found' });
    }

    if (!session.unlockedAt) {
      return res.status(400).json({ message: 'Session is not unlocked yet' });
    }

    if (session.completedAt) {
      return res.status(400).json({ message: 'Session is already completed' });
    }

    session.completedAt = new Date();
    session.isClaimed = true;

    let nextSessionNumber;
    if (parseInt(sessionNumber) === 4) {
      nextSessionNumber = 1;
      user.sessions.forEach(s => {
        if (s.sessionNumber === 1) {
          s.isLocked = true;
          s.nextUnlockAt = new Date(Date.now() + SESSION_INTERVAL);
          s.completedAt = null;
          s.isClaimed = false;
          s.unlockedAt = null;
        } else {
          s.isLocked = true;
          s.nextUnlockAt = null;
          s.completedAt = null;
          s.isClaimed = false;
          s.unlockedAt = null;
        }
      });
    } else {
      nextSessionNumber = sessionNumber + 1;
      const nextSession = user.sessions.find(s => s.sessionNumber === nextSessionNumber);
      if (nextSession) {
        nextSession.isLocked = true;
        nextSession.nextUnlockAt = new Date(Date.now() + SESSION_INTERVAL);
        nextSession.completedAt = null;
        nextSession.isClaimed = false;
        nextSession.unlockedAt = null;
      }
    }

    await user.save();
    res.status(200).json({ message: 'Session completed successfully', session: session });
  } catch (error) {
    console.error('Complete session error:', error.message);
    res.status(500).json({ message: 'Error completing session', error: error.message });
  }
};

exports.resetUserSessions = async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.sessions.forEach(s => {
      s.completedAt = null;
      s.isClaimed = false;
      s.isLocked = s.sessionNumber === 1 ? false : true;
      s.nextUnlockAt = null;
      s.unlockedAt = s.sessionNumber === 1 ? new Date() : null;
    });

    await user.save();
    res.status(200).json({ message: 'Sessions reset successfully', sessions: user.sessions });
  } catch (error) {
    console.error('Reset sessions error:', error.message);
    res.status(500).json({ message: 'Error resetting sessions', error: error.message });
  }
};

// Wallet
exports.updateWalletAddress = async (req, res) => {
  try {
    const { uid } = req.user;
    const { walletType, walletAddress } = req.body;

    if (!walletType || walletAddress === undefined || walletAddress === null) {
      return res.status(400).json({ message: 'walletType and walletAddress are required' });
    }

    if (walletAddress !== '' && (!walletAddress.startsWith('0x') || walletAddress.length !== 42)) {
      return res.status(400).json({ message: 'Invalid wallet address format' });
    }

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (walletType === 'metamask') {
      user.walletAddresses.metamask = walletAddress;
      user.walletStatus = walletAddress === '' ? 'Not Connected' : 'Connected';
    } else if (walletType === 'trustWallet') {
      user.walletAddresses.trustWallet = walletAddress;
      user.walletStatus = walletAddress === '' ? 'Not Connected' : 'Connected';
    } else {
      return res.status(400).json({ message: 'Invalid walletType' });
    }

    await user.save();
    res.status(200).json({ message: 'Wallet address updated successfully', walletAddresses: user.walletAddresses });
  } catch (error) {
    console.error('Update wallet address error:', error.message);
    res.status(500).json({ message: 'Error updating wallet address', error: error.message });
  }
};

// Utility
exports.getUserCount = async (req, res) => {
  try {
    const count = await User.countDocuments();
    res.status(200).json({ success: true, count });
  } catch (error) {
    console.error('Get user count error:', error.message);
    res.status(500).json({ success: false, message: 'Error getting user count', error: error.message });
  }
};

exports.incrementCalculatorUsage = async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    user.calculatorUsage = (user.calculatorUsage || 0) + 1;
    await user.save();
    res.status(200).json({ calculatorUsage: user.calculatorUsage });
  } catch (error) {
    console.error('Increment calculator usage error:', error.message);
    res.status(500).json({ message: 'Error incrementing calculator usage', error: error.message });
  }
};

// Notifications
exports.updateFCMToken = async (req, res) => {
  try {
    const { uid } = req.user;
    const { fcmToken, deviceId, platform } = req.body;

    if (!fcmToken) {
      return res.status(400).json({ message: 'FCM token is required' });
    }

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (!user.fcmTokens) {
      user.fcmTokens = [];
    }

    const existingTokenIndex = user.fcmTokens.findIndex(t => t.token === fcmToken);

    if (existingTokenIndex !== -1) {
      user.fcmTokens[existingTokenIndex].lastUsed = new Date();
      user.fcmTokens[existingTokenIndex].isActive = true;
      if (deviceId) user.fcmTokens[existingTokenIndex].deviceId = deviceId;
      if (platform) user.fcmTokens[existingTokenIndex].platform = platform;
    } else {
      user.fcmTokens.push({
        token: fcmToken,
        deviceId: deviceId || null,
        platform: platform || null,
        isActive: true,
        lastUsed: new Date(),
        createdAt: new Date()
      });
    }

    const validation = await notificationService.validateFCMToken(fcmToken);
    if (!validation.valid) {
      console.warn('Invalid FCM token provided:', fcmToken);
      if (existingTokenIndex !== -1) {
        user.fcmTokens[existingTokenIndex].isActive = false;
      } else {
        user.fcmTokens[user.fcmTokens.length - 1].isActive = false;
      }
    }

    await user.save();
    res.status(200).json({ message: 'FCM token updated successfully', tokenValid: validation.valid });
  } catch (error) {
    console.error('Update FCM token error:', error.message);
    res.status(500).json({ message: 'Error updating FCM token', error: error.message });
  }
};

exports.removeFCMToken = async (req, res) => {
  try {
    const { uid } = req.user;
    const { fcmToken } = req.body;

    if (!fcmToken) {
      return res.status(400).json({ message: 'FCM token is required' });
    }

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (!user.fcmTokens) {
      return res.status(404).json({ message: 'No FCM tokens found' });
    }

    user.fcmTokens = user.fcmTokens.filter(t => t.token !== fcmToken);
    await user.save();
    res.status(200).json({ message: 'FCM token removed successfully' });
  } catch (error) {
    console.error('Remove FCM token error:', error.message);
    res.status(500).json({ message: 'Error removing FCM token', error: error.message });
  }
};

exports.updateNotificationSettings = async (req, res) => {
  try {
    const { uid } = req.user;
    const { sessionUnlocked, pushEnabled } = req.body;

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (!user.notificationSettings) {
      user.notificationSettings = { sessionUnlocked: true, pushEnabled: true };
    }

    if (typeof sessionUnlocked === 'boolean') user.notificationSettings.sessionUnlocked = sessionUnlocked;
    if (typeof pushEnabled === 'boolean') user.notificationSettings.pushEnabled = pushEnabled;

    await user.save();
    res.status(200).json({ message: 'Notification settings updated successfully', notificationSettings: user.notificationSettings });
  } catch (error) {
    console.error('Update notification settings error:', error.message);
    res.status(500).json({ message: 'Error updating notification settings', error: error.message });
  }
};

// Screenshots
const { uploadToFirebase } = require('../config/cloudinary');

exports.uploadScreenshots = async (req, res) => {
  try {
    const { uid } = req.user;
    if (!uid) {
      return res.status(401).json({ message: 'Unauthorized' });
    }
    
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({ message: 'No files uploaded' });
    }
    
    const urls = [];
    for (const file of req.files) {
      const url = await uploadToFirebase(file, uid);
      urls.push(url);
    }
    
    if (!user.screenshots) user.screenshots = [];
    user.screenshots.push(...urls);
    user.updatedAt = new Date();
    await user.save();
    
    res.status(200).json({ success: true, message: `${urls.length} screenshot(s) uploaded successfully`, urls, screenshots: user.screenshots });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ success: false, message: 'Error uploading screenshots', error: error.message });
  }
};

// Main exports
exports.getUserRank = getUserRank;
exports.checkAndGiveBonusOnRankChange = checkAndGiveBonusOnRankChange;
exports.claimBonusFromNotification = claimBonusFromNotification;
exports.cancelBonusFromNotification = cancelBonusFromNotification;
exports.checkBonusStatus = checkBonusStatus;
exports.updateUserBalance = updateUserBalance;
exports.updateUserBalanceByAdmin = updateUserBalanceByAdmin;
exports.getCompleteLeaderboard = getCompleteLeaderboard;
exports.syncUserRank = syncUserRank;
exports.claimDailyBonus = claimDailyBonus;
exports.triggerRankBonusNotification = triggerRankBonusNotification;
