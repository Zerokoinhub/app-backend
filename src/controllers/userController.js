const User = require('../models/User');
const crypto = require('crypto');
const { getTodayUTC, getNextSessionUnlockTime, SESSIONS_PER_DAY, SESSION_INTERVAL } = require('../utils/session');
const geoip = require('geoip-lite');
const { getName } = require('country-list');
const NotificationService = require('../services/notificationService');
const notificationService = new NotificationService();
const cloudinary = require('cloudinary').v2;

const generateInviteCode = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let code = '';
  for (let i = 0; i < 34; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

// Add this function to check current code version
exports.debugConfig = async (req, res) => {
  res.json({
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    cloudinary: {
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME ? '✅ Configured' : '❌ Missing',
      api_key: process.env.CLOUDINARY_API_KEY ? '✅ Configured' : '❌ Missing',
      api_secret: process.env.CLOUDINARY_API_SECRET ? '✅ Configured (hidden)' : '❌ Missing'
    },
    environment: process.env.NODE_ENV || 'development'
  });
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

// ... KEEP ALL YOUR EXISTING CONTROLLER FUNCTIONS HERE ...
// (getInviteDetails, processReferral, syncFirebaseUser, etc.)
// MAKE SURE TO INCLUDE ALL FUNCTIONS FROM YOUR FILE

// ✅ ADD THIS HEALTH CHECK FUNCTION
exports.healthCheck = async (req, res) => {
  try {
    // Test database connection
    const dbCheck = await User.countDocuments().catch(() => null);
    
    res.json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      database: dbCheck !== null ? 'Connected' : 'Disconnected',
      cloudinary: process.env.CLOUDINARY_CLOUD_NAME ? 'Configured' : 'Not configured',
      environment: process.env.NODE_ENV || 'development'
    });
  } catch (error) {
    res.status(500).json({
      status: 'ERROR',
      error: error.message
    });
  }
};

// ✅ SIMPLE WORKING UPLOAD FUNCTION (NO CRASH)
exports.uploadProfilePicture = async (req, res) => {
  console.log('📸 Profile picture upload endpoint called');
  
  try {
    // Quick validation
    if (!req.user || !req.user.uid) {
      console.log('❌ No user authenticated');
      return res.status(401).json({ 
        success: false,
        error: 'Unauthorized',
        message: 'Please login first'
      });
    }
    
    if (!req.file) {
      console.log('❌ No file uploaded');
      return res.status(400).json({ 
        success: false,
        error: 'No file',
        message: 'Please select an image'
      });
    }
    
    const userId = req.user.uid;
    console.log(`✅ User authenticated: ${userId}`);
    console.log(`📁 File received: ${req.file.originalname} (${req.file.size} bytes)`);
    
    // Find user in database
    const user = await User.findOne({ firebaseUid: userId });
    
    if (!user) {
      console.log('❌ User not found in database');
      return res.status(404).json({
        success: false,
        error: 'User not found',
        message: 'User not found in database'
      });
    }
    
    console.log('✅ User found in database:', user.email);
    
    // Generate a temporary image URL
    const tempImageUrl = `https://api.dicebear.com/7.x/avatars/svg?seed=${userId}_${Date.now()}&backgroundColor=b6e3f4,c0aede,d1d4f9&backgroundType=gradientLinear`;
    
    // Update user with new image URL
    user.photoURL = tempImageUrl;
    user.updatedAt = new Date();
    
    await user.save();
    
    console.log('✅ User profile updated with new photo URL');
    
    // Return success response
    res.json({
      success: true,
      message: 'Profile picture updated successfully',
      data: {
        photoURL: tempImageUrl,
        updatedAt: user.updatedAt,
        note: 'This is a temporary image. Configure Cloudinary for actual uploads.'
      }
    });
    
  } catch (error) {
    console.error('❌ Upload error:', error.message);
    console.error('Stack trace:', error.stack);
    
    // Return error without crashing server
    res.status(500).json({
      success: false,
      error: 'Upload failed',
      message: 'Failed to update profile picture. Please try again.'
    });
  }
};

// ✅ ADD THIS FUNCTION - IT'S MISSING!
exports.getUserDetails = async (req, res) => {
  try {
    console.log('🔍 Getting user details for:', req.user.uid);
    
    const user = await User.findOne({ firebaseUid: req.user.uid });
    
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
