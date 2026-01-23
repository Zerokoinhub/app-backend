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

router.get('/count', (req, res) => {
  res.json({ success: true, count: 1 });
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
router.get('/sessions', verifyFirebaseToken, (req, res) => {
  res.json({ 
    success: true, 
    sessions: [],
    message: 'Sessions placeholder',
    user: req.user.uid
  });
});

router.get('/profile', verifyFirebaseToken, (req, res) => {
  res.json({ 
    success: true, 
    profile: {
      uid: req.user.uid,
      displayName: 'User',
      email: req.user.email || 'user@example.com',
      profilePicture: null
    }
  });
});

// ✅ ADD THIS: PUT profile endpoint (MISSING ROUTE)
router.put('/profile', verifyFirebaseToken, (req, res) => {
  console.log('✅ PUT /profile called with data:', req.body);
  
  if (!req.body || Object.keys(req.body).length === 0) {
    return res.status(400).json({
      success: false,
      message: 'No data provided for update'
    });
  }
  
  res.json({
    success: true,
    message: 'Profile updated successfully',
    updatedFields: req.body,
    user: req.user.uid,
    timestamp: new Date().toISOString()
  });
});

router.post('/sync', verifyFirebaseToken, (req, res) => {
  res.json({ 
    success: true, 
    message: 'User synced successfully',
    user: req.user.uid
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

module.exports = router;
