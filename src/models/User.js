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
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('User', userSchema);