const express = require('express');
const router = express.Router();
const Settings = require('../models/Settings');
const auth = require('../middleware/auth');

// GET settings (public - for mobile app)
router.get('/', async (req, res) => {
  try {
    let settings = await Settings.findOne();
    if (!settings) {
      // Create default settings
      settings = await Settings.create({
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
        }
      });
    }
    res.json({ success: true, data: settings });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// UPDATE settings (admin only)
router.put('/', auth, async (req, res) => {
  try {
    // Verify admin role
    if (req.user.role !== 'superadmin' && req.user.role !== 'editor') {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }

    const { rewards, features } = req.body;
    
    const settings = await Settings.findOneAndUpdate(
      {},
      { 
        rewards: rewards,
        features: features,
        updatedAt: new Date(),
        updatedBy: req.user.email
      },
      { new: true, upsert: true }
    );
    
    res.json({ success: true, data: settings });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get settings version (for cache invalidation)
router.get('/version', async (req, res) => {
  try {
    const settings = await Settings.findOne();
    res.json({ 
      success: true, 
      version: settings?.updatedAt?.getTime() || Date.now() 
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
