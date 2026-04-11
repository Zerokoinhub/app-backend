const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
  rewards: {
    referralReward: { type: Number, default: 50 },
    learningReward: { type: Number, default: 2 },
    adBaseReward: { type: Number, default: 30 },
    sessionReward: { type: Number, default: 10 },
    dailyBonus: { type: Number, default: 5 },
    streakBonus: { type: Number, default: 100 }
  },
  features: {
    videoAds: { type: Boolean, default: true },
    referralSystem: { type: Boolean, default: true },
    dailyRewards: { type: Boolean, default: true }
  },
  updatedAt: { type: Date, default: Date.now },
  updatedBy: { type: String, default: 'system' }
});

module.exports = mongoose.model('Settings', settingsSchema);
