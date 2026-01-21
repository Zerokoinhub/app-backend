const User = require('../models/User');
const crypto = require('crypto');
const { getTodayUTC, getNextSessionUnlockTime, SESSIONS_PER_DAY, SESSION_INTERVAL } = require('../utils/session');
const geoip = require('geoip-lite');
const { getName } = require('country-list');
const NotificationService = require('../services/notificationService');
const notificationService = new NotificationService();
const cloudinary = require('cloudinary').v2;

// =========================
// INVITE CODE GENERATOR
// =========================
const generateInviteCode = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let code = '';
  for (let i = 0; i < 34; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

// =========================
// DEBUG CONFIG
// =========================
exports.debugConfig = async (req, res) => {
  res.json({
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    cloudinary: {
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME ? 'Configured' : 'Missing',
      api_key: process.env.CLOUDINARY_API_KEY ? 'Configured' : 'Missing',
      api_secret: process.env.CLOUDINARY_API_SECRET ? 'Configured' : 'Missing'
    },
    environment: process.env.NODE_ENV || 'development'
  });
};

// =========================
// REGISTER USER
// =========================
exports.registerUser = async (req, res) => {
  try {
    let inviteCode = generateInviteCode();
    while (await User.findOne({ inviteCode })) {
      inviteCode = generateInviteCode();
    }
    const user = new User({ inviteCode });
    await user.save();
    res.status(201).json({ inviteCode });
  } catch {
    res.status(500).json({ message: 'Error registering user' });
  }
};

// =========================
// HEALTH CHECK
// =========================
exports.healthCheck = async (req, res) => {
  try {
    const dbCheck = await User.countDocuments().catch(() => null);
    res.json({
      status: 'OK',
      database: dbCheck !== null ? 'Connected' : 'Disconnected',
      cloudinary: process.env.CLOUDINARY_CLOUD_NAME ? 'Configured' : 'Not configured'
    });
  } catch {
    res.status(500).json({ status: 'ERROR' });
  }
};

// =================================================
// PROFILE PICTURE UPLOAD (LOGIC SAME – FIXED CORE)
// =================================================
exports.uploadProfilePicture = async (req, res) => {
  console.log('📸 Upload endpoint hit');

  try {
    // 1. Auth
    if (!req.user || !req.user.uid) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }

    // 2. File check
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'No file uploaded' });
    }

    // 3. MIME check (same as before)
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'image/gif'];
    if (!allowedMimeTypes.includes(req.file.mimetype)) {
      return res.status(400).json({ success: false, error: 'Invalid file type' });
    }

    // 4. Size check (same)
    if (req.file.size > 5 * 1024 * 1024) {
      return res.status(400).json({ success: false, error: 'File too large' });
    }

    // 5. Find user
    const user = await User.findOne({ firebaseUid: req.user.uid });
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    let imageUrl;
    const timestamp = Date.now();

    // 6. Cloudinary (SAME FEATURE, SAFE METHOD)
    const hasCloudinary =
      process.env.CLOUDINARY_CLOUD_NAME &&
      process.env.CLOUDINARY_API_KEY &&
      process.env.CLOUDINARY_API_SECRET;

    if (hasCloudinary) {
      try {
        imageUrl = await new Promise((resolve, reject) => {
          cloudinary.uploader.upload_stream(
            {
              folder: 'zerokoin/profile-pictures',
              public_id: `profile_${req.user.uid}_${timestamp}`,
              overwrite: true
            },
            (err, result) => {
              if (err) reject(err);
              else resolve(result.secure_url);
            }
          ).end(req.file.buffer);
        });
      } catch (err) {
        console.error('❌ Cloudinary failed:', err.message);
      }
    }

    // 7. Fallback (UNCHANGED FEATURE)
    if (!imageUrl) {
      imageUrl = `https://api.dicebear.com/7.x/avatars/svg?seed=${req.user.uid}_${timestamp}&radius=50`;
    }

    // 8. Save user (same)
    user.photoURL = imageUrl;
    user.updatedAt = new Date();
    await user.save();

    // 9. Response (same)
    return res.json({
      success: true,
      message: 'Profile picture updated successfully',
      data: { photoURL: imageUrl }
    });

  } catch (error) {
    console.error('❌ Upload error:', error.message);
    return res.status(500).json({
      success: false,
      error: 'Failed to upload profile picture'
    });
  }
};

// =========================
// TEST UPLOAD
// =========================
exports.testUpload = async (req, res) => {
  res.json({
    success: true,
    fileReceived: !!req.file,
    user: req.user ? req.user.uid : null
  });
};
