const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');

// ✅ SIMPLE AND RELIABLE MULTER CONFIGURATION
const multer = require('multer');

// Memory storage for profile pictures
const memoryStorage = multer.memoryStorage();
const uploadProfilePicture = multer({
  storage: memoryStorage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
    files: 1
  },
  fileFilter: (req, file, cb) => {
    // Accept only images
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'image/gif'];
    if (allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only images are allowed.'), false);
    }
  }
});

// For screenshots (local storage) - keep your existing config
const upload = require('../config/multer');

// ============ PUBLIC ROUTES ============
router.get('/health', userController.healthCheck);
router.get('/debug-config', userController.debugConfig);
router.post('/register', userController.registerUser);
router.get('/invite/:inviteCode', userController.getInviteDetails);
router.post('/referral', userController.processReferral);
router.get('/count', userController.getUserCount);

// ============ AUTHENTICATED ROUTES ============
router.get('/sessions', verifyFirebaseToken, userController.getUserSessions);
router.post('/unlock', verifyFirebaseToken, userController.unlockNextSession);
router.post('/complete-session', verifyFirebaseToken, userController.completeSession);
router.post('/reset-sessions', verifyFirebaseToken, userController.resetUserSessions);
router.post('/sync', verifyFirebaseToken, userController.syncFirebaseUser);
router.get('/profile', verifyFirebaseToken, userController.getUserProfile);
router.put('/wallet-address', verifyFirebaseToken, userController.updateWalletAddress);
router.put('/calculator-usage', verifyFirebaseToken, userController.incrementCalculatorUsage);
router.put('/update-balance', verifyFirebaseToken, userController.updateUserBalance);
router.put('/profile', verifyFirebaseToken, userController.updateUserProfile);
router.get('/details', verifyFirebaseToken, userController.getUserDetails);

// Upload routes
router.post('/upload-screenshots', verifyFirebaseToken, upload.array('screenshots', 6), userController.uploadScreenshots);

// ✅ FIXED: PROFILE PICTURE UPLOAD ROUTE
router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  (req, res, next) => {
    console.log('🛣️ Profile picture route accessed');
    console.log('📦 Content-Type:', req.headers['content-type']);
    console.log('👤 User authenticated:', !!req.user);
    next();
  },
  uploadProfilePicture.single('image'), // ⚠️ IMPORTANT: Field name must be 'image'
  (req, res, next) => {
    console.log('✅ Multer processed file:', req.file ? 'Yes' : 'No');
    if (req.file) {
      console.log('📁 File details:', {
        fieldname: req.file.fieldname,
        originalname: req.file.originalname,
        size: req.file.size,
        mimetype: req.file.mimetype
      });
    }
    next();
  },
  userController.uploadProfilePicture
);

// FCM Token Management Routes
router.post('/fcm-token', verifyFirebaseToken, userController.updateFCMToken);
router.delete('/fcm-token', verifyFirebaseToken, userController.removeFCMToken);
router.put('/notification-settings', verifyFirebaseToken, userController.updateNotificationSettings);

// ✅ TEST ENDPOINTS
router.post('/test-upload', 
  verifyFirebaseToken,
  uploadProfilePicture.single('image'),
  userController.testUpload
);

// ✅ SIMPLE TEST ENDPOINT (NO FILE)
router.get('/simple-test', verifyFirebaseToken, (req, res) => {
  res.json({
    success: true,
    message: 'Profile picture endpoint is reachable',
    user: req.user.uid,
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
