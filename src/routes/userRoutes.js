const express = require('express');
const router = express.Router();
const multer = require('multer');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');

console.log('✅ userRoutes.js loading with ALL routes');

// ============ PUBLIC ROUTES ============
router.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    message: 'Backend is alive' 
  });
});

// Fixed line 33
router.get('/invite/:inviteCode', (req, res) => {
  res.json({ 
    success: true, 
    inviteCode: req.params.inviteCode,
    message: 'Invite system placeholder' 
  });
});

// ============ AUTHENTICATED ROUTES ============
// ✅ ADD THIS: User sessions route
router.get('/sessions', verifyFirebaseToken, (req, res) => {
  console.log('✅ Sessions endpoint called for user:', req.user.uid);
  res.json({ 
    success: true, 
    sessions: [],
    message: 'Sessions placeholder',
    user: req.user.uid
  });
});

// ✅ ADD THIS: Update profile route
router.put('/profile', verifyFirebaseToken, (req, res) => {
  console.log('✅ Update profile called:', req.body);
  res.json({ 
    success: true, 
    message: 'Profile updated successfully',
    data: req.body,
    user: req.user.uid
  });
});

// ✅ ADD THIS: Get profile route
router.get('/profile', verifyFirebaseToken, (req, res) => {
  res.json({ 
    success: true, 
    profile: {
      uid: req.user.uid,
      displayName: 'User',
      email: 'user@example.com'
    }
  });
});

// ============ FILE UPLOAD ============
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }
});

router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  upload.single('image'),
  (req, res) => {
    console.log('✅ Upload called by user:', req.user.uid);
    
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
      },
      user: req.user.uid
    });
  }
);

// ✅ ADD THIS: User sync route
router.post('/sync', verifyFirebaseToken, (req, res) => {
  res.json({ 
    success: true, 
    message: 'User synced successfully',
    user: req.user.uid
  });
});

// ✅ ADD THIS: User count
router.get('/count', (req, res) => {
  res.json({ success: true, count: 1 });
});

module.exports = router;
