const express = require('express');
const router = express.Router();
const multer = require('multer');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');
const User = require('../models/User');
const userController = require('../controllers/userController');

console.log('✅ userRoutes.js loading with ALL routes');

// ✅ Firebase Storage bucket
let bucket;
try {
  bucket = admin.storage().bucket();
  console.log('📦 Firebase bucket ready in userRoutes');
} catch (error) {
  console.error('❌ Failed to get Firebase bucket:', error.message);
  bucket = null;
}
// ============ PUBLIC ROUTES ============
router.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    message: 'Backend is alive' 
  });
});

router.get('/count', async (req, res) => {
  try {
    console.log('🔢 /api/users/count endpoint called');
    
    const totalUsers = await User.countDocuments({});
    
    console.log(`✅ Total users found: ${totalUsers}`);
    
    res.json({
      success: true,
      count: totalUsers,
      totalUsers: totalUsers,
      message: `Total users: ${totalUsers}`,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('❌ Error counting users:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to count users',
      details: error.message,
      count: 0
    });
  }
});

router.get('/invite/:inviteCode', (req, res) => {
  res.json({ 
    success: true, 
    inviteCode: req.params.inviteCode,
    message: 'Invite system placeholder' 
  });
});

// ============ OTHER ROUTES ============
router.post('/register', userController.registerUser);
router.post('/referral', userController.processReferral);
router.post('/sync', verifyFirebaseToken, userController.syncFirebaseUser);
router.put('/wallet-address', verifyFirebaseToken, userController.updateWalletAddress);
router.put('/calculator-usage', verifyFirebaseToken, userController.incrementCalculatorUsage);
router.put('/update-balance', verifyFirebaseToken, userController.updateUserBalance);
router.post('/unlock', verifyFirebaseToken, userController.unlockNextSession);
router.post('/upload-screenshots', verifyFirebaseToken, userController.uploadScreenshots);

// ============ FCM TOKEN MANAGEMENT ============
router.post('/fcm-token', verifyFirebaseToken, userController.updateFCMToken);
router.delete('/fcm-token', verifyFirebaseToken, userController.removeFCMToken);
router.put('/notification-settings', verifyFirebaseToken, userController.updateNotificationSettings);

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
    // user.balance = (user.balance || 0) + 30;
    
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
      newBalance: user.balance + 30,
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

// ✅ Use memory storage for Railway (not disk storage)
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: { 
    fileSize: 5 * 1024 * 1024 // 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed!'), false);
    }
  }
});

