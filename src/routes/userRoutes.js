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
// router.post('/upload-profile-picture', 
//   verifyFirebaseToken,
//   uploadProfilePicture.single('image'),
//   userController.uploadProfilePicture
// );

// ✅ FIXED: Working profile picture upload to Firebase Storage
router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  upload.single('image'),
  async (req, res) => {
    try {
      console.log('📤 Firebase Storage upload for:', req.user.uid);
      
      if (!req.file) {
        return res.status(400).json({ 
          success: false, 
          message: 'No file uploaded' 
        });
      }
      
      const userId = req.user.uid;
      const fileName = `${userId}_${Date.now()}_${req.file.originalname}`;
      
      console.log('   File details:', {
        name: fileName,
        size: req.file.size,
        type: req.file.mimetype
      });
      
      // ✅ Get Firebase Storage bucket
      const bucket = admin.storage().bucket();
      
      // ✅ Create a file reference
      const file = bucket.file(`profile_pics/${fileName}`);
      
      // ✅ Upload the buffer to Firebase Storage
      await file.save(req.file.buffer, {
        metadata: {
          contentType: req.file.mimetype,
          metadata: {
            firebaseStorageDownloadTokens: userId,
            uploadedBy: userId,
            uploadedAt: new Date().toISOString()
          }
        },
        public: true
      });
      
      // ✅ Generate public URL with token
      const [metadata] = await file.getMetadata();
      const token = metadata.metadata.firebaseStorageDownloadTokens || userId;
      
      const photoURL = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${token}`;
      
      console.log('✅ File uploaded to Firebase Storage:', photoURL);
      
      // ✅ Update user in MongoDB
      const updatedUser = await User.findOneAndUpdate(
        { firebaseUid: userId },
        { 
          $set: { 
            photoURL: photoURL,
            updatedAt: new Date(),
            email: req.user.email
          }
        },
        { 
          new: true,
          upsert: true 
        }
      );
      
      console.log('✅ MongoDB updated with Firebase Storage URL');
      
      // Return response
      res.json({ 
        success: true, 
        message: 'Profile picture uploaded to Firebase Storage',
        photoURL: photoURL,
        photoUrl: photoURL,
        storage: 'firebase',
        fileInfo: {
          name: fileName,
          size: req.file.size,
          contentType: req.file.mimetype
        }
      });
      
    } catch (error) {
      console.error('❌ Firebase Storage upload error:', error);
      
      // Check if it's Firebase Admin error
      if (error.code === 'app/no-app') {
        return res.status(500).json({
          success: false,
          message: 'Firebase Admin not configured',
          error: 'FIREBASE_SERVICE_ACCOUNT environment variable missing'
        });
      }
      
      res.status(500).json({
        success: false,
        message: 'Failed to upload to Firebase Storage',
        error: error.message,
        code: error.code
      });
    }
  }
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
