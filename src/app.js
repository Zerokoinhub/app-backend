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

// ============================================
// ADD ALL NEW ENDPOINTS HERE - BEFORE MOUNTING ROUTES
// ============================================

// Test deploy endpoint - to verify deployment
app.get('/api/users/test-deploy', (req, res) => {
  console.log('✅ TEST-DEPLOY endpoint hit!');
  res.json({ 
    success: true, 
    message: 'NEW CODE IS DEPLOYED!',
    timestamp: new Date().toISOString(),
    route: '/api/users/test-deploy'
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Ping
app.get('/ping', (req, res) => {
  res.json({ success: true, message: 'pong', timestamp: new Date().toISOString() });
});

// API test
app.get('/api/test', (req, res) => {
  res.json({ success: true, message: 'API is working!', timestamp: new Date().toISOString() });
});

// Sync Firebase user to MongoDB
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
    
    // ✅ CORRECT PATH for App Backend: models/user.js
    const User = require('../models/user');
    
    // Find user by firebaseUid or email
    let user = await User.findOne({ $or: [{ firebaseUid: uid }, { email: email }] });
    
    if (!user) {
      // Create new user
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
      // Update existing user
      if (!user.firebaseUid && uid) user.firebaseUid = uid;
      if (name) user.name = name;
      if (photoURL) user.photoURL = photoURL;
      user.lastLogin = new Date();
      await user.save();
      console.log(`✅ User updated: ${email}`);
    }
    
    res.json({
      success: true,
      message: 'User synced successfully',
      user: {
        id: user._id,
        firebaseUid: user.firebaseUid,
        email: user.email,
        name: user.name,
        balance: user.balance,
        isActive: user.isActive,
        role: user.role
      }
    });
    
  } catch (error) {
    console.error('❌ Error syncing user:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Error syncing user',
      error: error.message 
    });
  }
});

// Get all users
app.get('/api/users/all', async (req, res) => {
  try {
    // ✅ CORRECT PATH for App Backend: models/user.js
    const User = require('../models/user');
    const users = await User.find({})
      .select('firebaseUid email name balance isActive role createdAt')
      .sort({ createdAt: -1 });
    
    console.log(`📊 Total users in App Backend MongoDB: ${users.length}`);
    
    res.json({
      success: true,
      count: users.length,
      users: users
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Leaderboard - Top 10 users by balance
app.get('/api/users/leaderboard/top10', async (req, res) => {
  try {
    console.log('📊 Leaderboard endpoint hit');
    
    // ✅ CORRECT PATH for App Backend: models/user.js
    const User = require('../models/user');
    
    const topUsers = await User.find({ 
      isActive: true, 
      balance: { $gt: 0 } 
    })
      .select('name email balance photoURL country')
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
      profilePicture: user.photoURL || null,
      country: user.country || 'Unknown'
    }));
    
    const totalUsers = await User.countDocuments({ 
      isActive: true, 
      balance: { $gt: 0 } 
    });
    
    // Get average balance
    const avgResult = await User.aggregate([
      { $match: { isActive: true, balance: { $gt: 0 } } },
      { $group: { _id: null, avgBalance: { $avg: "$balance" } } }
    ]);
    const avgBalance = avgResult[0]?.avgBalance || 0;
    
    res.json({
      success: true,
      data: {
        topUsers: formattedUsers,
        stats: {
          totalUsersWithBalance: totalUsers,
          averageBalance: Math.round(avgBalance * 100) / 100,
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

// Get user rank
app.get('/api/users/leaderboard/rank/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    // ✅ CORRECT PATH for App Backend: models/user.js
    const User = require('../models/user');
    
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    const rank = await User.countDocuments({
      isActive: true,
      balance: { $gt: user.balance || 0 }
    }) + 1;
    
    const totalUsers = await User.countDocuments({ isActive: true, balance: { $gt: 0 } });
    
    res.json({
      success: true,
      data: {
        rank: rank,
        totalUsers: totalUsers,
        user: {
          id: user._id,
          name: user.name,
          balance: user.balance
        }
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// Debug routes
app.get('/debug-routes', (req, res) => {
  const routes = [];
  
  function extractRoutes(stack, basePath = '') {
    if (!stack) return;
    stack.forEach(layer => {
      if (layer.route) {
        routes.push({
          path: basePath + layer.route.path,
          methods: Object.keys(layer.route.methods).join(', ')
        });
      } else if (layer.name === 'router' && layer.handle && layer.handle.stack) {
        let routerPath = '';
        if (layer.regexp) {
          const match = layer.regexp.toString().match(/\/\^?(.*?)\\\/\?/);
          if (match) routerPath = '/' + match[1].replace(/\\/g, '');
        }
        extractRoutes(layer.handle.stack, basePath + routerPath);
      }
    });
  }
  
  if (app._router && app._router.stack) {
    extractRoutes(app._router.stack);
  }
  
  res.json({ 
    success: true, 
    totalRoutes: routes.length, 
    routes: routes.sort((a, b) => a.path.localeCompare(b.path))
  });
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

// ============================================
// CONNECT TO DATABASE AND START SERVICES
// ============================================

// Connect to MongoDB
connectDB()
  .then(() => {
    console.log('Connected to MongoDB successfully');

    // Start session notification service
    sessionNotificationService.start();
    console.log('🔔 Session notification service started');

    // Start automatic notification service
    autoNotificationService.start();
    console.log('📱 Automatic notification service started');
  })
  .catch((error) => {
    console.error('MongoDB connection error:', error);
  });

// ============================================
// ROOT ENDPOINT - UPDATED WITH VERSION
// ============================================

app.get('/', (req, res) => {
  res.json({ 
    message: 'Welcome to ZeroKoin API',
    version: '3.0.0',
    deployedAt: new Date().toISOString(),
    endpoints: {
      test: '/api/users/test-deploy',
      health: '/health',
      ping: '/ping',
      apiTest: '/api/test',
      sync: 'POST /api/users/sync',
      users: '/api/users/all',
      leaderboard: '/api/users/leaderboard/top10',
      debug: '/debug-routes'
    }
  });
});

// ============================================
// 404 HANDLER
// ============================================

app.use((req, res) => {
  console.log(`⚠️ 404 - Route not found: ${req.method} ${req.url}`);
  res.status(404).json({ 
    success: false, 
    message: `Cannot ${req.method} ${req.url}`,
    availableEndpoints: [
      'GET /',
      'GET /health',
      'GET /ping',
      'GET /api/test',
      'GET /api/users/test-deploy',
      'POST /api/users/sync',
      'GET /api/users/all',
      'GET /api/users/leaderboard/top10',
      'GET /debug-routes'
    ]
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
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// ============================================
// START SERVER
// ============================================

const server = app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log('========================================');
  console.log('📋 AVAILABLE ENDPOINTS:');
  console.log(`   GET  /                           - Root endpoint`);
  console.log(`   GET  /health                     - Health check`);
  console.log(`   GET  /ping                       - Ping test`);
  console.log(`   GET  /api/test                   - API test`);
  console.log(`   GET  /api/users/test-deploy      - Deploy test`);
  console.log(`   POST /api/users/sync             - Sync Firebase user`);
  console.log(`   GET  /api/users/all              - Get all users`);
  console.log(`   GET  /api/users/leaderboard/top10 - Leaderboard`);
  console.log(`   GET  /debug-routes               - List all routes`);
  console.log('========================================');
}).on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use. Please try a different port.`);
    process.exit(1);
  } else {
    console.error('Server error:', err);
  }
});
