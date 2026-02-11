const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');
const User = require('../models/User'); // Make sure to import User model
const admin = require('../config/firebase'); // Import Firebase Admin

// Configure Multer for memory storage
const multer = require('multer');
const storage = multer.memoryStorage();
const upload = multer({ 
  storage: storage,
  limits: { 
    fileSize: 10 * 1024 * 1024, // 10MB limit
    files: 1
  },
  fileFilter: (req, file, cb) => {
    // Accept images only
    if (!file.originalname.match(/\.(jpg|jpeg|png|gif|webp)$/)) {
      return cb(new Error('Only image files are allowed!'), false);
    }
    cb(null, true);
  }
});

// ✅ WORKING Firebase Storage Profile Picture Upload - COMPLETE FIXED VERSION
// CLOUDINARY VERSION - Agar Cloudinary use karna hai
router.post('/upload-profile-picture',
  verifyFirebaseToken,
  upload.single('image'),
  userController.uploadProfilePicture  // Cloudinary controller
);
      
      // ============ 🔥 FIXED: CORRECT FOLDER NAME ============
      // ✅ Sample URL: profile_pics/filename.jpg
      const fileExtension = req.file.originalname.split('.').pop() || 'jpg';
      const fileName = `${userId}_${Date.now()}.${fileExtension}`;
      const filePath = `profile_pics/${fileName}`;  // ← FIXED: profile_pics/ not profile_pictures/
      
      console.log('   Generated file path:', filePath);
      
      // ✅ Get Firebase Storage bucket
      const bucket = admin.storage().bucket();
      const file = bucket.file(filePath);
      
      // ✅ Create a unique download token
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
      
      // ✅ Make file publicly accessible
      await file.makePublic();
      
      // ============ 🔥 FIXED: CORRECT URL FORMAT ============
      // ✅ EXACT format as your sample URL
      const photoURL = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(filePath)}?alt=media&token=${downloadToken}`;
      
      console.log('✅ File uploaded successfully');
      console.log('📎 URL:', photoURL);
      
      // ✅ Update user in MongoDB
      try {
        const updatedUser = await User.findOneAndUpdate(
          { firebaseUid: userId },
          { 
            $set: { 
              photoURL: photoURL,
              profilePicture: photoURL,
              updatedAt: new Date(),
              email: userEmail
            }
          },
          { 
            new: true,
            upsert: false 
          }
        );
        
        if (!updatedUser) {
          console.warn('⚠️ User not found in MongoDB for firebaseUid:', userId);
        } else {
          console.log('✅ User updated in MongoDB');
        }
      } catch (dbError) {
        console.error('❌ MongoDB update error:', dbError);
      }
      
      // ✅ Return success response - Flutter compatible format
      res.status(200).json({ 
        success: true, 
        message: 'Profile picture uploaded successfully',
        photoURL: photoURL,        // ← Flutter expects this
        photoUrl: photoURL,        // ← Alternative format
        data: {
          photoURL: photoURL,
          fileName: fileName,
          filePath: filePath,
          storageType: 'firebase',
          timestamp: new Date().toISOString(),
          userId: userId
        }
      });
      
    } catch (error) {
      console.error('❌ Firebase Storage upload error:', error);
      console.error('   Error stack:', error.stack);
      
      // Specific error handling
      if (error.code === 'app/no-app' || error.code === 'app/invalid-credential') {
        return res.status(500).json({
          success: false,
          message: 'Firebase Admin configuration error',
          error: 'Please check your Firebase service account credentials'
        });
      }
      
      if (error.code === 403 || error.message.includes('permission')) {
        return res.status(403).json({
          success: false,
          message: 'Storage permission denied',
          error: 'Check Firebase Storage rules'
        });
      }
      
      res.status(500).json({
        success: false,
        message: 'Failed to upload profile picture',
        error: error.message,
        code: error.code
      });
    }
  }
);

// ✅ Alternative: Simple upload endpoint (for testing)
router.post('/upload-simple', 
  verifyFirebaseToken,
  upload.single('file'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'No file provided' });
      }
      
      const userId = req.user.uid;
      const bucket = admin.storage().bucket();
      const fileName = `test_${userId}_${Date.now()}.jpg`;
      
      const file = bucket.file(fileName);
      
      await file.save(req.file.buffer, {
        metadata: {
          contentType: req.file.mimetype,
          metadata: {
            uploadedBy: userId
          }
        }
      });
      
      // Get signed URL (valid for 15 minutes)
      const [signedUrl] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 15 * 60 * 1000 // 15 minutes
      });
      
      res.json({
        success: true,
        url: signedUrl,
        message: 'File uploaded successfully'
      });
      
    } catch (error) {
      console.error('Simple upload error:', error);
      res.status(500).json({ error: error.message });
    }
  }
);

// ✅ Test endpoint to verify Firebase Admin is working
router.get('/test-firebase', verifyFirebaseToken, async (req, res) => {
  try {
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({ maxResults: 5 });
    
    res.json({
      success: true,
      message: 'Firebase Admin is working',
      bucketName: bucket.name,
      fileCount: files.length,
      user: req.user.uid
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Firebase Admin error',
      error: error.message
    });
  }
});

module.exports = router;
