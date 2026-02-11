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
