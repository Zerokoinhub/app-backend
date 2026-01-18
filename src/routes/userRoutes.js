const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');

// ✅ FIXED: Simple Cloudinary setup
const cloudinary = require('cloudinary').v2;
const multer = require('multer');

// ✅ IMPORTANT: Check if Cloudinary config exists
if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_SECRET) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
  });
  console.log('✅ Cloudinary configured successfully');
} else {
  console.warn('⚠️ Cloudinary environment variables missing!');
}

// ✅ FIXED: Use memory storage
const memoryStorage = multer.memoryStorage();
const uploadProfilePicture = multer({ 
  storage: memoryStorage,
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB
});

// For screenshots (local storage)
const upload = require('../config/multer');

// User routes
router.post('/register', userController.registerUser);
router.get('/invite/:inviteCode', userController.getInviteDetails);
router.post('/referral', userController.processReferral);
router.get('/sessions', verifyFirebaseToken, userController.getUserSessions);
router.post('/unlock', verifyFirebaseToken, userController.unlockNextSession);
router.post('/complete-session', verifyFirebaseToken, userController.completeSession);
router.post('/reset-sessions', verifyFirebaseToken, userController.resetUserSessions);
router.post('/sync', verifyFirebaseToken, userController.syncFirebaseUser);
router.get('/profile', verifyFirebaseToken, userController.getUserProfile);
router.put('/wallet-address', verifyFirebaseToken, userController.updateWalletAddress);
router.get('/count', userController.getUserCount);
router.put('/calculator-usage', verifyFirebaseToken, userController.incrementCalculatorUsage);
router.put('/update-balance', verifyFirebaseToken, userController.updateUserBalance);

// Upload screenshots route
router.post('/upload-screenshots', verifyFirebaseToken, upload.array('screenshots', 6), userController.uploadScreenshots);

// FCM Token Management Routes
router.post('/fcm-token', verifyFirebaseToken, userController.updateFCMToken);
router.delete('/fcm-token', verifyFirebaseToken, userController.removeFCMToken);
router.put('/notification-settings', verifyFirebaseToken, userController.updateNotificationSettings);

// Profile management routes
router.put('/profile', verifyFirebaseToken, userController.updateUserProfile);

// ✅ PROFILE PICTURE UPLOAD - WITH ERROR HANDLING
router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  uploadProfilePicture.single('image'),
  userController.uploadProfilePicture
);

// Get user details - ✅ CHECK THIS LINE (likely line 61)
router.get('/details', verifyFirebaseToken, userController.getUserDetails);

// ✅ TEST ENDPOINTS FOR DEBUGGING
router.post('/test-cloudinary-simple', async (req, res) => {
  try {
    console.log('🧪 Testing Cloudinary...');
    
    if (!process.env.CLOUDINARY_CLOUD_NAME) {
      return res.json({ error: 'CLOUDINARY_CLOUD_NAME missing' });
    }
    
    const testImage = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
    
    const result = await cloudinary.uploader.upload(testImage, {
      folder: 'test-uploads'
    });
    
    res.json({
      success: true,
      message: 'Cloudinary working!',
      url: result.secure_url
    });
    
  } catch (error) {
    console.error('Cloudinary test error:', error.message);
    res.json({
      success: false,
      error: error.message
    });
  }
});

// ✅ HEALTH CHECK
router.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    cloudinary: process.env.CLOUDINARY_CLOUD_NAME ? 'configured' : 'missing'
  });
});

module.exports = router;
