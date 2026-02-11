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

// ============================================
// ✅ NEW USER SYNC - SESSIONS PROPERLY INITIALIZED
// ============================================
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
      console.log('✨ Creating NEW user with sessions...');
      let inviteCode = generateInviteCode();
      while (await User.findOne({ inviteCode })) {
        inviteCode = generateInviteCode();
      }

      // ✅ NEW USER - PROPER SESSIONS WITH TIMERS
      const now = new Date();
      
      const newUser = new User({
        firebaseUid: uid,
        name,
        email,
        inviteCode,
        country,
        balance: 0,
        recentAmount: 0,
        sessions: [
          {
            sessionNumber: 1,
            unlockedAt: now,                    // ✅ SESSION 1 - IMMEDIATELY UNLOCKED
            completedAt: null,
            isLocked: false,                   // ✅ UNLOCKED
            nextUnlockAt: null,               // ✅ NO TIMER
            isClaimed: false,
            createdAt: now,
            lastUpdated: now
          },
          {
            sessionNumber: 2,
            unlockedAt: null,
            completedAt: null,
            isLocked: true,                   // ✅ LOCKED
            nextUnlockAt: new Date(now.getTime() + SESSION_INTERVAL), // +6 hours
            isClaimed: false,
            createdAt: now,
            lastUpdated: now
          },
          {
            sessionNumber: 3,
            unlockedAt: null,
            completedAt: null,
            isLocked: true,
            nextUnlockAt: new Date(now.getTime() + (2 * SESSION_INTERVAL)), // +12 hours
            isClaimed: false,
            createdAt: now,
            lastUpdated: now
          },
          {
            sessionNumber: 4,
            unlockedAt: null,
            completedAt: null,
            isLocked: true,
            nextUnlockAt: new Date(now.getTime() + (3 * SESSION_INTERVAL)), // +18 hours
            isClaimed: false,
            createdAt: now,
            lastUpdated: now
          }
        ]
      });

      await newUser.save();
      console.log('✅ New user created successfully with invite code:', inviteCode);
      console.log('📊 Sessions initialized:', newUser.sessions.map(s => ({
        num: s.sessionNumber,
        locked: s.isLocked,
        unlockAt: s.nextUnlockAt?.toISOString() || null
      })));

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