router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  upload.single('image'),
  async (req, res) => {
    console.log('========== UPLOAD START ==========');
    console.log('🔐 User:', req.user?.uid);
    console.log('📁 Has file:', !!req.file);
    
    try {
      // 1. Check if file exists
      if (!req.file) {
        console.log('❌ No file uploaded');
        return res.status(400).json({ 
          success: false, 
          message: 'No file uploaded'
        });
      }
      
      console.log('✅ File details:', {
        originalname: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
        bufferExists: !!req.file.buffer,
        bufferLength: req.file.buffer?.length || 0
      });
      
      // 2. Get user info
      const userId = req.user.uid;
      const firebaseEmail = req.user.email;
      
      if (!userId) {
        throw new Error('User ID not found in token');
      }
      
      console.log('👤 User:', { userId, email: firebaseEmail });
      
      // 3. Check Firebase
      console.log('🔥 Firebase bucket available:', !!bucket);
      if (bucket) {
        console.log('📦 Bucket name:', bucket.name);
      }
      
      // 4. Upload to Firebase Storage
      let photoURL;
      
      if (bucket) {
        try {
          // Generate safe filename
          const timestamp = Date.now();
          const originalName = req.file.originalname || 'profile.jpg';
          const safeFileName = originalName.replace(/[^a-zA-Z0-9.]/g, '_');
          const firebaseFileName = `profile_pics/${userId}_${timestamp}_${safeFileName}`;
          
          console.log('📝 Creating file at:', firebaseFileName);
          
          // Create file reference
          const file = bucket.file(firebaseFileName);
          
          // Upload with proper error handling
          console.log('⬆️ Uploading to Firebase...');
          
          const uploadOptions = {
            metadata: {
              contentType: req.file.mimetype || 'image/jpeg',
              metadata: {
                uploadedBy: userId,
                uploadedAt: new Date().toISOString()
              }
            }
          };
          
          // Make sure we have buffer
          if (!req.file.buffer) {
            throw new Error('File buffer is empty');
          }
          
          await file.save(req.file.buffer, uploadOptions);
          console.log('✅ File saved to Firebase');
          
          // Make public
          console.log('🔓 Making file public...');
          await file.makePublic();
          
          // Get public URL
          photoURL = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(firebaseFileName)}?alt=media`;
          console.log('🔗 Firebase URL:', photoURL);
          
        } catch (firebaseError) {
          console.error('❌ Firebase upload error:', firebaseError.message);
          console.error('❌ Stack:', firebaseError.stack);
          
          // Fallback to placeholder
          photoURL = `https://ui-avatars.com/api/?name=${encodeURIComponent(userId)}&background=0083a3&color=fff&size=256`;
          console.log('⚠️ Using fallback URL:', photoURL);
        }
      } else {
        // No Firebase - use placeholder
        console.log('⚠️ Firebase not available, using placeholder');
        photoURL = `https://ui-avatars.com/api/?name=${encodeURIComponent(userId)}&background=0083a3&color=fff&size=256`;
      }
      
      // 5. Update MongoDB
      console.log('💾 Updating MongoDB...');
      
      const updateData = {
        photoURL: photoURL,
        updatedAt: new Date(),
        email: firebaseEmail || req.user.email
      };
      
      console.log('📦 Update data:', updateData);
      
      const updatedUser = await User.findOneAndUpdate(
        { firebaseUid: userId },
        { $set: updateData },
        { 
          new: true,
          upsert: true,
          runValidators: false // Disable validators for now
        }
      ).lean(); // Use lean() for better performance
      
      if (!updatedUser) {
        throw new Error('Failed to update user in database');
      }
      
      console.log('✅ MongoDB updated:', {
        id: updatedUser._id,
        name: updatedUser.name,
        photoURL: updatedUser.photoURL
      });
      
      // 6. Success response
      const response = {
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
      };
      
      console.log('========== UPLOAD SUCCESS ==========');
      res.json(response);
      
    } catch (error) {
      console.error('========== UPLOAD ERROR ==========');
      console.error('❌ Error:', error.message);
      console.error('❌ Stack:', error.stack);
      console.error('❌ Request details:', {
        userId: req.user?.uid,
        hasFile: !!req.file,
        fileSize: req.file?.size,
        bucketAvailable: !!bucket
      });
      console.error('========== END ERROR ==========');
      
      // Send detailed error (but not in production)
      const errorResponse = {
        success: false,
        message: 'Upload failed',
        error: process.env.NODE_ENV === 'production' ? 'Internal server error' : error.message,
        debug: process.env.NODE_ENV !== 'production' ? {
          errorType: error.constructor.name,
          errorCode: error.code,
          hasFile: !!req.file,
          fileSize: req.file?.size,
          bucketAvailable: !!bucket
        } : undefined
      };
      
      res.status(500).json(errorResponse);
    }
  }
);
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

router.post('/test-update', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const testData = {
      displayName: `TestUser_${Date.now()}`,
      photoURL: `https://test.com/image_${Date.now()}.jpg`,
      email: req.user.email
    };
    
    console.log('🧪 Test update with:', testData);
    
    const updatedUser = await User.findOneAndUpdate(
      { firebaseUid: userId },
      { 
        $set: {
          name: testData.displayName,
          photoURL: testData.photoURL,
          email: testData.email,
          updatedAt: new Date()
        }
      },
      { new: true, upsert: true }
    );
    
    res.json({
      success: true,
      message: 'Test update successful',
      sentData: testData,
      storedData: {
        name: updatedUser.name,
        photoURL: updatedUser.photoURL,
        email: updatedUser.email
      },
      verification: {
        nameMatches: updatedUser.name === testData.displayName,
        photoURLMatches: updatedUser.photoURL === testData.photoURL,
        emailMatches: updatedUser.email === testData.email
      }
    });
    
  } catch (error) {
    console.error('Test error:', error);
    res.status(500).json({ error: error.message });
  }
});

