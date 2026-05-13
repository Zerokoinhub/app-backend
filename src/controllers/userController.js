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
  for (let i = 0; i < 34; i++) {https://github.com/Zerokoinhub/app-backend/edit/main/src/controllers/userController.js
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};
// Admin panel - Update user balance function
const updateUserBalanceByAdmin = async (req, res) => {
  try {
    const { userId, newBalance } = req.body;
    
    // Get user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false });
    }
    
    const oldBalance = user.balance;
    
    // ✅ GET OLD RANK BEFORE UPDATE
    const oldTopUsers = await User.find({}).sort({ balance: -1 }).limit(10).lean();
    const oldRank = oldTopUsers.findIndex(u => u._id.toString() === userId) + 1;
    
    // Update balance
    user.balance = newBalance;
    await user.save();
    
    // ✅ GET NEW RANK AFTER UPDATE
    const newTopUsers = await User.find({}).sort({ balance: -1 }).limit(10).lean();
    const newRank = newTopUsers.findIndex(u => u._id.toString() === userId) + 1;
    
    console.log(`📊 Admin update - User: ${user.email}`);
    console.log(`   Old Rank: ${oldRank}, New Rank: ${newRank}`);
    
    // ✅ CHECK IF RANK IMPROVED
    if (newRank < oldRank && newRank >= 1 && newRank <= 3) {
      const bonusAmount = newRank === 1 ? 20 : newRank === 2 ? 10 : 5;
      
      console.log(`🎉 RANK IMPROVED! Creating pending bonus...`);
      
      // ✅ CREATE PENDING BONUS AUTOMATICALLY
      user.pendingBonus = {
        amount: bonusAmount,
        rank: newRank,
        claimed: false,
        earnedAt: new Date()
      };
      
      // ✅ RESET TIMER
      user.lastBonusClaimTime = null;
      
      await user.save();
      
      console.log(`✅ Pending bonus created for rank ${newRank}`);
      
      // ✅ OPTIONAL: Send push notification
      await sendBonusNotification(user, newRank, bonusAmount);
    }
    
    res.json({ 
      success: true, 
      message: 'Balance updated successfully',
      rankImproved: newRank < oldRank,
      newRank: newRank,
      oldRank: oldRank
    });
    
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};
// userController.js - Backend
// Check bonus status for current user
// ============ REAL-TIME BONUS ON POSITION CHANGE ============

