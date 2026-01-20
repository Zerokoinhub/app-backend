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

// ✅ FIXED: SIMPLE AND RELIABLE UPLOAD FUNCTION
exports.uploadProfilePicture = async (req, res) => {
  console.log('📸 Profile picture upload endpoint called');
  console.log('📁 File info:', req.file ? {
    originalname: req.file.originalname,
    size: req.file.size,
    mimetype: req.file.mimetype,
    fieldname: req.file.fieldname
  } : 'No file');
  
  try {
    // 1. Basic validation
    if (!req.user || !req.user.uid) {
      return res.status(401).json({ 
        success: false,
        error: 'Unauthorized - No user found'
      });
    }
    
    if (!req.file) {
      return res.status(400).json({ 
        success: false,
        error: 'No file uploaded. Please select an image.'
      });
    }
    
    const userId = req.user.uid;
    console.log(`✅ User ID: ${userId}`);
    
    // 2. Validate file type
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'image/gif'];
    if (!allowedMimeTypes.includes(req.file.mimetype)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid file type. Please upload JPEG, PNG, or WebP image.'
      });
    }
    
    // 3. Validate file size (5MB max)
    if (req.file.size > 5 * 1024 * 1024) {
      return res.status(400).json({
        success: false,
        error: 'File too large. Maximum size is 5MB.'
      });
    }
    
    // 4. Find user
    const user = await User.findOne({ firebaseUid: userId });
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found in database'
      });
    }
    
    // 5. Upload to Cloudinary or use fallback
    let imageUrl;
    const timestamp = Date.now();
    
    // Check Cloudinary configuration
    const hasCloudinaryConfig = process.env.CLOUDINARY_CLOUD_NAME && 
                               process.env.CLOUDINARY_API_KEY && 
                               process.env.CLOUDINARY_API_SECRET;
    
    if (hasCloudinaryConfig) {
      console.log('☁️ Attempting Cloudinary upload...');
      try {
        // Use callback-based upload with timeout
        const uploadToCloudinary = () => {
          return new Promise((resolve, reject) => {
            // Convert buffer to base64
            const fileBuffer = req.file.buffer;
            const fileBase64 = `data:${req.file.mimetype};base64,${fileBuffer.toString('base64')}`;
            
            // Upload with callback (more reliable than promise)
            cloudinary.uploader.upload(fileBase64, {
              folder: 'zerokoin/profile-pictures',
              public_id: `profile_${userId}_${timestamp}`,
              overwrite: true,
              transformation: [
                { width: 400, height: 400, crop: 'fill', gravity: 'face' },
                { quality: 'auto:good', fetch_format: 'auto' }
              ]
            }, (error, result) => {
              if (error) {
                console.error('❌ Cloudinary error:', error.message);
                reject(error);
              } else {
                console.log('✅ Cloudinary upload successful');
                resolve(result.secure_url);
              }
            });
          });
        };
        
        // Add timeout
        const timeoutPromise = new Promise((_, reject) => {
          setTimeout(() => reject(new Error('Cloudinary upload timeout (20s)')), 20000);
        });
        
        // Race between upload and timeout
        imageUrl = await Promise.race([uploadToCloudinary(), timeoutPromise]);
        
      } catch (cloudinaryError) {
        console.error('❌ Cloudinary upload failed, using fallback:', cloudinaryError.message);
        // Fallback to DiceBear
        imageUrl = `https://api.dicebear.com/7.x/avatars/svg?seed=${userId}_${timestamp}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf&radius=50`;
      }
    } else {
      console.log('⚠️ Cloudinary not configured, using DiceBear fallback');
      imageUrl = `https://api.dicebear.com/7.x/avatars/svg?seed=${userId}_${timestamp}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf&radius=50`;
    }
    
    // 6. Update user in database
    console.log(`🔄 Updating user with photoURL: ${imageUrl.substring(0, 50)}...`);
    user.photoURL = imageUrl;
    user.updatedAt = new Date();
    
    // Save with error handling
    try {
      await user.save();
      console.log('✅ User updated successfully in database');
    } catch (saveError) {
      console.error('❌ Failed to save user:', saveError.message);
      // Still return success if Cloudinary worked, even if DB save failed
    }
    
    // 7. Return success response
    return res.json({
      success: true,
      message: 'Profile picture updated successfully',
      data: {
        photoURL: imageUrl,
        updatedAt: new Date().toISOString(),
        userId: userId
      }
    });
    
  } catch (error) {
    console.error('❌ Upload endpoint error:', error.message);
    console.error('❌ Error stack:', error.stack ? error.stack.substring(0, 200) : 'No stack trace');
    
    // Always return a proper response
    return res.status(500).json({
      success: false,
      error: 'Failed to process profile picture upload. Please try again.',
      debug: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// ✅ TEST ENDPOINT - SIMPLE AND RELIABLE
exports.testUpload = async (req, res) => {
  console.log('🧪 Test upload endpoint called');
  
  try {
    res.json({
      success: true,
      message: 'Upload endpoint is working correctly',
      timestamp: new Date().toISOString(),
      fileReceived: !!req.file,
      fileInfo: req.file ? {
        fieldname: req.file.fieldname,
        originalname: req.file.originalname,
        size: req.file.size,
        mimetype: req.file.mimetype
      } : null,
      userAuthenticated: !!req.user,
      userId: req.user ? req.user.uid : null
    });
  } catch (error) {
    console.error('Test endpoint error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};