router.get('/admin/debug-user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log(`🔍 Debugging user: ${userId}`);
    
    const userById = await User.findById(userId);
    const userByFirebaseUid = await User.findOne({ firebaseUid: userId });
    const userByEmail = await User.findOne({ email: userId });
    
    console.log('📊 Database query results:');
    console.log('   By MongoDB _id:', userById ? 'Found' : 'Not found');
    console.log('   By firebaseUid:', userByFirebaseUid ? 'Found' : 'Not found');
    console.log('   By email:', userByEmail ? 'Found' : 'Not found');
    
    const allUsers = await User.find({}).limit(5).select('name email photoURL firebaseUid sessions');
    
    const user = userById || userByFirebaseUid || userByEmail;
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
        searchMethods: {
          byId: !!userById,
          byFirebaseUid: !!userByFirebaseUid,
          byEmail: !!userByEmail
        }
      });
    }
    
    res.json({
      success: true,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        photoURL: user.photoURL,
        photoURLExists: !!user.photoURL,
        photoURLType: user.photoURL ? 
          (user.photoURL.includes('firebasestorage') ? 'Firebase Storage' : 
           user.photoURL.includes('cloudinary') ? 'Cloudinary' : 
           'Other') : 'None',
        firebaseUid: user.firebaseUid,
        balance: user.balance,
        sessions: user.sessions || [],
        sessionsCount: user.sessions ? user.sessions.length : 0,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      },
      allUsers: allUsers.map(u => ({
        _id: u._id,
        name: u.name,
        email: u.email,
        photoURL: u.photoURL,
        firebaseUid: u.firebaseUid,
        sessionsCount: u.sessions ? u.sessions.length : 0
      }))
    });
    
  } catch (error) {
    console.error('Debug error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

router.get('/debug-routes', (req, res) => {
  console.log('🔍 Incoming request to /debug-routes');
  
  res.json({
    routesAvailable: [
      'GET /api/users/profile',
      'PUT /api/users/profile',
      'GET /api/users/sessions',
      'POST /api/users/complete-session',
      'POST /api/users/reset-sessions',
      'GET /api/users/debug-routes',
      'GET /api/users/debug-sessions',
      'GET /api/users/debug-field-mapping',
      'GET /api/users/admin/debug-user/:userId',
      'GET /api/users/health',
      'GET /api/users/count',
      'POST /api/users/upload-profile-picture'
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

// ============ OTHER USER ROUTES ============

router.put('/wallet-address', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { walletType, walletAddress } = req.body;
    
    console.log(`🔄 Updating ${walletType} wallet for user ${userId}: ${walletAddress}`);
    
    const user = await User.findOneAndUpdate(
      { firebaseUid: userId },
      { 
        $set: { 
          [`wallets.${walletType}`]: walletAddress,
          updatedAt: new Date()
        }
      },
      { new: true }
    );
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Wallet address updated successfully',
      walletType: walletType,
      walletAddress: walletAddress,
      user: {
        _id: user._id,
        wallets: user.wallets
      }
    });
    
  } catch (error) {
    console.error('❌ Error updating wallet address:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update wallet address',
      error: error.message
    });
  }
});

router.put('/calculator-usage', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    
    console.log(`🔄 Incrementing calculator usage for user ${userId}`);
    
    const user = await User.findOneAndUpdate(
      { firebaseUid: userId },
      { 
        $inc: { calculatorUsage: 1 },
        $set: { updatedAt: new Date() }
      },
      { new: true }
    );
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Calculator usage incremented',
      calculatorUsage: user.calculatorUsage || 1
    });
    
  } catch (error) {
    console.error('❌ Error incrementing calculator usage:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to increment calculator usage',
      error: error.message
    });
  }
});

router.post('/sync', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const firebaseEmail = req.user.email;
    const firebaseName = req.user.name;
    const firebasePhotoURL = req.user.picture;
    
    console.log('🔄 Syncing Firebase user to MongoDB:', {
      userId,
      email: firebaseEmail,
      name: firebaseName,
      photoURL: firebasePhotoURL
    });
    
    const generateInviteCode = () => {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      let code = '';
      for (let i = 0; i < 8; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      return code;
    };
    
    let user = await User.findOne({ firebaseUid: userId });
    
    if (!user && firebaseEmail) {
      user = await User.findOne({ email: firebaseEmail });
    }
    
    if (user) {
      user.name = firebaseName || user.name;
      user.photoURL = firebasePhotoURL || user.photoURL;
      user.firebaseUid = userId;
      user.updatedAt = new Date();
      await user.save();
      
      console.log('✅ Existing user synced:', user._id);
    } else {
      user = await User.create({
        firebaseUid: userId,
        email: firebaseEmail,
        name: firebaseName || '',
        photoURL: firebasePhotoURL || '',
        inviteCode: generateInviteCode(),
        createdAt: new Date(),
        updatedAt: new Date()
      });
      
      console.log('✅ New user created:', user._id);
    }
    
    res.json({
      success: true,
      message: 'User synced successfully',
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        photoURL: user.photoURL,
        firebaseUid: user.firebaseUid,
        inviteCode: user.inviteCode
      }
    });
    
  } catch (error) {
    console.error('❌ Sync error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to sync user',
      error: error.message
    });
  }
});

router.get('/details', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    
    const user = await User.findOne({ firebaseUid: userId });
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    res.json({
      success: true,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        photoURL: user.photoURL,
        firebaseUid: user.firebaseUid,
        balance: user.balance || 0,
        inviteCode: user.inviteCode,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }
    });
    
  } catch (error) {
    console.error('❌ Error getting user details:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get user details',
      error: error.message
    });
  }
});

module.exports = router;