// ============================================
// ✅ GET USER SESSIONS - WITH AUTO-UNLOCK CHECK
// ============================================
exports.getUserSessions = async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // ✅ AGAR SESSIONS NAHI HAIN TOH INITIALIZE KARO
    if (!user.sessions || user.sessions.length === 0) {
      const now = new Date();
      user.sessions = [
        {
          sessionNumber: 1,
          unlockedAt: now,
          completedAt: null,
          isLocked: false,
          nextUnlockAt: null,
          isClaimed: false,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 2,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          nextUnlockAt: new Date(now.getTime() + SESSION_INTERVAL),
          isClaimed: false,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 3,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          nextUnlockAt: new Date(now.getTime() + (2 * SESSION_INTERVAL)),
          isClaimed: false,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 4,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          nextUnlockAt: new Date(now.getTime() + (3 * SESSION_INTERVAL)),
          isClaimed: false,
          createdAt: now,
          lastUpdated: now
        }
      ];
      await user.save();
      console.log('✅ Sessions initialized for existing user');
    }

    // ✅ CHECK FOR EXPIRED TIMERS AND AUTO-UNLOCK
    const now = new Date();
    let sessionsUpdated = false;

    for (let session of user.sessions) {
      if (session.isLocked && session.nextUnlockAt) {
        const unlockTime = new Date(session.nextUnlockAt);
        if (now >= unlockTime) {
          session.isLocked = false;
          session.unlockedAt = new Date(now);
          session.nextUnlockAt = null;
          session.lastUpdated = now;
          sessionsUpdated = true;
          console.log(`🔓 Auto-unlocked session ${session.sessionNumber} at ${now.toISOString()}`);
        }
      }
    }

    if (sessionsUpdated) {
      await user.save();
    }

    res.status(200).json({ 
      success: true,
      sessions: user.sessions 
    });
    
  } catch (error) {
    console.error('Get user sessions error:', error.message);
    res.status(500).json({ 
      success: false,
      message: 'Error fetching user sessions', 
      error: error.message 
    });
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

// ============================================
// ✅ COMPLETE SESSION - WITH PROPER TIMERS (CLAIM TIME + INTERVAL)
// ============================================
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

    // ✅ COMPLETE CURRENT SESSION
    const claimTime = new Date(); // Jab user ne claim kiya
    session.completedAt = claimTime;
    session.isClaimed = true;
    session.lastUpdated = claimTime;

    // ✅ ADD COINS
    user.balance = (user.balance || 0) + 30;
    user.recentAmount = 30;
    user.lastSessionCompletedAt = claimTime;

    let nextSessionNumber;
    
    // ========== SESSION 4 COMPLETE - RESET ALL SESSIONS ==========
    if (parseInt(sessionNumber) === 4) {
      console.log('🔄 Session 4 completed - resetting all sessions at:', claimTime.toISOString());
      nextSessionNumber = 1;
      
      // Reset all sessions with proper timers based on CLAIM TIME
      user.sessions.forEach((s, index) => {
        const sessionNum = index + 1;
        
        if (sessionNum === 1) {
          // ✅ SESSION 1 - IMMEDIATELY UNLOCKED, NO TIMER
          s.isLocked = false;
          s.unlockedAt = claimTime;
          s.nextUnlockAt = null;
        } else {
          // ✅ SESSIONS 2,3,4 - LOCKED WITH TIMERS (claimTime + (n-1)*6h)
          s.isLocked = true;
          s.unlockedAt = null;
          s.nextUnlockAt = new Date(claimTime.getTime() + (sessionNum - 1) * SESSION_INTERVAL);
        }
        s.completedAt = null;
        s.isClaimed = false;
        s.lastUpdated = claimTime;
      });
      
      user.sessionsResetAt = claimTime;
      user.lastSessionCycleCompletedAt = claimTime;
      
    } else {
      // ========== NORMAL SESSION - UNLOCK NEXT SESSION ==========
      nextSessionNumber = parseInt(sessionNumber) + 1;
      const nextSession = user.sessions.find(s => s.sessionNumber === nextSessionNumber);
      
      if (nextSession) {
        console.log(`🔓 Setting unlock for session ${nextSessionNumber} at:`, 
          new Date(claimTime.getTime() + SESSION_INTERVAL).toISOString());
        
        nextSession.isLocked = true;
        // ✅ NEXT SESSION UNLOCK = CLAIM TIME + 6 HOURS
        nextSession.nextUnlockAt = new Date(claimTime.getTime() + SESSION_INTERVAL);
        nextSession.unlockedAt = null;
        nextSession.completedAt = null;
        nextSession.isClaimed = false;
        nextSession.lastUpdated = claimTime;
      }
    }

    await user.save();
    
    console.log(`✅ Session ${sessionNumber} completed! New balance: ${user.balance}`);
    console.log('📊 Updated sessions:', user.sessions.map(s => ({
      num: s.sessionNumber,
      locked: s.isLocked,
      unlockAt: s.nextUnlockAt?.toISOString() || null,
      completed: s.completedAt?.toISOString() || null
    })));

    res.status(200).json({
      success: true,
      message: 'Session completed successfully',
      session: session,
      nextSession: user.sessions.find(s => s.sessionNumber === nextSessionNumber),
      sessionsReset: parseInt(sessionNumber) === 4,
      balance: user.balance,
      claimTime: claimTime
    });

  } catch (error) {
    console.error('❌ Complete session error:', error.message);
    res.status(500).json({ 
      success: false, 
      message: 'Error completing session', 
      error: error.message 
    });
  }
};

