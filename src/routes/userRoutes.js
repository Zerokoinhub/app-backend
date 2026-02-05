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


// ============ SESSION ROUTES ============

// GET user sessions
router.get('/sessions', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const firebaseEmail = req.user.email;
    
    console.log('📥 GET /sessions for:', {
      userId,
      email: firebaseEmail
    });
    
    let user = await User.findOne({ firebaseUid: userId });
    
    if (!user && firebaseEmail) {
      user = await User.findOne({ email: firebaseEmail });
      
      if (user && !user.firebaseUid) {
        user.firebaseUid = userId;
        await user.save();
        console.log('✅ Updated firebaseUid for existing user');
      }
    }
    
    if (!user) {
      console.log('🆕 Creating new user with sessions for:', userId);
      
      const generateInviteCode = () => {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        let code = '';
        for (let i = 0; i < 8; i++) {
          code += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return code;
      };
      
      const now = new Date();
      
      const sessions = [
        {
          sessionNumber: 1,
          unlockedAt: now,
          completedAt: null,
          isLocked: false,
          isClaimed: false,
          coinsClaimedAt: null,
          nextUnlockAt: null,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 2,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          isClaimed: false,
          coinsClaimedAt: null,
          nextUnlockAt: null,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 3,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          isClaimed: false,
          coinsClaimedAt: null,
          nextUnlockAt: null,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 4,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          isClaimed: false,
          coinsClaimedAt: null,
          nextUnlockAt: null,
          createdAt: now,
          lastUpdated: now
        }
      ];
      
      user = await User.create({
        firebaseUid: userId,
        email: firebaseEmail,
        name: req.user.name || '',
        photoURL: req.user.picture || '',
        inviteCode: generateInviteCode(),
        sessions: sessions,
        createdAt: now,
        updatedAt: now
      });
      
      console.log('✅ New user created with sessions:', user._id);
      
      return res.json({ 
        success: true, 
        sessions: sessions,
        message: 'New user sessions created',
        user: userId
      });
    }
    
    if (!user.sessions || user.sessions.length === 0) {
      console.log('🔄 Creating sessions for existing user:', user._id);
      
      const now = new Date();
      
      const sessions = [
        {
          sessionNumber: 1,
          unlockedAt: now,
          completedAt: null,
          isLocked: false,
          isClaimed: false,
          coinsClaimedAt: null,
          nextUnlockAt: null,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 2,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          isClaimed: false,
          coinsClaimedAt: null,
          nextUnlockAt: null,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 3,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          isClaimed: false,
          coinsClaimedAt: null,
          nextUnlockAt: null,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 4,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          isClaimed: false,
          coinsClaimedAt: null,
          nextUnlockAt: null,
          createdAt: now,
          lastUpdated: now
        }
      ];
      
      user.sessions = sessions;
      await user.save();
      
      console.log('✅ Sessions created for existing user');
      
      return res.json({ 
        success: true, 
        sessions: sessions,
        message: 'Sessions created for existing user',
        user: userId
      });
    }
    
    console.log('✅ Returning existing sessions for user:', user._id);
    console.log('   Session count:', user.sessions.length);
    
    const now = new Date();
    let updatedSessions = user.sessions.map(session => {
      const sessionCopy = { ...session._doc || session };
      
      if (sessionCopy.nextUnlockAt && typeof sessionCopy.nextUnlockAt === 'string') {
        sessionCopy.nextUnlockAt = new Date(sessionCopy.nextUnlockAt);
      }
      
      if (sessionCopy.isLocked && sessionCopy.nextUnlockAt) {
        if (now >= sessionCopy.nextUnlockAt) {
          sessionCopy.isLocked = false;
          sessionCopy.unlockedAt = now;
          sessionCopy.nextUnlockAt = null;
          console.log(`🔓 Auto-unlocked session ${sessionCopy.sessionNumber}`);
        }
      }
      
      return sessionCopy;
    });
    
    const sessionsChanged = updatedSessions.some((session, index) => 
      JSON.stringify(session) !== JSON.stringify(user.sessions[index])
    );
    
    if (sessionsChanged) {
      user.sessions = updatedSessions;
      await user.save();
      console.log('🔓 Updated session lock status');
    }
    
    res.json({ 
      success: true, 
      sessions: updatedSessions,
      message: 'Sessions retrieved successfully',
      user: userId
    });
    
  } catch (error) {
    console.error('❌ GET /sessions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch sessions',
      error: error.message
    });
  }
});

