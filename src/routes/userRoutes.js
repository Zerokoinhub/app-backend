const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');
const multer = require('multer');

// ✅ Simple multer configuration
const memoryStorage = multer.memoryStorage();
const uploadProfilePicture = multer({ 
  storage: memoryStorage,
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB
});

// For screenshots (local storage)
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
router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  uploadProfilePicture.single('image'),
  userController.uploadProfilePicture
);

// FCM Token Management Routes
router.post('/fcm-token', verifyFirebaseToken, userController.updateFCMToken);
router.delete('/fcm-token', verifyFirebaseToken, userController.removeFCMToken);
router.put('/notification-settings', verifyFirebaseToken, userController.updateNotificationSettings);

// ✅ TEST ENDPOINTS
router.post('/test-upload', verifyFirebaseToken, uploadProfilePicture.single('image'), async (req, res) => {
  try {
    console.log('🧪 Test upload endpoint called');
    
    res.json({
      success: true,
      message: 'Upload endpoint working',
      fileReceived: !!req.file,
      fileInfo: req.file ? {
        name: req.file.originalname,
        size: req.file.size,
        type: req.file.mimetype
      } : null,
      userAuthenticated: !!req.user,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Test upload error:', error);
    res.json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