// Check and give bonus when user's rank changes
const sendBonusNotification = async (user, rank, bonusAmount) => {
  try {
    console.log(`📱 Attempting to send notification to ${user.email}`);
    console.log(`   FCM Tokens: ${JSON.stringify(user.fcmTokens)}`);
    
    const activeTokens = user.fcmTokens?.filter(t => t.isActive && t.token) || [];
    
    console.log(`   Active tokens count: ${activeTokens.length}`);
    
    if (activeTokens.length === 0) {
      console.log(`⚠️ No active FCM tokens for user ${user.email}`);
      return;
    }
    
    const NotificationService = require('../services/notificationService');
    const notificationService = new NotificationService();
    
    for (const tokenInfo of activeTokens) {
      console.log(`📱 Sending to token: ${tokenInfo.token.substring(0, 20)}...`);
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
// userController.js - Check this function
const checkAndGiveBonusOnRankChange = async (user, oldBalance, newBalance) => {
  try {
    // Get current rank
    const topUsers = await User.find({}).sort({ balance: -1 }).limit(3).lean();
    const userRank = topUsers.findIndex(u => u.firebaseUid === user.firebaseUid) + 1;
    
    console.log(`🔍 Rank Check - User: ${user.email}`);
    console.log(`   Current Rank: ${userRank}`);
    console.log(`   Last Bonus Rank: ${user.lastBonusRank}`);
    console.log(`   Last Claim Time: ${user.lastBonusClaimTime}`);
    
    // ✅ KYA RANK IMPROVE HUA HAI?
    const rankImproved = user.lastBonusRank != null && userRank < user.lastBonusRank;
    
    // ✅ AGAR RANK TOP 3 MEIN HAI
    if (userRank >= 1 && userRank <= 3) {
      
      // ✅ JAB BHI RANK IMPROVE HO - PURANA TIMER RESET KARO!
      if (rankImproved) {
        let bonusAmount = userRank === 1 ? 20 : userRank === 2 ? 10 : 5;
        
        console.log(`🎉 RANK IMPROVED! Creating pending bonus for Rank ${userRank}, Amount ${bonusAmount}`);
        
        // ✅ IMPORTANT: Purana timer reset karo
        user.lastBonusClaimTime = null;  // Reset claim time
        user.lastBonusRank = null;        // Reset last rank (purana hatao)
        user.bonusTimer = {
          lastClaimTime: null,
          nextClaimTime: null,
          autoBonusGiven: false,
          pendingBonus: false
        };
        
        // Create pending bonus immediately
        user.pendingBonus = {
          amount: bonusAmount,
          rank: userRank,
          claimed: false,
          earnedAt: new Date()
        };
        
        await user.save();
        
        // Send notification
        await sendBonusNotification(user, userRank, bonusAmount);
        
        return true;
      }
      // ✅ AGAR RANK SAME HAI AUR 24 HOURS HO GAYE HAIN
      else if (!user.lastBonusClaimTime || (new Date() - user.lastBonusClaimTime) >= 24 * 60 * 60 * 1000) {
        let bonusAmount = userRank === 1 ? 20 : userRank === 2 ? 10 : 5;
        
        console.log(`🎉 Time-based bonus for Rank ${userRank}, Amount ${bonusAmount}`);
        
        user.pendingBonus = {
          amount: bonusAmount,
          rank: userRank,
          claimed: false,
          earnedAt: new Date()
        };
        
        await user.save();
        await sendBonusNotification(user, userRank, bonusAmount);
        
        return true;
      }
    }
    
    console.log(`❌ No bonus created - Rank: ${userRank}, Improved: ${rankImproved}`);
    return false;
    
  } catch (error) {
    console.error('Error checking rank bonus:', error);
    return false;
  }
};// userController.js - Replace your claimBonusFromNotification with this
const claimBonusFromNotification = async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    if (!user.pendingBonus || user.pendingBonus.claimed) {
      return res.status(400).json({ 
        success: false, 
        message: 'No pending bonus to claim' 
      });
    }
    
    const bonusAmount = user.pendingBonus.amount;
    const rank = user.pendingBonus.rank;
    
    // ✅ Add balance
    user.balance = (user.balance || 0) + bonusAmount;
    
    // ✅ Mark as claimed
    user.pendingBonus.claimed = true;
    user.pendingBonus.claimedAt = new Date();
    user.lastBonusClaimTime = new Date();
    user.lastBonusRank = rank;
    user.lastBonusAmount = bonusAmount;
    
    // ✅ Set next claim time (24 hours from now)
    user.bonusTimer = {
      lastClaimTime: new Date(),
      nextClaimTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
      autoBonusGiven: false,
      pendingBonus: false
    };
    
    await user.save();
    
    console.log(`✅ Bonus claimed: ${bonusAmount} coins added to ${user.email}, new balance: ${user.balance}`);
    
    res.json({
      success: true,
      message: `You claimed ${bonusAmount} coins!`,
      data: {
        bonusAmount: bonusAmount,
        rank: rank,
        newBalance: user.balance
      }
    });
    
  } catch (error) {
    console.error('Error claiming bonus:', error);
    res.status(500).json({ success: false, error: error.message });
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
    
    const bonusAmount = user.pendingBonus.amount;
    
    // ✅ DON'T subtract from balance (kyunki balance me add nahi kiya tha)
    // user.balance -= bonusAmount; // ❌ REMOVE THIS LINE
    
    user.pendingBonus = null;
    await user.save();
    
    res.json({
      success: true,
      message: 'Bonus cancelled',
      data: {
        removedAmount: bonusAmount,
        newBalance: user.balance
      }
    });
    
  } catch (error) {
    console.error('Error cancelling bonus:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};
// Update this function to trigger bonus check on balance change
const updateUserBalance = async (req, res) => {
  try {
    const { uid } = req.user;
    const { amount } = req.body;
    
    if (typeof amount !== 'number') {
      return res.status(400).json({ message: 'Amount must be a number' });
    }
    
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const oldBalance = user.balance;
    user.balance += amount;
    await user.save();
    
    // ✅ Check if rank changed and give bonus
    await checkAndGiveBonusOnRankChange(user, oldBalance, user.balance);
    
    res.status(200).json({
      message: 'User balance updated successfully',
      newBalance: user.balance,
    });
    
  } catch (error) {
    console.error('Update user balance error:', error.message);
    res.status(500).json({ message: 'Error updating user balance', error: error.message });
  }
};
const checkBonusStatus = async (req, res) => {
  try {
    const { uid } = req.user;
    const now = new Date();
    
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // ✅ PEHLE CHECK KARO - KYA PENDING BONUS HAI?
    if (user.pendingBonus && !user.pendingBonus.claimed) {
      console.log(`📊 Pending bonus exists: Rank ${user.pendingBonus.rank}`);
      return res.json({
        success: true,
        data: {
          rank: user.pendingBonus.rank,
          isInTop3: true,
          alreadyClaimed: false,
          canClaim: true,
          bonusAmount: user.pendingBonus.amount,
          hoursLeft: 0,
          hasPendingBonus: true
        }
      });
    }
    
    // Get current rank
    const topUsers = await User.find({})
      .select('firebaseUid balance')
      .sort({ balance: -1 })
      .limit(10)
      .lean();
    
    const userRank = topUsers.findIndex(u => u.firebaseUid === uid) + 1;
    const isInTop3 = userRank <= 3 && userRank > 0;
    
    // ✅ RANK IMPROVEMENT CHECK - AGAR IMPROVE HUA TO TIMER IGNORE KARO
    const lastBonusRank = user.lastBonusRank;
    const rankImproved = lastBonusRank != null && userRank < lastBonusRank;
    
    let alreadyClaimed = false;
    let hoursLeft = 0;
    
    // ✅ AGAR RANK IMPROVE HUA HAI TO ALREADY CLAIMED FALSE KARO
    if (!rankImproved) {
      const lastClaimTime = user.lastBonusClaimTime;
      if (lastClaimTime) {
        const hoursSinceLastClaim = (now - lastClaimTime) / (1000 * 60 * 60);
        alreadyClaimed = hoursSinceLastClaim < 24;
        hoursLeft = 24 - hoursSinceLastClaim;
      }
    } else {
      console.log(`🎯 RANK IMPROVED! Resetting timer for user ${user.email}`);
      alreadyClaimed = false;
      hoursLeft = 0;
    }
    
    let bonusAmount = 0;
    if (userRank === 1) bonusAmount = 20;
    else if (userRank === 2) bonusAmount = 10;
    else if (userRank === 3) bonusAmount = 5;
    
    // ✅ CAN CLAIM CONDITION
    let canClaim = false;
    
    if (isInTop3) {
      if (rankImproved) {
        canClaim = true;
        console.log(`🎯 RANK IMPROVED! Can claim immediately!`);
      } else if (!alreadyClaimed) {
        canClaim = true;
      }
    }
    
    console.log(`📊 Final Status: canClaim=${canClaim}, rankImproved=${rankImproved}, alreadyClaimed=${alreadyClaimed}`);
    
    res.json({
      success: true,
      data: {
        rank: userRank,
        isInTop3: isInTop3,
        alreadyClaimed: alreadyClaimed,
        rankImproved: rankImproved,
        canClaim: canClaim,
        bonusAmount: bonusAmount,
        hoursLeft: hoursLeft > 0 ? Math.ceil(hoursLeft) : 0,
        lastBonusRank: lastBonusRank
      }
    });
    
  } catch (error) {
    console.error('❌ Error checking bonus status:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};
const claimDailyBonus = async (req, res) => {
  try {
    const { uid } = req.user;
    const now = new Date();
    
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // Get top 3 users
    const topUsers = await User.find({})
      .sort({ balance: -1 })
      .limit(3)
      .lean();
    
    const userRank = topUsers.findIndex(u => u.firebaseUid === uid) + 1;
    
    if (userRank < 1 || userRank > 3) {
      return res.json({ success: false, message: 'You are not in top 3' });
    }
    
    // Check if 24 hours have passed for manual claim
    const nextClaimTime = user.bonusTimer?.nextClaimTime;
    let canClaim = false;
    let hoursLeft = 0;
    
    if (!nextClaimTime) {
      canClaim = true;
    } else {
      const hoursSinceLastClaim = (now - nextClaimTime) / (1000 * 60 * 60);
      canClaim = hoursSinceLastClaim >= 0;
      hoursLeft = -Math.min(0, hoursSinceLastClaim);
    }
    
    // Check if rank improved (can claim immediately)
    const rankImproved = user.lastBonusRank && userRank < user.lastBonusRank;
    
    if (!canClaim && !rankImproved) {
      return res.json({ 
        success: false, 
        message: `Auto bonus will be added in ${Math.ceil(hoursLeft)} hours` 
      });
    }
    
    let bonusAmount = 0;
    if (userRank === 1) bonusAmount = 20;
    else if (userRank === 2) bonusAmount = 10;
    else if (userRank === 3) bonusAmount = 5;
    
    const newBalance = (user.balance || 0) + bonusAmount;
    
    // Update bonus timer
    const nextClaim = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    
    await User.findOneAndUpdate(
      { firebaseUid: uid },
      { 
        $set: { 
          balance: newBalance,
          lastBonusClaimTime: now,
          lastBonusRank: userRank,
          lastBonusAmount: bonusAmount,
          'bonusTimer.lastClaimTime': now,
          'bonusTimer.nextClaimTime': nextClaim,
          'bonusTimer.autoBonusGiven': false,
          'bonusTimer.pendingBonus': false
        }
      }
    );
    
    res.json({
      success: true,
      message: `You got ${bonusAmount} coins!`,
      data: {
        bonusAmount: bonusAmount,
        newBalance: newBalance,
        oldBalance: newBalance - bonusAmount,
        rank: userRank,
        nextClaimTime: nextClaim.toISOString()
      }
    });
    
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
// ============ NEW: Complete Leaderboard Endpoint ============
const getCompleteLeaderboard = async (req, res) => {
  try {
    console.log('📊 Fetching complete leaderboard...');

    // Get all active users
    const allUsers = await User.find({})
      .select('name email balance photoURL')
      .sort({ balance: -1 })
      .lean();

    console.log(`✅ Total users: ${allUsers.length}`);

    // Format users with proper data
    const formattedUsers = allUsers.map((user, index) => ({
      rank: index + 1,
      id: user._id,
      name: user.name || 'Anonymous',
      email: user.email,
      balance: Number(user.balance) || 0,
      photoURL: user.photoURL || null,
    }));

    // Get top 10
    const top10Users = formattedUsers.slice(0, 10);

    res.json({
      success: true,
      data: {
        topUsers: top10Users,
        allUsers: formattedUsers, // Optional: agar sab chahiye toh
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
// ============ LEADERBOARD FUNCTIONS ============
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
    console.log('Processing referral:', { inviteCode, referredBy });

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

exports.syncFirebaseUser = async (req, res) => {
  try {
    const { uid, email, name } = req.user;
    console.log('🔥 Syncing Firebase user:', { uid, email, name });

    let user = await User.findOne({ firebaseUid: uid });
    console.log('🔍 Existing user check result:', user ? 'Found' : 'Not found');

    const ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
    const geo = geoip.lookup(ip);
    const country = geo ? getName(geo.country) : null;

    if (user) {
      console.log('📝 Updating existing user:', user.inviteCode);
      user.name = name || user.name;
      user.email = email || user.email;
      user.country = country;
      await user.save();
      console.log('✅ User updated successfully');

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
      console.log('✨ Creating new user for Firebase UID:', uid);
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
      console.log('✅ User created successfully with invite code:', inviteCode);

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

    res.status(200).json({
      user: {
        firebaseUid: user.firebaseUid,
        name: user.name,
        email: user.email,
        inviteCode: user.inviteCode,
        referredBy: user.referredBy,
        recentAmount: user.recentAmount,
        balance: user.balance,
        walletAddresses: user.walletAddresses,
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error('Get user profile error:', error.message);
    res.status(500).json({ message: 'Error fetching user profile', error: error.message });
  }
};

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

    res.status(200).json({
      message: 'Session unlocked successfully',
      session: nextSession
    });
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
        const countdownDuration = SESSION_INTERVAL;
        nextSession.isLocked = true;
        nextSession.nextUnlockAt = new Date(Date.now() + countdownDuration);
        nextSession.completedAt = null;
        nextSession.isClaimed = false;
        nextSession.unlockedAt = null;
      }
    }

    await user.save();

    const response = {
      message: 'Session completed successfully',
      session: session,
      nextSession: user.sessions.find(s => s.sessionNumber === nextSessionNumber),
      sessionsReset: parseInt(sessionNumber) === 4
    };

    console.log(`Session ${sessionNumber} completed. Response:`, JSON.stringify(response, null, 2));

    res.status(200).json(response);
  } catch (error) {
    console.error('Complete session error:', error.message);
    res.status(500).json({ message: 'Error completing session', error: error.message });
  }
};

exports.updateWalletAddress = async (req, res) => {
  try {
    const { uid } = req.user;
    const { walletType, walletAddress } = req.body;

    console.log(`🔄 Updating wallet address for user ${uid}:`, { walletType, walletAddress });

    if (!walletType || walletAddress === undefined || walletAddress === null) {
      console.log('❌ Backend: Validation failed - missing required fields');
      return res.status(400).json({ message: 'walletType and walletAddress are required' });
    }

    if (walletAddress !== '' && (!walletAddress.startsWith('0x') || walletAddress.length !== 42)) {
      return res.status(400).json({ message: 'Invalid wallet address format. Must be a valid Ethereum address (0x...)' });
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

    console.log(`✅ Wallet address updated successfully for user ${uid}`);

    res.status(200).json({
      message: 'Wallet address updated successfully',
      walletAddresses: user.walletAddresses
    });
  } catch (error) {
    console.error('Update wallet address error:', error.message);
    res.status(500).json({ message: 'Error updating wallet address', error: error.message });
  }
};

exports.getUserCount = async (req, res) => {
  try {
    const count = await User.countDocuments();
    res.status(200).json({ 
      success: true,      // ✅ ADDED!
      count: count 
    });
  } catch (error) {
    console.error('Get user count error:', error.message);
    res.status(500).json({ 
      success: false,     // ✅ ADDED!
      message: 'Error getting user count', 
      error: error.message 
    });
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

    res.status(200).json({
      message: 'Sessions reset successfully',
      sessions: user.sessions
    });
  } catch (error) {
    console.error('Reset sessions error:', error.message);
    res.status(500).json({ message: 'Error resetting sessions', error: error.message });
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

exports.updateUserBalance = async (req, res) => {
  try {
    const { uid } = req.user;
    const { amount } = req.body;

    if (typeof amount !== 'number') {
      return res.status(400).json({ message: 'Amount must be a number' });
    }

    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    user.balance = (user.balance || 0) + amount;
    await user.save();

    res.status(200).json({
      message: 'User balance updated successfully',
      newBalance: user.balance,
    });
  } catch (error) {
    console.error('Update user balance error:', error.message);
    res.status(500).json({ message: 'Error updating user balance', error: error.message });
  }
};

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

    res.status(200).json({
      message: 'FCM token updated successfully',
      tokenValid: validation.valid
    });
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

    res.status(200).json({
      message: 'FCM token removed successfully'
    });
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
      user.notificationSettings = {
        sessionUnlocked: true,
        pushEnabled: true
      };
    }

    if (typeof sessionUnlocked === 'boolean') {
      user.notificationSettings.sessionUnlocked = sessionUnlocked;
    }
    if (typeof pushEnabled === 'boolean') {
      user.notificationSettings.pushEnabled = pushEnabled;
    }

    await user.save();

    res.status(200).json({
      message: 'Notification settings updated successfully',
      notificationSettings: user.notificationSettings
    });
  } catch (error) {
    console.error('Update notification settings error:', error.message);
    res.status(500).json({ message: 'Error updating notification settings', error: error.message });
  }
};
// ✅ FIXED uploadScreenshots function
const { uploadToFirebase } = require('../config/cloudinary');

exports.uploadScreenshots = async (req, res) => {
  try {
    console.log('📸 Upload screenshots request received');
    
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
    
    // ✅ Firebase Storage se upload
    const urls = [];
    for (const file of req.files) {
      const url = await uploadToFirebase(file, uid);
      urls.push(url);
      console.log('📸 Uploaded to Firebase:', url);
    }
    
    if (!user.screenshots) user.screenshots = [];
    user.screenshots.push(...urls);
    user.updatedAt = new Date();
    await user.save();
    
    res.status(200).json({
      success: true,
      message: `${urls.length} screenshot(s) uploaded successfully`,
      urls: urls,
      screenshots: user.screenshots
    });
    
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ 
      success: false,
      message: 'Error uploading screenshots', 
      error: error.message 
    });
  }
};
exports.updateUserProfile = async (req, res) => {
  try {
    console.log("📝 Profile update request received");
    console.log("   User ID:", req.user.uid);
    console.log("   Request body:", req.body);

    const { displayName, photoURL } = req.body;
    const userId = req.user.uid;
    const userEmail = req.user.email;

    if (!displayName || displayName.trim() === '') {
      return res.status(400).json({
        success: false,
        message: "Display name is required"
      });
    }

    const user = await User.findOne({ firebaseUid: userId });
    
    if (!user) {
      console.log("⚠️ User not found, creating new user...");
      
      let inviteCode = generateInviteCode();
      while (await User.findOne({ inviteCode })) {
        inviteCode = generateInviteCode();
      }

      const newUser = new User({
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

      await newUser.save();
      console.log("✅ New user created with invite code:", inviteCode);

      return res.status(200).json({
        success: true,
        message: "Profile created successfully",
        data: {
          displayName: displayName.trim(),
          photoURL: photoURL || null,
          updatedAt: new Date().toISOString()
        }
      });
    }

    user.name = displayName.trim();
    if (photoURL !== undefined) {
      user.photoURL = photoURL;
    }
    user.updatedAt = new Date();

    await user.save();
    console.log("✅ User profile updated successfully");

    res.status(200).json({
      success: true,
      message: "Profile updated successfully",
      data: {
        displayName: displayName.trim(),
        photoURL: user.photoURL,
        updatedAt: user.updatedAt.toISOString()
      }
    });

  } catch (error) {
    console.error("❌ Error updating profile:", error);
    console.error("Stack trace:", error.stack);
    
    res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message
    });
  }
};

// ✅ SINGLE uploadProfilePicture function - NO DUPLICATES!
exports.uploadProfilePicture = async (req, res) => {
  try {
    console.log('📸 Profile picture upload request received');
    
    if (!req.file) {
      console.log('❌ No file uploaded');
      return res.status(400).json({ 
        success: false, 
        error: 'No file uploaded' 
      });
    }

    const userId = req.user.uid;
    console.log('   User ID:', userId);
    console.log('   Cloudinary file:', req.file);

    // Cloudinary returns secure_url in path property
    const photoURL = req.file.path;
    
    console.log('   Photo URL from Cloudinary:', photoURL);

    let user = await User.findOne({ firebaseUid: userId });

    if (!user) {
      console.log('   Creating new user entry...');
      user = new User({
        firebaseUid: userId,
        email: req.user.email || '',
        name: req.user.name || '',
        photoURL: photoURL,
        createdAt: new Date(),
        updatedAt: new Date()
      });
    } else {
      console.log('   Updating existing user:', user.email);
      user.photoURL = photoURL;
      user.updatedAt = new Date();
    }

    await user.save();
    console.log('   ✅ User saved successfully');

    res.json({
      success: true,
      message: 'Profile picture uploaded successfully',
      photoURL: photoURL
    });

  } catch (error) {
    console.error('❌ Error in uploadProfilePicture:', error);
    console.error('   Stack:', error.stack);
    
    res.status(500).json({ 
      success: false, 
      error: 'Failed to upload profile picture',
      details: process.env.NODE_ENV === 'production' ? undefined : error.message
    });
  }
};

exports.getUserDetails = async (req, res) => {
  try {
    const userId = req.user.uid;
    const user = await User.findOne({ firebaseUid: userId });

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.json({
      success: true,
      user: {
        firebaseUid: user.firebaseUid,
        name: user.name,
        email: user.email,
        photoURL: user.photoURL,
        inviteCode: user.inviteCode,
        balance: user.balance,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }
    });
  } catch (error) {
    console.error('❌ Error getting user details:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get user details'
    });
  }
};
// userController.js me add karein - END me

// Manual trigger for rank bonus notification
const triggerRankBonusNotification = async (req, res) => {
  try {
    const { uid } = req.user;
    console.log(`🔔 Manual trigger for user: ${uid}`);
    
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // Get current rank
    const topUsers = await User.find({}).sort({ balance: -1 }).limit(3).lean();
    const userRank = topUsers.findIndex(u => u.firebaseUid === uid) + 1;
    
    console.log(`   User rank: ${userRank}`);
    
    if (userRank >= 1 && userRank <= 3) {
      const bonusAmount = userRank === 1 ? 20 : userRank === 2 ? 10 : 5;
      
      // Check if already claimed today
      const now = new Date();
      const lastClaimTime = user.lastBonusClaimTime;
      let alreadyClaimed = false;
      
      if (lastClaimTime) {
        const hoursSinceLastClaim = (now - lastClaimTime) / (1000 * 60 * 60);
        alreadyClaimed = hoursSinceLastClaim < 24;
      }
      
      if (!alreadyClaimed) {
        // Store pending bonus
        user.pendingBonus = {
          amount: bonusAmount,
          rank: userRank,
          claimed: false,
          earnedAt: now
        };
        await user.save();
        
        // Send notification
        await sendBonusNotification(user, userRank, bonusAmount);
        
        return res.json({ 
          success: true, 
          message: `Notification sent for rank ${userRank}, +${bonusAmount} coins`,
          rank: userRank,
          bonusAmount: bonusAmount
        });
      } else {
        return res.json({ 
          success: false, 
          message: 'Already claimed today. Try again after 24 hours.'
        });
      }
    } else {
      return res.json({ 
        success: false, 
        message: `User not in top 3. Current rank: ${userRank}`
      });
    }
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

// Export
exports.triggerRankBonusNotification = triggerRankBonusNotification;
// Export missing functions
exports.getCompleteLeaderboard = getCompleteLeaderboard;
// Add this at the VERY END of userController.js
exports.checkBonusStatus = checkBonusStatus;
exports.claimDailyBonus = claimDailyBonus;
// Add these missing exports at the VERY END
exports.claimBonusFromNotification = claimBonusFromNotification;
exports.cancelBonusFromNotification = cancelBonusFromNotification; 
