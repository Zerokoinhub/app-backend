const express = require('express');
const router = express.Router();
const multer = require('multer');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');
const User = require('../models/User');
const userController = require('../controllers/userController');

console.log('✅ userRoutes.js loading with ALL routes');

// ============ MULTER SETUP ============
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }
});

// ============ PUBLIC ROUTES ============
router.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    message: 'Backend is alive' 
  });
});

router.get('/count', userController.getUserCount);
router.get('/invite/:inviteCode', userController.getInviteDetails);

// ============ SESSION ROUTES ============
router.get('/sessions', verifyFirebaseToken, userController.getUserSessions);
router.post('/complete-session', verifyFirebaseToken, userController.completeSession);
router.post('/reset-sessions', verifyFirebaseToken, userController.resetUserSessions);

// ============ PROFILE ROUTES ============
router.get('/profile', verifyFirebaseToken, userController.getUserProfile);

// ✅ UPDATED: PUT /profile ko controller mein move kiya
router.put('/profile', verifyFirebaseToken, userController.updateUserProfile);

// ============ FILE UPLOAD ============
router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  upload.single('image'),
  async (req, res) => {
    if (!req.file) {
      return res.status(400).json({ 
        success: false, 
        message: 'No file uploaded' 
      });
    }
    
    try {
      const userId = req.user.uid;
      const firebaseEmail = req.user.email;
      
      console.log('📤 Uploading profile picture for:', userId);
      
      // ✅ CRITICAL: ACTUAL FILE UPLOAD LOGIC YAHAN ADD KARO
      const fileName = `${userId}_${Date.now()}_${req.file.originalname}`;
      
      // Google Cloud Storage URL (yehi old code se copy karo)
      const photoURL = `https://storage.googleapis.com/your-bucket/profile_pics/${fileName}`;
      
      // Cloudinary ya Firebase Storage logic yahan implement karo
      
      const updatedUser = await User.findOneAndUpdate(
        { firebaseUid: userId },
        { 
          $set: { 
            photoURL: photoURL,
            updatedAt: new Date(),
            email: firebaseEmail
          }
        },
        { 
          new: true,
          upsert: true 
        }
      );
      
      console.log('✅ Profile picture saved to MongoDB');
      
      // ✅ FLUTTER KE LIYE CORRECT RESPONSE FORMAT
      res.json({ 
        success: true, 
        message: 'Profile picture uploaded successfully',
        photoURL: photoURL,  // ✅ yeh Flutter get karega
        photoUrl: photoURL,  // ✅ alternative key
        file: {
          name: req.file.originalname,
          size: req.file.size,
          type: req.file.mimetype,
          url: photoURL      // ✅ yahan bhi URL provide karo
        },
        user: {
          _id: updatedUser._id,
          name: updatedUser.name,
          photoURL: updatedUser.photoURL,
          email: updatedUser.email
        }
      });
      
    } catch (error) {
      console.error('❌ Upload error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to upload profile picture',
        error: error.message
      });
    }
  }
);

// ============ SCREENSHOTS UPLOAD ============
router.post('/upload-screenshots', 
  verifyFirebaseToken, 
  upload.array('screenshots', 6), 
  userController.uploadScreenshots
);

// ============ OTHER ROUTES ============
router.post('/register', userController.registerUser);
router.post('/referral', userController.processReferral);
router.post('/sync', verifyFirebaseToken, userController.syncFirebaseUser);
router.put('/wallet-address', verifyFirebaseToken, userController.updateWalletAddress);
router.put('/calculator-usage', verifyFirebaseToken, userController.incrementCalculatorUsage);
router.put('/update-balance', verifyFirebaseToken, userController.updateUserBalance);
router.post('/unlock', verifyFirebaseToken, userController.unlockNextSession);

// ============ FCM TOKEN MANAGEMENT ============
router.post('/fcm-token', verifyFirebaseToken, userController.updateFCMToken);
router.delete('/fcm-token', verifyFirebaseToken, userController.removeFCMToken);
router.put('/notification-settings', verifyFirebaseToken, userController.updateNotificationSettings);

