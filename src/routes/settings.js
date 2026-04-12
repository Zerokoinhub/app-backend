// routes/settings.js
const express = require('express');
const router = express.Router();

// GET /api/settings - Public endpoint for mobile app and admin
router.get('/', async (req, res) => {
  try {
    // You can store settings in MongoDB or return defaults
    // For now, return default values
    const settings = {
      rewards: {
        referralReward: 50,
        learningReward: 2,
        adBaseReward: 30,
        sessionReward: 10,
        dailyBonus: 5,
        streakBonus: 100
      },
      features: {
        videoAds: true,
        referralSystem: true,
        dailyRewards: true
      },
      updatedAt: new Date()
    };
    
    res.json({ success: true, data: settings });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// PUT /api/settings - Admin only endpoint
router.put('/', async (req, res) => {
  try {
    const { rewards, features } = req.body;
    
    // Here you would save to database
    // For now, just return success
    const settings = {
      rewards: rewards || {
        referralReward: 50,
        learningReward: 2,
        adBaseReward: 30,
        sessionReward: 10,
        dailyBonus: 5,
        streakBonus: 100
      },
      features: features || {
        videoAds: true,
        referralSystem: true,
        dailyRewards: true
      },
      updatedAt: new Date()
    };
    
    res.json({ success: true, data: settings, message: "Settings updated successfully" });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