// ============================================
// ✅ RESET USER SESSIONS - MANUAL RESET
// ============================================
exports.resetUserSessions = async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    console.log(`🔄 Manually resetting sessions for user: ${uid}`);
    
    // ✅ RESET TIME = JAB USER NE RESET KIYA
    const resetTime = new Date();
    
    const resetSessions = [
      {
        sessionNumber: 1,
        unlockedAt: resetTime,                    // ✅ SESSION 1 - IMMEDIATELY UNLOCKED
        completedAt: null,
        isLocked: false,
        nextUnlockAt: null,
        isClaimed: false,
        createdAt: user.sessions[0]?.createdAt || resetTime,
        lastUpdated: resetTime
      },
      {
        sessionNumber: 2,
        unlockedAt: null,
        completedAt: null,
        isLocked: true,
        nextUnlockAt: new Date(resetTime.getTime() + SESSION_INTERVAL), // +6 hours
        isClaimed: false,
        createdAt: user.sessions[1]?.createdAt || resetTime,
        lastUpdated: resetTime
      },
      {
        sessionNumber: 3,
        unlockedAt: null,
        completedAt: null,
        isLocked: true,
        nextUnlockAt: new Date(resetTime.getTime() + (2 * SESSION_INTERVAL)), // +12 hours
        isClaimed: false,
        createdAt: user.sessions[2]?.createdAt || resetTime,
        lastUpdated: resetTime
      },
      {
        sessionNumber: 4,
        unlockedAt: null,
        completedAt: null,
        isLocked: true,
        nextUnlockAt: new Date(resetTime.getTime() + (3 * SESSION_INTERVAL)), // +18 hours
        isClaimed: false,
        createdAt: user.sessions[3]?.createdAt || resetTime,
        lastUpdated: resetTime
      }
    ];

    user.sessions = resetSessions;
    user.sessionsResetAt = resetTime;
    user.lastSessionCycleCompletedAt = resetTime;
    
    await user.save();
    
    console.log(`✅ Sessions reset successful at ${resetTime.toISOString()}`);
    console.log('📊 Reset sessions:', user.sessions.map(s => ({
      num: s.sessionNumber,
      locked: s.isLocked,
      unlockAt: s.nextUnlockAt?.toISOString() || null
    })));

    res.status(200).json({
      success: true,
      message: 'Sessions reset successfully',
      sessions: user.sessions,
      resetTime: resetTime
    });

  } catch (error) {
    console.error('❌ Reset sessions error:', error.message);
    res.status(500).json({ 
      success: false, 
      message: 'Error resetting sessions', 
      error: error.message 
    });
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
      success: true,
      count: count 
    });
  } catch (error) {
    console.error('Get user count error:', error.message);
    res.status(500).json({ 
      success: false,
      message: 'Error getting user count', 
      error: error.message 
    });
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

exports.uploadScreenshots = async (req, res) => {
  try {
    console.log('📸 Upload screenshots request received');
    console.log('📸 Files received:', req.files ? req.files.length : 0);

    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    if (!user) {
      console.log('❌ User not found for uid:', uid);
      return res.status(404).json({ message: 'User not found' });
    }

    if (!req.files || req.files.length === 0) {
      console.log('❌ No files received in request');
      return res.status(400).json({ message: 'No files uploaded' });
    }

    const urls = req.files.map(file => file.path);
    user.screenshots = urls.slice(0, 6);
    await user.save();

    console.log('✅ Screenshots saved successfully');

    res.status(200).json({
      message: 'Screenshots uploaded successfully',
      screenshots: user.screenshots
    });
  } catch (error) {
    console.error('Upload screenshots error:', error.message);
    res.status(500).json({ message: 'Error uploading screenshots', error: error.message });
  }
};

exports.updateUserProfile = async (req, res) => {
  try {
    console.log("📝 Profile update request received");
    console.log("   User ID:", req.user.uid);

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

      const now = new Date();
      const newUser = new User({
        firebaseUid: userId,
        name: displayName.trim(),
        email: userEmail,
        inviteCode: inviteCode,
        photoURL: photoURL || null,
        balance: 0,
        calculatorUsage: 0,
        createdAt: now,
        updatedAt: now
      });

      await newUser.save();
      console.log("✅ New user created with invite code:", inviteCode);

      return res.status(200).json({
        success: true,
        message: "Profile created successfully",
        data: {
          displayName: displayName.trim(),
          photoURL: photoURL || null,
          updatedAt: now.toISOString()
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
    res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message
    });
  }
};

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
    console.log('✅ Profile picture saved successfully');

    res.json({
      success: true,
      message: 'Profile picture uploaded successfully',
      photoURL: photoURL
    });

  } catch (error) {
    console.error('❌ Error in uploadProfilePicture:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to upload profile picture'
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