// ✅ COMPLETE SESSION WITH CLAIM LOGIC
router.post('/complete-session', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { sessionNumber } = req.body;
    
    if (!sessionNumber || sessionNumber < 1 || sessionNumber > 4) {
      return res.status(400).json({
        success: false,
        message: 'Invalid session number. Must be between 1 and 4'
      });
    }
    
    console.log('🎯 Completing session', sessionNumber, 'for user:', userId);
    
    const user = await User.findOne({ firebaseUid: userId });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    if (!user.sessions || user.sessions.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No sessions found for user'
      });
    }
    
    const sessionIndex = user.sessions.findIndex(
      s => s.sessionNumber === sessionNumber
    );
    
    if (sessionIndex === -1) {
      return res.status(404).json({
        success: false,
        message: `Session ${sessionNumber} not found`
      });
    }
    
    const session = user.sessions[sessionIndex];
    const now = new Date();
    
    // Check if already claimed
    if (session.isClaimed) {
      return res.json({
        success: true,
        message: `Session ${sessionNumber} coins already claimed`,
        session: session,
        sessionsReset: false
      });
    }
    
    // Check if locked
    if (session.isLocked) {
      return res.status(400).json({
        success: false,
        message: `Session ${sessionNumber} is locked`,
        nextUnlockAt: session.nextUnlockAt
      });
    }
    
    // ✅ STEP 1: MARK AS COMPLETED (if not already)
    if (!session.completedAt) {
      user.sessions[sessionIndex].completedAt = now;
      console.log(`✅ Marked session ${sessionNumber} as completed`);
    }
    
    // ✅ STEP 2: CLAIM THE COINS
    user.sessions[sessionIndex].isClaimed = true;
    user.sessions[sessionIndex].coinsClaimedAt = now;
    user.sessions[sessionIndex].lastUpdated = now;
    
    // Add balance
    user.balance = (user.balance || 0) + 30;
    
    let sessionsReset = false;
    
    // ✅ IMPORTANT: Next session timer starts FROM CLAIM TIME
    if (sessionNumber === 4) {
      console.log('🔄 Session 4 claimed! Resetting cycle...');
      
      const session1UnlockTime = new Date(now.getTime() + 6 * 60 * 60 * 1000);
      
      user.sessions = user.sessions.map((s, index) => {
        if (index === 0) {
          return {
            sessionNumber: 1,
            unlockedAt: null,
            completedAt: null,
            isLocked: true,
            isClaimed: false,
            coinsClaimedAt: null,
            nextUnlockAt: session1UnlockTime,
            createdAt: s.createdAt || now,
            lastUpdated: now
          };
        } else {
          return {
            sessionNumber: index + 1,
            unlockedAt: null,
            completedAt: null,
            isLocked: true,
            isClaimed: false,
            coinsClaimedAt: null,
            nextUnlockAt: null,
            createdAt: s.createdAt || now,
            lastUpdated: now
          };
        }
      });
      
      sessionsReset = true;
      user.lastSessionCycleCompletedAt = now;
      console.log(`⏰ Session 1 will unlock at: ${session1UnlockTime}`);
    }
    else if (sessionNumber < 4) {
      const nextSessionIndex = sessionIndex + 1;
      if (nextSessionIndex < user.sessions.length) {
        const unlockTime = new Date(now.getTime() + 6 * 60 * 60 * 1000);
        
        user.sessions[nextSessionIndex].isLocked = true;
        user.sessions[nextSessionIndex].nextUnlockAt = unlockTime;
        user.sessions[nextSessionIndex].lastUpdated = now;
        
        console.log(`⏰ Session ${nextSessionIndex + 1} will unlock at: ${unlockTime}`);
      }
    }
    
    user.lastSessionCompletedAt = now;
    user.updatedAt = now;
    
    await user.save();
    
    console.log('✅ Session coins claimed successfully');
    console.log('   New balance:', user.balance);
    console.log('   Sessions reset:', sessionsReset);
    
    res.json({
      success: true,
      message: `Session ${sessionNumber} coins claimed successfully`,
      balanceAdded: 30,
      newBalance: user.balance,
      sessions: user.sessions,
      sessionsReset: sessionsReset,
      nextSessionAvailable: sessionNumber < 4 ? 
        `Session ${sessionNumber + 1} available in 6 hours` : 
        'Session 1 available in 6 hours'
    });
    
  } catch (error) {
    console.error('❌ POST /complete-session error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to complete session',
      error: error.message
    });
  }
});

// ✅ RESET SESSIONS
router.post('/reset-sessions', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const now = new Date();
    
    console.log('🔄 Resetting sessions for user:', userId);
    
    const user = await User.findOne({ firebaseUid: userId });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    const sessions = [
      {
        sessionNumber: 1,
        unlockedAt: now,
        completedAt: null,
        isLocked: false,
        isClaimed: false,
        coinsClaimedAt: null,
        nextUnlockAt: null,
        createdAt: now,
        lastUpdated: now
      },
      {
        sessionNumber: 2,
        unlockedAt: null,
        completedAt: null,
        isLocked: true,
        isClaimed: false,
        coinsClaimedAt: null,
        nextUnlockAt: null,
        createdAt: now,
        lastUpdated: now
      },
      {
        sessionNumber: 3,
        unlockedAt: null,
        completedAt: null,
        isLocked: true,
        isClaimed: false,
        coinsClaimedAt: null,
        nextUnlockAt: null,
        createdAt: now,
        lastUpdated: now
      },
      {
        sessionNumber: 4,
        unlockedAt: null,
        completedAt: null,
        isLocked: true,
        isClaimed: false,
        coinsClaimedAt: null,
        nextUnlockAt: null,
        createdAt: now,
        lastUpdated: now
      }
    ];
    
    user.sessions = sessions;
    user.lastSessionCompletedAt = null;
    user.updatedAt = now;
    await user.save();
    
    console.log('✅ Sessions reset successfully');
    
    res.json({
      success: true,
      message: 'Sessions reset successfully',
      sessions: sessions
    });
    
  } catch (error) {
    console.error('❌ POST /reset-sessions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reset sessions',
      error: error.message
    });
  }
});

