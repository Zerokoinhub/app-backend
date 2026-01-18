const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');
const { getUserSessions, unlockNextSession, completeSession } = require('../controllers/userController');

// Import multer for file uploads
const multer = require('multer');
const path = require('path');

// Configure multer for profile pictures specifically
const profilePictureStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/profile-pictures/');
  },
  filename: function (req, file, cb) {
    const userId = req.user?.uid || 'unknown';
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `profile-${userId}-${uniqueSuffix}${ext}`);
  }
});

const uploadProfilePicture = multer({
  storage: profilePictureStorage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only images (jpeg, jpg, png) are allowed'));
    }
  }
});

// For screenshots (existing - keep as is)
const upload = require('../config/multer');

// User routes
router.post('/register', userController.registerUser);
router.get('/invite/:inviteCode', userController.getInviteDetails);
router.post('/referral', userController.processReferral);
router.get('/sessions', verifyFirebaseToken, getUserSessions);
router.post('/unlock', verifyFirebaseToken, unlockNextSession);
router.post('/complete-session', verifyFirebaseToken, completeSession);
router.post('/reset-sessions', verifyFirebaseToken, userController.resetUserSessions);
router.post('/sync', verifyFirebaseToken, userController.syncFirebaseUser);
router.get('/profile', verifyFirebaseToken, userController.getUserProfile);
router.put('/wallet-address', verifyFirebaseToken, userController.updateWalletAddress);
router.get('/count', userController.getUserCount);
router.put('/calculator-usage', verifyFirebaseToken, userController.incrementCalculatorUsage);
router.put('/update-balance', verifyFirebaseToken, userController.updateUserBalance);

// Upload screenshots route
router.post('/upload-screenshots', verifyFirebaseToken, (req, res, next) => {
  console.log('🔍 Route middleware - User:', req.user);
  console.log('🔍 Route middleware - Headers:', req.headers['content-type']);
  next();
}, upload.array('screenshots', 6), (req, res, next) => {
  console.log('🔍 After multer - Files:', req.files ? req.files.length : 0);
  next();
}, userController.uploadScreenshots);

// FCM Token Management Routes
router.post('/fcm-token', verifyFirebaseToken, userController.updateFCMToken);
router.delete('/fcm-token', verifyFirebaseToken, userController.removeFCMToken);
router.put('/notification-settings', verifyFirebaseToken, userController.updateNotificationSettings);

// Profile management routes
router.put('/profile', verifyFirebaseToken, userController.updateUserProfile);

// ADD THIS NEW ROUTE FOR PROFILE PICTURE UPLOAD
router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  uploadProfilePicture.single('profilePicture'),
  userController.uploadProfilePicture
);

// Get user details (optional - if needed)
router.get('/details', verifyFirebaseToken, userController.getUserDetails);

module.exports = router;
