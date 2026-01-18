const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');

// ✅ FIXED: Simple Cloudinary setup WITHOUT multer-storage-cloudinary
const cloudinary = require('cloudinary').v2;
const multer = require('multer');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// ✅ FIXED: Use memory storage instead of CloudinaryStorage
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

// ✅ PROFILE PICTURE UPLOAD - USING MEMORY STORAGE
router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  uploadProfilePicture.single('image'),
  userController.uploadProfilePicture
);

// Get user details
router.get('/details', verifyFirebaseToken, userController.getUserDetails);

// ✅ TEST ENDPOINT FOR DEBUGGING
router.post('/test-cloudinary-upload', 
  verifyFirebaseToken,
  uploadProfilePicture.single('test'),
  async (req, res) => {
    try {
      console.log('🧪 Test Cloudinary upload');
      console.log('   File received:', req.file ? 'Yes' : 'No');
      console.log('   User:', req.user.uid);
      
      if (!req.file) {
        return res.json({
          test: 'failed',
          reason: 'No file received'
        });
      }
      
      // Convert buffer to data URI for Cloudinary
      const dataURI = `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`;
      
      // Upload to Cloudinary
      const result = await cloudinary.uploader.upload(dataURI, {
        folder: 'test-uploads'
      });
      
      res.json({
        test: 'success',
        url: result.secure_url,
        message: 'Cloudinary working!'
      });
      
    } catch (error) {
      console.error('Test error:', error.message);
      res.json({
        test: 'error',
        message: error.message,
        appStillRunning: true
      });
    }
  }
);

module.exports = router;