// ============ PROFILE ROUTES ============

router.get('/profile', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const firebaseEmail = req.user.email;
    
    console.log('📥 GET /profile for:', {
      userId,
      email: firebaseEmail
    });
    
    let user = await User.findOne({ firebaseUid: userId });
    
    if (!user && firebaseEmail) {
      user = await User.findOne({ email: firebaseEmail });
      
      if (user && !user.firebaseUid) {
        user.firebaseUid = userId;
        await user.save();
        console.log('✅ Updated firebaseUid for existing user');
      }
    }
    
    if (!user) {
      console.log('🆕 Creating new user for:', userId);
      
      const generateInviteCode = () => {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        let code = '';
        for (let i = 0; i < 8; i++) {
          code += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return code;
      };
      
      user = await User.create({
        firebaseUid: userId,
        email: firebaseEmail,
        name: req.user.name || '',
        photoURL: req.user.picture || '',
        inviteCode: generateInviteCode(),
        createdAt: new Date(),
        updatedAt: new Date()
      });
      
      console.log('✅ New user created:', user._id);
    }
    
    res.json({ 
      success: true, 
      user: {
        _id: user._id,
        name: user.name,
        photoURL: user.photoURL,
        email: user.email,
        firebaseUid: user.firebaseUid,
        inviteCode: user.inviteCode,
        balance: user.balance || 0,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }
    });
    
  } catch (error) {
    console.error('❌ GET /profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch profile',
      error: error.message
    });
  }
});

router.put('/profile', verifyFirebaseToken, async (req, res) => {
  console.log('✅ PUT /profile called with data:', req.body);
  
  if (!req.body || Object.keys(req.body).length === 0) {
    return res.status(400).json({
      success: false,
      message: 'No data provided for update'
    });
  }
  
  try {
    const userId = req.user.uid;
    const firebaseEmail = req.user.email;
    
    const { displayName, photoURL, email } = req.body;
    
    console.log(`🔄 Updating user ${userId} with:`, {
      displayName,
      photoURL,
      email: email || firebaseEmail
    });
    
    const updateData = {
      updatedAt: new Date()
    };
    
    if (displayName !== undefined && displayName !== null && displayName !== '') {
      updateData.name = displayName;
      console.log(`   Mapping: displayName "${displayName}" → name "${displayName}"`);
    }
    
    if (photoURL !== undefined && photoURL !== null && photoURL !== '') {
      updateData.photoURL = photoURL;
      console.log(`   Setting photoURL: ${photoURL}`);
    }
    
    if (email !== undefined && email !== null && email !== '') {
      updateData.email = email;
      console.log(`   Setting email: ${email}`);
    } else if (firebaseEmail) {
      updateData.email = firebaseEmail;
      console.log(`   Using Firebase email: ${firebaseEmail}`);
    }
    
    updateData.firebaseUid = userId;
    
    console.log('📦 Final update data for MongoDB:', updateData);
    
    const updatedUser = await User.findOneAndUpdate(
      { firebaseUid: userId },
      { 
        $set: updateData
      },
      { 
        new: true,
        upsert: true,
        runValidators: true
      }
    );
    
    console.log('✅ MongoDB update successful!');
    console.log('   User ID:', updatedUser._id);
    console.log('   Name:', updatedUser.name);
    console.log('   PhotoURL:', updatedUser.photoURL);
    console.log('   Email:', updatedUser.email);
    
    res.json({
      success: true,
      message: 'Profile updated successfully',
      updatedFields: {
        name: updatedUser.name,
        photoURL: updatedUser.photoURL,
        email: updatedUser.email
      },
      user: {
        _id: updatedUser._id,
        name: updatedUser.name,
        photoURL: updatedUser.photoURL,
        email: updatedUser.email,
        firebaseUid: updatedUser.firebaseUid
      },
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('❌ PUT /profile error:', error);
    
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        error: error.message,
        details: error.errors
      });
    }
    
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Duplicate key error',
        error: 'Email or firebaseUid already exists'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to update profile',
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// ============ FILE UPLOAD ============

const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }
});

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
      
      const fileName = `${userId}_${Date.now()}_${req.file.originalname}`;
      const photoURL = `https://storage.googleapis.com/your-bucket/profile_pics/${fileName}`;
      
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
      
      res.json({ 
        success: true, 
        message: 'Profile picture uploaded successfully',
        photoURL: photoURL,
        photoUrl: photoURL,
        file: {
          name: req.file.originalname,
          size: req.file.size,
          type: req.file.mimetype,
          url: photoURL
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
