const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  inviteCode: {
    type: String,
    unique: true,
    required: true
  },
  referredBy: {
    type: String,
    default: null
  },
  recentAmount: {
    type: Number,
    default: 0
  },
  firebaseUid: {
    type: String,
    unique: true,
    sparse: true
  },
  email: {
    type: String,
    unique: true,
    sparse: true
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  balance: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  sessions: [
    {
      sessionNumber: Number,        // 1 to 4
      unlockedAt: Date,             // When this session was unlocked
      isClaimed: Boolean            // Has the user claimed this session?
    }
  ],
  lastSessionUnlockAt: Date,        // When the last session was unlocked
  sessionsResetAt: Date             // When sessions were last reset (UTC midnight)
});

module.exports = mongoose.model('User', userSchema);