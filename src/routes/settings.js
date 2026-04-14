// routes/settings.js
const express = require('express');
const router = express.Router();
const Settings = require('../models/Settings');

// GET /api/settings - Public endpoint for mobile app and admin
router.get('/', async (req, res) => {
  try {
    // Get settings from database
    let settings = await Settings.findOne();
    
    // If no settings exist, create default ones
    if (!settings) {
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
        },
        updatedAt: new Date(),
        updatedBy: 'system'
      });
      console.log('✅ Created default settings in database');
    }
    
    console.log('📡 GET Settings - Returning:', {
      adBaseReward: settings.rewards.adBaseReward,
      updatedAt: settings.updatedAt
    });
    
    res.json({ success: true, data: settings });
  } catch (error) {
    console.error('❌ Error fetching settings:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// PUT /api/settings - Admin only endpoint (Update settings)
router.put('/', async (req, res) => {
  try {
    const { rewards, features } = req.body;
    
    console.log('📝 PUT Settings - Received update:', JSON.stringify(req.body, null, 2));
    
    // Find existing settings or create new one
    let settings = await Settings.findOne();
    
    if (!settings) {
      // Create new settings if none exist
      settings = new Settings({
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
    
    // Update rewards if provided
    if (rewards) {
      if (rewards.referralReward !== undefined) {
        settings.rewards.referralReward = rewards.referralReward;
        console.log(`✅ Updated referralReward to: ${rewards.referralReward}`);
      }
      if (rewards.learningReward !== undefined) {
        settings.rewards.learningReward = rewards.learningReward;
        console.log(`✅ Updated learningReward to: ${rewards.learningReward}`);
      }
      if (rewards.adBaseReward !== undefined) {
        settings.rewards.adBaseReward = rewards.adBaseReward;
        console.log(`✅ Updated adBaseReward to: ${rewards.adBaseReward}`);
      }
      if (rewards.sessionReward !== undefined) {
        settings.rewards.sessionReward = rewards.sessionReward;
        console.log(`✅ Updated sessionReward to: ${rewards.sessionReward}`);
      }
      if (rewards.dailyBonus !== undefined) {
        settings.rewards.dailyBonus = rewards.dailyBonus;
        console.log(`✅ Updated dailyBonus to: ${rewards.dailyBonus}`);
      }
      if (rewards.streakBonus !== undefined) {
        settings.rewards.streakBonus = rewards.streakBonus;
        console.log(`✅ Updated streakBonus to: ${rewards.streakBonus}`);
      }
    }
    
    // Update features if provided
    if (features) {
      if (features.videoAds !== undefined) {
        settings.features.videoAds = features.videoAds;
        console.log(`✅ Updated videoAds to: ${features.videoAds}`);
      }
      if (features.referralSystem !== undefined) {
        settings.features.referralSystem = features.referralSystem;
        console.log(`✅ Updated referralSystem to: ${features.referralSystem}`);
      }
      if (features.dailyRewards !== undefined) {
        settings.features.dailyRewards = features.dailyRewards;
        console.log(`✅ Updated dailyRewards to: ${features.dailyRewards}`);
      }
    }
    
    // Update timestamp and who updated it
    settings.updatedAt = new Date();
    settings.updatedBy = req.user?.email || 'admin';
    
    // Save to database
    await settings.save();
    
    console.log('✅ Settings saved to database successfully!');
    console.log('📊 Current values in database:', {
      referralReward: settings.rewards.referralReward,
      learningReward: settings.rewards.learningReward,
      adBaseReward: settings.rewards.adBaseReward,
      sessionReward: settings.rewards.sessionReward,
      dailyBonus: settings.rewards.dailyBonus,
      streakBonus: settings.rewards.streakBonus,
      updatedAt: settings.updatedAt
    });
    
    res.json({ 
      success: true, 
      data: settings, 
      message: "Settings updated successfully" 
    });
  } catch (error) {
    console.error('❌ Error saving settings:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// POST /api/settings/update-ad-reward - Specific endpoint for updating ad reward
router.post('/update-ad-reward', async (req, res) => {
  try {
    const { adBaseReward } = req.body;
    
    if (adBaseReward === undefined) {
      return res.status(400).json({ success: false, error: 'adBaseReward is required' });
    }
    
    console.log(`🎯 Updating adBaseReward to: ${adBaseReward}`);
    
    let settings = await Settings.findOne();
    
    if (!settings) {
      settings = new Settings();
    }
    
    settings.rewards.adBaseReward = adBaseReward;
    settings.updatedAt = new Date();
    settings.updatedBy = req.user?.email || 'admin';
    
    await settings.save();
    
    console.log(`✅ adBaseReward updated to: ${adBaseReward}`);
    
    res.json({ 
      success: true, 
      data: { adBaseReward: settings.rewards.adBaseReward },
      message: `Ad reward updated to ${adBaseReward} ZRK` 
    });
  } catch (error) {
    console.error('❌ Error updating ad reward:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET /api/settings/debug - Debug endpoint to check current values
router.get('/debug', async (req, res) => {
  try {
    const settings = await Settings.findOne();
    
    if (!settings) {
      return res.json({ 
        success: true, 
        message: 'No settings found in database',
        databaseValue: null
      });
    }
    
    res.json({ 
      success: true, 
      data: {
        adBaseReward: settings.rewards.adBaseReward,
        learningReward: settings.rewards.learningReward,
        referralReward: settings.rewards.referralReward,
        sessionReward: settings.rewards.sessionReward,
        dailyBonus: settings.rewards.dailyBonus,
        streakBonus: settings.rewards.streakBonus,
        updatedAt: settings.updatedAt,
        updatedBy: settings.updatedBy
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// DELETE /api/settings/reset - Reset to default values (admin only)
router.delete('/reset', async (req, res) => {
  try {
    const defaultSettings = {
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
      updatedAt: new Date(),
      updatedBy: req.user?.email || 'admin'
    };
    
    let settings = await Settings.findOne();
    
    if (settings) {
      // Update existing settings
      settings.rewards = defaultSettings.rewards;
      settings.features = defaultSettings.features;
      settings.updatedAt = defaultSettings.updatedAt;
      settings.updatedBy = defaultSettings.updatedBy;
      await settings.save();
    } else {
      // Create new settings
      settings = await Settings.create(defaultSettings);
    }
    
    console.log('✅ Settings reset to default values');
    
    res.json({ 
      success: true, 
      data: settings,
      message: "Settings reset to default values" 
    });
  } catch (error) {
    console.error('❌ Error resetting settings:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
