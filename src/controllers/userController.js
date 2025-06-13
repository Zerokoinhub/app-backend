const User = require('../models/User');
const crypto = require('crypto');
const { getTodayUTC, getNextSessionUnlockTime, SESSIONS_PER_DAY } = require('../utils/session');

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

exports.syncFirebaseUser = async (req, res) => {
  try {
    const { uid, email, name } = req.user; // From Firebase auth middleware
    console.log('🔥 Syncing Firebase user:', { uid, email, name });

    // Check if user already exists
    let user = await User.findOne({ firebaseUid: uid });

    if (user) {
      // Update existing user data
      console.log('📝 Updating existing user:', user.inviteCode);
      user.name = name || user.name;
      user.email = email || user.email;
      await user.save();

      res.status(200).json({
        message: 'User data updated successfully',
        user: {
          firebaseUid: user.firebaseUid,
          name: user.name,
          email: user.email,
          inviteCode: user.inviteCode,
          recentAmount: user.recentAmount,
          balance: user.balance
        }
      });
    } else {
      // Create new user with Firebase data
      console.log('✨ Creating new user for Firebase UID:', uid);
      let inviteCode = generateInviteCode();
      while (await User.findOne({ inviteCode })) {
        inviteCode = generateInviteCode();
      }

      const newUser = new User({
        firebaseUid: uid,
        name: name,
        email: email,
        inviteCode: inviteCode
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
          balance: newUser.balance
        }
      });
    }
  } catch (error) {
    console.error('Firebase user sync error:', error.message);
    res.status(500).json({ message: 'Error syncing user data', error: error.message });
  }
};

// Get user profile (Firebase authenticated)
exports.getUserProfile = async (req, res) => {
  try {
    const { uid } = req.user; // From Firebase auth middleware

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
        createdAt: user.createdAt
      }
    });
  } catch (error) {
    console.error('Get user profile error:', error.message);
    res.status(500).json({ message: 'Error fetching user profile', error: error.message });
  }
};

exports.getUserSessions = async (req, res) => {
  const userId = req.user._id; // from auth middleware
  const user = await User.findById(userId);

  // Reset sessions if it's a new UTC day
  const todayUTC = getTodayUTC();
  if (!user.sessionsResetAt || user.sessionsResetAt < todayUTC) {
    user.sessions = [];
    for (let i = 1; i <= SESSIONS_PER_DAY; i++) {
      user.sessions.push({
        sessionNumber: i,
        unlockedAt: null,
        isClaimed: false
      });
    }
    user.lastSessionUnlockAt = null;
    user.sessionsResetAt = todayUTC;
    await user.save();
  }

  // Calculate unlock status and next unlock time
  let nextUnlockTime = null;
  for (let i = 0; i < SESSIONS_PER_DAY; i++) {
    if (i === 0) {
      user.sessions[i].unlockedAt = user.sessions[i].unlockedAt || user.sessionsResetAt;
    } else if (user.sessions[i - 1].unlockedAt) {
      const expectedUnlock = getNextSessionUnlockTime(user.sessions[i - 1].unlockedAt);
      if (!user.sessions[i].unlockedAt && new Date() >= expectedUnlock) {
        user.sessions[i].unlockedAt = expectedUnlock;
      }
      if (!user.sessions[i].unlockedAt) {
        nextUnlockTime = expectedUnlock;
        break;
      }
    }
  }
  await user.save();

  res.json({
    sessions: user.sessions,
    nextUnlockTime
  });
};

exports.unlockNextSession = async (req, res) => {
  const userId = req.user._id;
  const user = await User.findById(userId);

  // Reset sessions if it's a new UTC day
  const todayUTC = getTodayUTC();
  if (!user.sessionsResetAt || user.sessionsResetAt < todayUTC) {
    user.sessions = [];
    for (let i = 1; i <= SESSIONS_PER_DAY; i++) {
      user.sessions.push({
        sessionNumber: i,
        unlockedAt: null,
        isClaimed: false
      });
    }
    user.lastSessionUnlockAt = null;
    user.sessionsResetAt = todayUTC;
    await user.save();
  }

  // Find next session to unlock
  const nextSession = user.sessions.find(s => !s.unlockedAt);
  if (!nextSession) {
    return res.status(400).json({ message: "All sessions unlocked for today." });
  }
  if (nextSession.sessionNumber === 1) {
    nextSession.unlockedAt = todayUTC;
    user.lastSessionUnlockAt = todayUTC;
    await user.save();
    return res.json({ message: "Session 1 unlocked!", nextUnlockTime: getNextSessionUnlockTime(todayUTC) });
  } else {
    const prevSession = user.sessions[nextSession.sessionNumber - 2];
    const expectedUnlock = getNextSessionUnlockTime(prevSession.unlockedAt);
    if (new Date() < expectedUnlock) {
      return res.status(400).json({
        message: "Next session not yet unlocked.",
        nextUnlockTime: expectedUnlock
      });
    }
    nextSession.unlockedAt = expectedUnlock;
    user.lastSessionUnlockAt = expectedUnlock;
    await user.save();
    return res.json({ message: `Session ${nextSession.sessionNumber} unlocked!`, nextUnlockTime: getNextSessionUnlockTime(expectedUnlock) });
  }
};