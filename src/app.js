// Load environment variables first, before any other imports
const path = require('path');
const envPath = path.join(__dirname, '../.env');
console.log('🔧 Loading .env from:', envPath);
console.log('🔧 __dirname:', __dirname);
require('dotenv').config({ path: envPath });

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const connectDB = require('./config/database');
const userRoutes = require('./routes/userRoutes');
const tokenRoutes = require('./routes/tokenRoutes');
const withdrawRoutes = require('./routes/withdrawRoutes');
const courseRoutes = require('./routes/courseRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const timeRoutes = require('./routes/timeRoutes');
const settingsRoutes = require('./routes/settings'); // ✅ ADD THIS LINE
const sessionNotificationService = require('./services/sessionNotificationService');
const autoNotificationService = require('./services/autoNotificationService');
const admin = require('firebase-admin');

const PORT = process.env.PORT || 8080;

// ========== 🔥 FIREBASE ADMIN INITIALIZATION ==========
console.log("🔥 Initializing Firebase Admin...");
try {
  if (!admin.apps.length) {
    const serviceAccount = {
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    };
    
    console.log("🔥 Firebase Project ID:", serviceAccount.projectId ? "✓" : "✗");
    console.log("🔥 Firebase Client Email:", serviceAccount.clientEmail ? "✓" : "✗");
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET || "zerokoin-705c5.firebasestorage.app",
    });
    
    console.log("✅ Firebase Admin initialized");
  }
} catch (error) {
  console.error("❌ Firebase Admin initialization failed:", error.message);
}
// ======================================================

const app = express();
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/api/settings', settingsRoutes);
// ✅ CORRECT PATH FOR APP BACKEND (Flutter app)
const User = require('./models/User');  // Note: capital U, in src/models/User.js

// ============================================
// TEST ENDPOINTS
// ============================================

