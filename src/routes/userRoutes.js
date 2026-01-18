const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');

// Cloudinary setup
const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Cloudinary storage for profile pictures
const profilePictureStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'profile-pictures',
    allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    transformation: [{ width: 500, height: 500, crop: 'limit' }]
  }
});

const uploadProfilePicture = multer({ 
  storage: profilePictureStorage,
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

// ✅ PROFILE PICTURE UPLOAD - FIXED FIELD NAME: 'image' (not 'profilePicture')
router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  uploadProfilePicture.single('image'), // ✅ FIXED: Changed from 'profilePicture' to 'image'
  userController.uploadProfilePicture
);

// Get user details
router.get('/details', verifyFirebaseToken, userController.getUserDetails);

module.exports = router;
