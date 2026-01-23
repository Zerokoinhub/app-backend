// userRoutes.js - CORRECT VERSION
const express = require('express');
const router = express.Router();
const multer = require('multer');

console.log('✅ userRoutes.js loading successfully');

// ============ SIMPLE ROUTES ============
router.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    message: 'Backend is alive' 
  });
});

// ✅ LINE 33 FIXED - This should be around line 15-20 now
router.get('/invite/:inviteCode', (req, res) => {
  console.log('✅ Invite route called with code:', req.params.inviteCode);
  res.json({ 
    success: true, 
    inviteCode: req.params.inviteCode,
    message: 'Invite system placeholder' 
  });
});

// ============ FILE UPLOAD ============
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }
});

router.post('/upload-profile-picture', 
  upload.single('image'),
  (req, res) => {
    if (!req.file) {
      return res.status(400).json({ 
        success: false, 
        message: 'No file uploaded' 
      });
    }
    
    res.json({ 
      success: true, 
      message: 'Profile picture uploaded successfully',
      file: {
        name: req.file.originalname,
        size: req.file.size,
        type: req.file.mimetype
      }
    });
  }
);

module.exports = router;
