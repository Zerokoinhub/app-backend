const express = require('express');
const router = express.Router();
const multer = require('multer');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');
const User = require('../models/User'); // Make sure to import User model

console.log('✅ userRoutes.js loading with ALL routes');

// ============ PUBLIC ROUTES ============
router.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    message: 'Backend is alive' 
  });
});

// Count total users in database
router.get('/count', async (req, res) => {
  try {
    console.log('🔢 /api/users/count endpoint called');
    
    // Count ALL users in the database
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

// ============ SESSION ROUTES ============

// ✅ FIXED: GET user sessions - Now creates sessions if they don't exist
router.get('/sessions', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const firebaseEmail = req.user.email;
    
    console.log('📥 GET /sessions for:', {
      userId,
      email: firebaseEmail
    });
    
    // Try to find user
    let user = await User.findOne({ firebaseUid: userId });
    
    // If not found, try by email
    if (!user && firebaseEmail) {
      user = await User.findOne({ email: firebaseEmail });
      
      // If found by email but firebaseUid is missing, update it
      if (user && !user.firebaseUid) {
        user.firebaseUid = userId;
        await user.save();
        console.log('✅ Updated firebaseUid for existing user');
      }
    }
    
    // If still not found, create new user with sessions
    if (!user) {
      console.log('🆕 Creating new user with sessions for:', userId);
      
      // Generate unique invite code
      const generateInviteCode = () => {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        let code = '';
        for (let i = 0; i < 8; i++) {
          code += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return code;
      };
      
      // Get current time
      const now = new Date();
      
      // Create 4 sessions with proper timing
      const sessions = [
        {
          sessionNumber: 1,
          unlockedAt: now,
          completedAt: null,
          isLocked: false,
          nextUnlockAt: null,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 2,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          nextUnlockAt: new Date(now.getTime() + 6 * 60 * 60 * 1000), // 6 hours from now
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 3,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          nextUnlockAt: new Date(now.getTime() + 12 * 60 * 60 * 1000), // 12 hours from now
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 4,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          nextUnlockAt: new Date(now.getTime() + 18 * 60 * 60 * 1000), // 18 hours from now
          createdAt: now,
          lastUpdated: now
        }
      ];
      
      user = await User.create({
        firebaseUid: userId,
        email: firebaseEmail,
        name: req.user.name || '', // Use Firebase name if available
        photoURL: req.user.picture || '', // Use Firebase photo if available
        inviteCode: generateInviteCode(),
        sessions: sessions, // Store sessions in user document
        createdAt: now,
        updatedAt: now
      });
      
      console.log('✅ New user created with sessions:', user._id);
      
      // Return the newly created sessions
      return res.json({ 
        success: true, 
        sessions: sessions,
        message: 'New user sessions created',
        user: userId
      });
    }
    
    // If user exists but has no sessions, create them
    if (!user.sessions || user.sessions.length === 0) {
      console.log('🔄 Creating sessions for existing user:', user._id);
      
      const now = new Date();
      
      // Create fresh sessions
      const sessions = [
        {
          sessionNumber: 1,
          unlockedAt: now,
          completedAt: null,
          isLocked: false,
          nextUnlockAt: null,
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 2,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          nextUnlockAt: new Date(now.getTime() + 6 * 60 * 60 * 1000),
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 3,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          nextUnlockAt: new Date(now.getTime() + 12 * 60 * 60 * 1000),
          createdAt: now,
          lastUpdated: now
        },
        {
          sessionNumber: 4,
          unlockedAt: null,
          completedAt: null,
          isLocked: true,
          nextUnlockAt: new Date(now.getTime() + 18 * 60 * 60 * 1000),
          createdAt: now,
          lastUpdated: now
        }
      ];
      
      // Update user with sessions
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
    
    // User has sessions, return them
    console.log('✅ Returning existing sessions for user:', user._id);
    console.log('   Session count:', user.sessions.length);
    
    // Update session lock status based on current time
    const now = new Date();
    let updatedSessions = user.sessions.map(session => {
      const sessionCopy = { ...session };
      
      // Convert to Date objects if they're strings
      if (sessionCopy.nextUnlockAt && typeof sessionCopy.nextUnlockAt === 'string') {
        sessionCopy.nextUnlockAt = new Date(sessionCopy.nextUnlockAt);
      }
      
      // If session is locked and nextUnlockAt has passed, unlock it
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
    
    // Save updated sessions if any changed
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

// ✅ ADDED: Complete a session
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
    
    // Find user
    const user = await User.findOne({ firebaseUid: userId });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Check if user has sessions
    if (!user.sessions || user.sessions.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No sessions found for user'
      });
    }
    
    // Find the session
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
    
    // Check if session is already completed
    if (session.completedAt) {
      return res.json({
        success: true,
        message: `Session ${sessionNumber} was already completed`,
        session: session,
        sessionsReset: false
      });
    }
    
    // Check if session is locked
    if (session.isLocked) {
      return res.status(400).json({
        success: false,
        message: `Session ${sessionNumber} is locked`,
        nextUnlockAt: session.nextUnlockAt
      });
    }
    
    // Mark session as completed
    user.sessions[sessionIndex].completedAt = now;
    user.sessions[sessionIndex].lastUpdated = now;
    
    // Update user balance (add 30 coins)
    user.balance = (user.balance || 0) + 30;
    
    // Check if this was session 4 (completes the cycle)
    let sessionsReset = false;
    
    if (sessionNumber === 4) {
      console.log('🔄 Session 4 completed! Resetting all sessions...');
      
      // Reset all sessions after session 4
      user.sessions = user.sessions.map((s, index) => {
        const resetTime = new Date(now.getTime() + (index * 6 * 60 * 60 * 1000));
        
        return {
          sessionNumber: index + 1,
          unlockedAt: index === 0 ? resetTime : null,
          completedAt: null,
          isLocked: index > 0,
          nextUnlockAt: index > 0 ? resetTime : null,
          createdAt: s.createdAt || now,
          lastUpdated: now
        };
      });
      
      sessionsReset = true;
      user.lastSessionCycleCompletedAt = now;
    } else if (sessionNumber < 4) {
      // Unlock the next session after 6 hours
      const nextSessionIndex = sessionIndex + 1;
      if (nextSessionIndex < user.sessions.length) {
        const unlockTime = new Date(now.getTime() + 6 * 60 * 60 * 1000);
        user.sessions[nextSessionIndex].isLocked = false;
        user.sessions[nextSessionIndex].unlockedAt = now;
        user.sessions[nextSessionIndex].nextUnlockAt = null;
        user.sessions[nextSessionIndex].lastUpdated = now;
        
        console.log(`🔓 Session ${nextSessionIndex + 1} unlocked`);
      }
    }
    
    // Update last session completion time
    user.lastSessionCompletedAt = now;
    user.updatedAt = now;
    
    await user.save();
    
    console.log('✅ Session completed successfully');
    console.log('   New balance:', user.balance);
    console.log('   Sessions reset:', sessionsReset);
    
    res.json({
      success: true,
      message: `Session ${sessionNumber} completed successfully`,
      balanceAdded: 30,
      newBalance: user.balance,
      sessions: user.sessions,
      sessionsReset: sessionsReset,
      nextSessionAvailable: sessionNumber < 4 ? `Session ${sessionNumber + 1}` : null
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

// ✅ ADDED: Reset sessions (for testing/debugging)
router.post('/reset-sessions', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const now = new Date();
    
    console.log('🔄 Resetting sessions for user:', userId);
    
    // Find user
    const user = await User.findOne({ firebaseUid: userId });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Create fresh sessions
    const sessions = [
      {
        sessionNumber: 1,
        unlockedAt: now,
        completedAt: null,
        isLocked: false,
        nextUnlockAt: null,
        createdAt: now,
        lastUpdated: now
      },
      {
        sessionNumber: 2,
        unlockedAt: null,
        completedAt: null,
        isLocked: true,
        nextUnlockAt: new Date(now.getTime() + 6 * 60 * 60 * 1000),
        createdAt: now,
        lastUpdated: now
      },
      {
        sessionNumber: 3,
        unlockedAt: null,
        completedAt: null,
        isLocked: true,
        nextUnlockAt: new Date(now.getTime() + 12 * 60 * 60 * 1000),
        createdAt: now,
        lastUpdated: now
      },
      {
        sessionNumber: 4,
        unlockedAt: null,
        completedAt: null,
        isLocked: true,
        nextUnlockAt: new Date(now.getTime() + 18 * 60 * 60 * 1000),
        createdAt: now,
        lastUpdated: now
      }
    ];
    
    // Update user
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

// ✅ GET profile route
router.get('/profile', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const firebaseEmail = req.user.email;
    
    console.log('📥 GET /profile for:', {
      userId,
      email: firebaseEmail
    });
    
    // Try to find user by firebaseUid first
    let user = await User.findOne({ firebaseUid: userId });
    
    // If not found, try by email
    if (!user && firebaseEmail) {
      user = await User.findOne({ email: firebaseEmail });
      
      // If found by email but firebaseUid is missing, update it
      if (user && !user.firebaseUid) {
        user.firebaseUid = userId;
        await user.save();
        console.log('✅ Updated firebaseUid for existing user');
      }
    }
    
    // If still not found, create new user
    if (!user) {
      console.log('🆕 Creating new user for:', userId);
      
      // Generate unique invite code
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
        name: req.user.name || '', // Use Firebase name if available
        photoURL: req.user.picture || '', // Use Firebase photo if available
        inviteCode: generateInviteCode(),
        createdAt: new Date(),
        updatedAt: new Date()
      });
      
      console.log('✅ New user created:', user._id);
    }
    
    // Return user data
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

// ✅ PUT profile endpoint WITH MONGODB SAVING
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
    
    // Extract data from request
    const { displayName, photoURL, email } = req.body;
    
    console.log(`🔄 Updating user ${userId} with:`, {
      displayName,
      photoURL,
      email: email || firebaseEmail
    });
    
    // Prepare update data - MAP displayName → name
    const updateData = {
      updatedAt: new Date()
    };
    
    // ✅ CRITICAL: Map Flutter's displayName to MongoDB's name field
    if (displayName !== undefined && displayName !== null && displayName !== '') {
      updateData.name = displayName;
      console.log(`   Mapping: displayName "${displayName}" → name "${displayName}"`);
    }
    
    // ✅ photoURL already matches
    if (photoURL !== undefined && photoURL !== null && photoURL !== '') {
      updateData.photoURL = photoURL;
      console.log(`   Setting photoURL: ${photoURL}`);
    }
    
    // ✅ email (use provided or Firebase email)
    if (email !== undefined && email !== null && email !== '') {
      updateData.email = email;
      console.log(`   Setting email: ${email}`);
    } else if (firebaseEmail) {
      updateData.email = firebaseEmail;
      console.log(`   Using Firebase email: ${firebaseEmail}`);
    }
    
    // Ensure firebaseUid is set
    updateData.firebaseUid = userId;
    
    console.log('📦 Final update data for MongoDB:', updateData);
    
    // Find and update user
    const updatedUser = await User.findOneAndUpdate(
      { firebaseUid: userId }, // Find by Firebase UID
      { 
        $set: updateData
      },
      { 
        new: true, // Return updated document
        upsert: true, // Create if doesn't exist
        runValidators: true
      }
    );
    
    console.log('✅ MongoDB update successful!');
    console.log('   User ID:', updatedUser._id);
    console.log('   Name:', updatedUser.name);
    console.log('   PhotoURL:', updatedUser.photoURL);
    console.log('   Email:', updatedUser.email);
    
    // Return success response
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
    
    // Check for specific MongoDB errors
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

// ============ FILE UPLOAD ROUTES ============

// ✅ File upload with MongoDB save
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB
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
      console.log('   File info:', {
        name: req.file.originalname,
        size: req.file.size,
        type: req.file.mimetype
      });
      
      // In production, upload to S3/Cloudinary/Firebase Storage
      // For now, generate a placeholder URL or save filename
      const fileName = `${userId}_${Date.now()}_${req.file.originalname}`;
      const photoURL = `https://storage.googleapis.com/your-bucket/profile_pics/${fileName}`;
      
      // Update user in MongoDB
      const updatedUser = await User.findOneAndUpdate(
        { firebaseUid: userId },
        { 
          $set: { 
            photoURL: photoURL,
            updatedAt: new Date(),
            email: firebaseEmail // Ensure email is set
          }
        },
        { 
          new: true,
          upsert: true 
        }
      );
      
      console.log('✅ Profile picture saved to MongoDB');
      console.log('   PhotoURL:', updatedUser.photoURL);
      
      // Return response
      res.json({ 
        success: true, 
        message: 'Profile picture uploaded successfully',
        photoURL: photoURL, // Send both photoURL and photoUrl for compatibility
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

// ============ DEBUG & TEST ROUTES ============

// ✅ ADD: Debug route to check field mapping
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
    
    // Show all fields
    const userObj = user.toObject();
    
    res.json({
      exists: true,
      mongoDBFields: Object.keys(userObj),
      currentData: {
        _id: user._id,
        name: user.name,
        displayName: user.displayName, // Will be undefined
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

// ✅ ADD: Debug route for sessions
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

// ✅ ADD: Test route to verify update works
router.post('/test-update', verifyFirebaseToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const testData = {
      displayName: `TestUser_${Date.now()}`,
      photoURL: `https://test.com/image_${Date.now()}.jpg`,
      email: req.user.email
    };
    
    console.log('🧪 Test update with:', testData);
    
    // Update user
    const updatedUser = await User.findOneAndUpdate(
      { firebaseUid: userId },
      { 
        $set: {
          name: testData.displayName, // Map displayName → name
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

// ✅ ADD: Admin debug route
router.get('/admin/debug-user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log(`🔍 Debugging user: ${userId}`);
    
    // Try different ways to find the user
    const userById = await User.findById(userId);
    const userByFirebaseUid = await User.findOne({ firebaseUid: userId });
    const userByEmail = await User.findOne({ email: userId });
    
    console.log('📊 Database query results:');
    console.log('   By MongoDB _id:', userById ? 'Found' : 'Not found');
    console.log('   By firebaseUid:', userByFirebaseUid ? 'Found' : 'Not found');
    console.log('   By email:', userByEmail ? 'Found' : 'Not found');
    
    // Get all users to see structure
    const allUsers = await User.find({}).limit(5).select('name email photoURL firebaseUid sessions');
    console.log('📋 First 5 users in database:');
    allUsers.forEach((user, index) => {
      console.log(`   ${index + 1}. ${user.name} (${user.email})`);
      console.log(`      photoURL: ${user.photoURL}`);
      console.log(`      firebaseUid: ${user.firebaseUid}`);
      console.log(`      sessions: ${user.sessions ? user.sessions.length : 0}`);
    });
    
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

// ✅ ADD: Debug routes endpoint
router.get('/debug-routes', (req, res) => {
  console.log('🔍 Incoming request to /debug-routes');
  console.log('   Headers:', req.headers);
  console.log('   Query:', req.query);
  console.log('   Path:', req.path);
  console.log('   Original URL:', req.originalUrl);
  
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

// Update wallet address
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

// Increment calculator usage
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

// Sync Firebase user to MongoDB
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
    
    // Generate unique invite code
    const generateInviteCode = () => {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      let code = '';
      for (let i = 0; i < 8; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      return code;
    };
    
    // Check if user already exists
    let user = await User.findOne({ firebaseUid: userId });
    
    if (!user && firebaseEmail) {
      user = await User.findOne({ email: firebaseEmail });
    }
    
    if (user) {
      // Update existing user
      user.name = firebaseName || user.name;
      user.photoURL = firebasePhotoURL || user.photoURL;
      user.firebaseUid = userId; // Ensure firebaseUid is set
      user.updatedAt = new Date();
      await user.save();
      
      console.log('✅ Existing user synced:', user._id);
    } else {
      // Create new user
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

// Get user details
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