// ============ DEBUG ROUTES ============
router.get('/debug-field-mapping', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    
    console.log('🔍 Field mapping debug for:', userId);
    
    const user = await User.findOne({ firebaseUid: userId });
    
    if (!user) {
      return res.json({
        exists: false,
        message: 'User not found in MongoDB',
        firebaseUid: userId,
        firebaseEmail: req.user.email,
        firebaseName: req.user.name
      });
    }
    
    const userObj = user.toObject();
    
    res.json({
      exists: true,
      mongoDBFields: Object.keys(userObj),
      currentData: {
        _id: user._id,
        name: user.name,
        displayName: user.displayName,
        photoURL: user.photoURL,
        email: user.email,
        firebaseUid: user.firebaseUid,
        balance: user.balance,
        sessionsCount: user.sessions ? user.sessions.length : 0
      },
      fieldMapping: {
        'Flutter sends': 'displayName',
        'MongoDB stores': 'name',
        'Node.js maps': 'displayName → name'
      },
      schemaCheck: {
        hasNameField: user.schema.path('name') !== undefined,
        hasDisplayNameField: user.schema.path('displayName') !== undefined,
        hasPhotoURLField: user.schema.path('photoURL') !== undefined,
        hasSessionsField: user.schema.path('sessions') !== undefined
      }
    });
    
  } catch (error) {
    console.error('Debug error:', error);
    res.status(500).json({ error: error.message });
  }
});

router.get('/debug-sessions', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const user = await User.findOne({ firebaseUid: userId });
    
    res.json({
      success: true,
      userExists: !!user,
      hasSessionsField: user && user.sessions !== undefined,
      sessionsCount: user ? (user.sessions ? user.sessions.length : 0) : 0,
      sessions: user ? user.sessions : [],
      userDetails: user ? {
        _id: user._id,
        name: user.name,
        email: user.email,
        balance: user.balance,
        firebaseUid: user.firebaseUid
      } : null
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ✅ TEST ROUTE FOR UPLOAD
router.post('/test-upload', 
  verifyFirebaseToken,
  upload.single('image'),
  async (req, res) => {
    if (!req.file) {
      return res.status(400).json({ 
        success: false, 
        message: 'No file uploaded' 
      });
    }
    
    console.log('🧪 Test upload received:', {
      fileName: req.file.originalname,
      size: req.file.size,
      mimeType: req.file.mimetype
    });
    
    res.json({
      success: true,
      message: 'Test upload successful',
      file: {
        name: req.file.originalname,
        size: req.file.size,
        type: req.file.mimetype
      }
    });
  }
);

// ✅ SIMPLE TEST ROUTE
router.get('/simple-test', verifyFirebaseToken, (req, res) => {
  res.json({
    success: true,
    message: 'Simple test successful',
    user: req.user.uid,
    timestamp: new Date().toISOString()
  });
});

router.get('/debug-routes', (req, res) => {
  console.log('🔍 Incoming request to /debug-routes');
  
  res.json({
    routesAvailable: [
      'GET /api/users/health',
      'GET /api/users/count',
      'GET /api/users/invite/:inviteCode',
      'GET /api/users/sessions',
      'POST /api/users/complete-session',
      'POST /api/users/reset-sessions',
      'GET /api/users/profile',
      'PUT /api/users/profile',
      'POST /api/users/upload-profile-picture',
      'POST /api/users/upload-screenshots',
      'POST /api/users/register',
      'POST /api/users/referral',
      'POST /api/users/sync',
      'PUT /api/users/wallet-address',
      'PUT /api/users/calculator-usage',
      'PUT /api/users/update-balance',
      'POST /api/users/unlock',
      'POST /api/users/fcm-token',
      'DELETE /api/users/fcm-token',
      'PUT /api/users/notification-settings',
      'POST /api/users/test-upload',
      'GET /api/users/simple-test'
    ],
    currentRequest: {
      method: req.method,
      url: req.originalUrl,
      query: req.query,
      headers: {
        authorization: req.headers.authorization ? 'Present' : 'Missing',
        'content-type': req.headers['content-type']
      }
    }
  });
});

module.exports = router;
