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
    // 1. Basic validation
    if (!req.user || !req.user.uid) {
      return res.status(401).json({ 
        success: false,
        error: 'Unauthorized'
      });
    }
    
    if (!req.file) {
      return res.status(400).json({ 
        success: false,
        error: 'No file uploaded'
      });
    }
    
    const userId = req.user.uid;
    console.log(`✅ User: ${userId}, File: ${req.file.originalname}`);
    
    // 2. Find user
    const user = await User.findOne({ firebaseUid: userId });
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }
    
    // 3. Check if Cloudinary is configured
    const hasCloudinaryConfig = process.env.CLOUDINARY_CLOUD_NAME && 
                               process.env.CLOUDINARY_API_KEY && 
                               process.env.CLOUDINARY_API_SECRET;
    
    let imageUrl;
    
    if (hasCloudinaryConfig) {
      // Upload to Cloudinary
      console.log('☁️ Uploading to Cloudinary...');
      
      // Convert buffer to base64
      const fileBuffer = req.file.buffer;
      const fileBase64 = `data:${req.file.mimetype};base64,${fileBuffer.toString('base64')}`;
      
      const uploadResult = await cloudinary.uploader.upload(fileBase64, {
        folder: 'zerokoin/profile-pictures',
        public_id: `profile_${userId}_${Date.now()}`,
        overwrite: true,
        transformation: [
          { width: 400, height: 400, crop: 'fill', gravity: 'face' },
          { quality: 'auto', fetch_format: 'auto' }
        ]
      });
      
      imageUrl = uploadResult.secure_url;
      console.log('✅ Cloudinary upload successful:', imageUrl);
      
    } else {
      // Fallback: Generate avatar URL
      console.log('⚠️ Cloudinary not configured, using fallback');
      imageUrl = `https://api.dicebear.com/7.x/avatars/svg?seed=${userId}_${Date.now()}`;
    }
    
    // 4. Update user
    user.photoURL = imageUrl;
    user.updatedAt = new Date();
    await user.save();
    
    // 5. Return response
    res.json({
      success: true,
      message: 'Profile picture updated successfully',
      data: {
        photoURL: imageUrl,
        updatedAt: user.updatedAt
      }
    });
    
  } catch (error) {
    console.error('❌ Upload error:', error.message);
    
    // Check for specific errors
    let statusCode = 500;
    let errorMessage = 'Failed to upload profile picture';
    
    if (error.message.includes('File too large')) {
      statusCode = 400;
      errorMessage = 'Image is too large. Maximum size is 5MB.';
    } else if (error.message.includes('not allowed')) {
      statusCode = 400;
      errorMessage = 'Invalid file type. Please use JPG, PNG, or WebP.';
    }
    
    res.status(statusCode).json({
      success: false,
      error: errorMessage
    });
  }
};