app.get('/api/users/test-deploy', (req, res) => {
  console.log('✅ TEST-DEPLOY endpoint hit!');
  res.json({ 
    success: true, 
    message: 'NEW CODE IS DEPLOYED!',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

app.get('/ping', (req, res) => {
  res.json({ success: true, message: 'pong' });
});

app.get('/api/test', (req, res) => {
  res.json({ success: true, message: 'API is working!' });
});

// ============================================
// SYNC ENDPOINT
// ============================================
app.post('/api/users/sync', async (req, res) => {
  console.log('🔄 SYNC endpoint hit!');
  console.log('Body:', req.body);
  
  try {
    const { uid, email, name, photoURL } = req.body;
    
    if (!uid || !email) {
      return res.status(400).json({ 
        success: false, 
        message: 'Missing required fields: uid and email are required' 
      });
    }
    
    console.log(`🔄 Syncing user: ${email} (UID: ${uid})`);
    
    // Find user by firebaseUid or email
    let user = await User.findOne({ $or: [{ firebaseUid: uid }, { email: email }] });
    
    if (!user) {
      const username = name ? name.toLowerCase().replace(/\s/g, '') : email.split('@')[0];
      const crypto = require('crypto');
      const inviteCode = crypto.randomBytes(16).toString('hex');
      
      user = new User({
        firebaseUid: uid,
        email: email,
        name: name || email.split('@')[0],
        photoURL: photoURL || '',
        balance: 0,
        isActive: true,
        role: 'user',
        inviteCode: inviteCode,
        lastLogin: new Date(),
        sessions: [
          { sessionNumber: 1, isLocked: false },
          { sessionNumber: 2, isLocked: true },
          { sessionNumber: 3, isLocked: true },
          { sessionNumber: 4, isLocked: true }
        ]
      });
      
      await user.save();
      console.log(`✅ New user created: ${email}`);
    } else {
      if (!user.firebaseUid && uid) user.firebaseUid = uid;
      if (name) user.name = name;
      if (photoURL) user.photoURL = photoURL;
      user.lastLogin = new Date();
      await user.save();
      console.log(`✅ User updated: ${email}`);
    }
    
    res.json({ success: true, user: { id: user._id, email: user.email, name: user.name } });
  } catch (error) {
    console.error('❌ Sync error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================
// GET ALL USERS
// ============================================
app.get('/api/users/all', async (req, res) => {
  try {
    const users = await User.find({}).select('firebaseUid email name balance isActive');
    console.log(`📊 Total users in App Backend: ${users.length}`);
    res.json({ success: true, count: users.length, users });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================
// LEADERBOARD
// ============================================
app.get('/api/users/leaderboard/top10', async (req, res) => {
  try {
    console.log('📊 Leaderboard endpoint hit');
    
    const topUsers = await User.find({ 
      isActive: true, 
      balance: { $gt: 0 } 
    })
      .select('name email balance photoURL')
      .sort({ balance: -1 })
      .limit(10)
      .lean();
    
    console.log(`✅ Found ${topUsers.length} users with balances`);
    
    const formattedUsers = topUsers.map((user, index) => ({
      rank: index + 1,
      id: user._id,
      name: user.name || 'Anonymous User',
      email: user.email,
      balance: user.balance || 0,
      profilePicture: user.photoURL || null
    }));
    
    const totalUsers = await User.countDocuments({ 
      isActive: true, 
      balance: { $gt: 0 } 
    });
    
    res.json({
      success: true,
      data: {
        topUsers: formattedUsers,
        stats: {
          totalUsersWithBalance: totalUsers,
          highestBalance: formattedUsers[0]?.balance || 0,
          lastUpdated: new Date().toISOString()
        }
      }
    });
  } catch (error) {
    console.error('❌ Leaderboard error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error fetching leaderboard',
      error: error.message 
    });
  }
});

// ============================================
// MOUNT EXISTING ROUTES
// ============================================
app.use('/api/users', userRoutes);
app.use('/api/token', tokenRoutes);
app.use("/api/withdraw", withdrawRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/time', timeRoutes);
app.use('/api/settings', settingsRoutes); // ✅ ADD THIS LINE - Mount settings routes

// ============================================
// CONNECT TO DATABASE
// ============================================
connectDB()
  .then(() => {
    console.log('Connected to MongoDB successfully');
    sessionNotificationService.start();
    autoNotificationService.start();
  })
  .catch((error) => {
    console.error('MongoDB connection error:', error);
  });

// ============================================
// ROOT ENDPOINT
// ============================================
app.get('/', (req, res) => {
  res.json({ 
    message: 'Welcome to ZeroKoin API',
    version: '3.0.0',
    deployedAt: new Date().toISOString()
  });
});

// ============================================
// 404 HANDLER
// ============================================
app.use((req, res) => {
  res.status(404).json({ 
    success: false, 
    message: `Cannot ${req.method} ${req.url}`
  });
});

// ============================================
// ERROR HANDLER
// ============================================
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.stack);
  res.status(500).json({ 
    success: false,
    message: 'Something went wrong!',
    error: err.message 
  });
});

// ============================================
// START SERVER
// ============================================
const server = app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log('========================================');
  console.log('📋 AVAILABLE ENDPOINTS:');
  console.log(`   GET  /                           - Root`);
  console.log(`   GET  /health                     - Health`);
  console.log(`   GET  /api/users/test-deploy      - Test`);
  console.log(`   POST /api/users/sync             - Sync`);
  console.log(`   GET  /api/users/all              - All users`);
  console.log(`   GET  /api/users/leaderboard/top10 - Leaderboard`);
  console.log(`   GET  /api/settings               - Get settings`); // ✅ ADD THIS
  console.log(`   PUT  /api/settings               - Update settings`); // ✅ ADD THIS
  console.log('========================================');
}).on('error', (err) => {
  console.error('Server error:', err);
  process.exit(1);
});
