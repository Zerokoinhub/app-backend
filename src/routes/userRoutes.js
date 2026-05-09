const express = require('express');
const router = express.Router();
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');
const User = require('../models/User');
const { admin } = require('../config/firebase');

// ✅ Configure Multer for memory storage
const multer = require('multer');
const storage = multer.memoryStorage();
const upload = multer({ 
  storage: storage,
  limits: { 
    fileSize: 10 * 1024 * 1024, // 10MB limit
    files: 1
  },
  fileFilter: (req, file, cb) => {
    if (!file.originalname.match(/\.(jpg|jpeg|png|gif|webp)$/)) {
      return cb(new Error('Only image files are allowed!'), false);
    }
    cb(null, true);
  }
});

// ============================================
// ✅ PROFILE PICTURE UPLOAD - SINGLE ROUTE
// ============================================
router.post('/upload-screenshots', uploadScreenshots.array('screenshots', 10), userController.uploadScreenshots);
router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  (req, res, next) => {
    console.log('📤 Upload request received');
    console.log('🔍 Content-Type:', req.headers['content-type']);
    
    // FLUTTER 'image' FIELD BHEJ RAHA HAI
    const imageUpload = upload.single('image');
    
    imageUpload(req, res, (err) => {
      if (!err && req.file) {
        console.log('✅ File received via field: image (Flutter)');
        console.log('📁 File name:', req.file.originalname);
        console.log('📁 File size:', req.file.size);
        return next();
      }
      
      console.log('❌ image field not found!');
      return res.status(400).json({ 
        success: false, 
        message: 'No file uploaded. Expected field: image' 
      });
    });
  },
  async (req, res) => {
    try {
      console.log('📤 Starting Firebase Storage upload...');
      console.log('📁 File field name:', req.file.fieldname);
      console.log('👤 User:', req.user.uid);
      
      if (!req.file) {
        return res.status(400).json({ 
          success: false, 
          message: 'No file uploaded' 
        });
      }
      
      // Check file type
      if (!req.file.mimetype.startsWith('image/')) {
        return res.status(400).json({ 
          success: false, 
          message: 'Only image files are allowed' 
        });
      }
      
      const userId = req.user.uid;
      const userEmail = req.user.email || '';
      
      // ✅ Generate filename and path - CORRECT FOLDER NAME
      const fileExtension = req.file.originalname.split('.').pop() || 'jpg';
      const fileName = `${userId}_${Date.now()}.${fileExtension}`;
      const filePath = `profile_pics/${fileName}`;
      
      console.log('   File path:', filePath);
      
      // ✅ Get Firebase Storage bucket
      const bucket = admin.storage().bucket();
      const file = bucket.file(filePath);
      
      // ✅ Create download token
      const downloadToken = require('crypto').randomBytes(16).toString('hex');
      
      // ✅ Upload to Firebase Storage
      await file.save(req.file.buffer, {
        metadata: {
          contentType: req.file.mimetype,
          metadata: {
            firebaseStorageDownloadTokens: downloadToken,
            uploadedBy: userId,
            uploadedAt: new Date().toISOString(),
            userEmail: userEmail
          }
        },
        public: false
      });
      
      // ✅ Make public
      await file.makePublic();
      
      // ✅ Generate URL - EXACT format as sample
      const photoURL = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(filePath)}?alt=media&token=${downloadToken}`;
      
      console.log('✅ File uploaded successfully');
      console.log('📎 URL:', photoURL);
      
      // ✅ Update user in MongoDB - DIRECTLY IN ROUTE
      let user = await User.findOne({ firebaseUid: userId });
      
      if (!user) {
        console.log('   Creating new user entry...');
        user = new User({
          firebaseUid: userId,
          email: userEmail,
          name: req.user.name || '',
          photoURL: photoURL,
          profilePicture: photoURL,
          createdAt: new Date(),
          updatedAt: new Date()
        });
      } else {
        console.log('   Updating existing user:', user.email);
        user.photoURL = photoURL;
        user.profilePicture = photoURL;
        user.updatedAt = new Date();
        if (!user.email && userEmail) user.email = userEmail;
      }
      
      await user.save();
      console.log('   ✅ User saved successfully');
      
      // ✅ Return success response
      res.status(200).json({ 
        success: true, 
        message: 'Profile picture uploaded successfully to Firebase Storage',
        photoURL: photoURL,
        photoUrl: photoURL,
        data: {
          photoURL: photoURL,
          fileName: fileName,
          filePath: filePath,
          storageType: 'firebase',
          userId: userId
        }
      });
      
    } catch (error) {
      console.error('❌ Firebase Storage upload error:', error);
      console.error('   Error stack:', error.stack);
      
      res.status(500).json({
        success: false,
        message: 'Failed to upload profile picture',
        error: error.message
      });
    }
  }
);

// ============================================
// ✅ OTHER ROUTES - IMPORT FROM CONTROLLER
// ============================================
const userController = require('../controllers/userController');
const { getUserSessions, unlockNextSession, completeSession } = require('../controllers/userController');

router.post('/register', userController.registerUser);
router.get('/invite/:inviteCode', userController.getInviteDetails);
router.post('/referral', userController.processReferral);
router.get('/sessions', verifyFirebaseToken, getUserSessions);
router.post('/unlock', verifyFirebaseToken, unlockNextSession);
router.post('/complete-session', verifyFirebaseToken, completeSession);
router.post('/reset-sessions', verifyFirebaseToken, userController.resetUserSessions);
router.post('/sync', verifyFirebaseToken, userController.syncFirebaseUser);
router.get('/profile', verifyFirebaseToken, userController.getUserProfile);
router.put('/profile', verifyFirebaseToken, userController.updateUserProfile);
router.put('/wallet-address', verifyFirebaseToken, userController.updateWalletAddress);
router.get('/count', userController.getUserCount);
router.put('/calculator-usage', verifyFirebaseToken, userController.incrementCalculatorUsage);
router.put('/update-balance', verifyFirebaseToken, userController.updateUserBalance);
router.post('/upload-screenshots', verifyFirebaseToken, upload.array('screenshots', 6), userController.uploadScreenshots);
router.post('/fcm-token', verifyFirebaseToken, userController.updateFCMToken);
router.delete('/fcm-token', verifyFirebaseToken, userController.removeFCMToken);
router.put('/notification-settings', verifyFirebaseToken, userController.updateNotificationSettings);

module.exports = router;
