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

router.get('/count', (req, res) => {
  res.json({ success: true, count: 10 });
});

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

// ✅ UPDATED: GET profile route
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
        balance: user.balance,
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

// ✅ UPDATED: PUT profile endpoint WITH MONGODB SAVING
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

// ✅ UPDATED: File upload with MongoDB save
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
        firebaseUid: user.firebaseUid
      },
      fieldMapping: {
        'Flutter sends': 'displayName',
        'MongoDB stores': 'name',
        'Node.js maps': 'displayName → name'
      },
      schemaCheck: {
        hasNameField: user.schema.path('name') !== undefined,
        hasDisplayNameField: user.schema.path('displayName') !== undefined,
        hasPhotoURLField: user.schema.path('photoURL') !== undefined
      }
    });
    
  } catch (error) {
    console.error('Debug error:', error);
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
// Add to your userRoutes.js
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
    const allUsers = await User.find({}).limit(5).select('name email photoURL firebaseUid');
    console.log('📋 First 5 users in database:');
    allUsers.forEach((user, index) => {
      console.log(`   ${index + 1}. ${user.name} (${user.email})`);
      console.log(`      photoURL: ${user.photoURL}`);
      console.log(`      firebaseUid: ${user.firebaseUid}`);
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
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      },
      allUsers: allUsers.map(u => ({
        _id: u._id,
        name: u.name,
        email: u.email,
        photoURL: u.photoURL,
        firebaseUid: u.firebaseUid
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
// Add this route to userRoutes.js
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
      'GET /api/users/debug-routes',
      'GET /api/users/admin/debug-user/:userId',
      'GET /api/users/health',
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
module.exports = router;
