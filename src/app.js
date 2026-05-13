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
const cron = require('node-cron');
const connectDB = require('./config/database');
const userRoutes = require('./routes/userRoutes');
const tokenRoutes = require('./routes/tokenRoutes');
const withdrawRoutes = require('./routes/withdrawRoutes');
const courseRoutes = require('./routes/courseRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const timeRoutes = require('./routes/timeRoutes');
const settingsRoutes = require('./routes/settings');
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

// ============================================
// ✅ COMPLETE CORS CONFIGURATION (FIXED)
// ============================================
app.use(cors({
  origin: true,  // Allow all origins (for production, specify your domains)
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
  exposedHeaders: ['Content-Length', 'X-Requested-With'],
  preflightContinue: false,
  optionsSuccessStatus: 204
}));

// Handle preflight requests explicitly
app.options('*', cors());

// Security and logging
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ============================================
// MODELS
// ============================================
const User = require('./models/User');
const NotificationService = require('./services/notificationService');
const notificationService = new NotificationService();

// ============================================
// ✅ AUTO BONUS CRON JOB (Runs every hour)
// ============================================
cron.schedule('0 * * * *', async () => {
  console.log('🕐 Checking for pending 24-hour bonuses...', new Date().toISOString());
  
  try {
    const now = new Date();
    
    // Find users whose 24 hours have passed and they haven't received auto bonus
    const users = await User.find({
      'bonusTimer.nextClaimTime': { $lte: now },
      'bonusTimer.autoBonusGiven': false,
      isActive: true
    });
    
    console.log(`📊 Found ${users.length} users eligible for auto bonus`);
    
    for (const user of users) {
      // Get current rank
      const topUsers = await User.find({})
        .sort({ balance: -1 })
        .limit(3)
        .lean();
      
      const userRank = topUsers.findIndex(u => u.firebaseUid === user.firebaseUid) + 1;
      
      if (userRank >= 1 && userRank <= 3) {
        let bonusAmount = 0;
        if (userRank === 1) bonusAmount = 20;
        else if (userRank === 2) bonusAmount = 10;
        else if (userRank === 3) bonusAmount = 5;
        
        // Add bonus automatically
        user.balance += bonusAmount;
        user.bonusTimer = {
          lastClaimTime: now,
          nextClaimTime: new Date(now.getTime() + 24 * 60 * 60 * 1000),
          autoBonusGiven: false,
          pendingBonus: false
        };
        user.lastBonusAmount = bonusAmount;
        user.lastBonusRank = userRank;
        
        await user.save();
        
        // Send push notification
        const rankEmoji = userRank === 1 ? '🥇' : userRank === 2 ? '🥈' : '🥉';
        const activeTokens = user.fcmTokens?.filter(t => t.isActive && t.token) || [];
        
        for (const tokenInfo of activeTokens) {
          await notificationService.sendNotificationToUser(
            tokenInfo.token,
            '🎉 Daily Bonus Added!',
            `${rankEmoji} Your ${bonusAmount} coins have been automatically added to your balance!`,
            { 
              type: 'auto_bonus', 
              amount: bonusAmount.toString(), 
              rank: userRank.toString(),
              newBalance: user.balance.toString()
            }
          );
        }
        
        console.log(`✅ Auto bonus: +${bonusAmount} coins to ${user.name || user.email} (Rank ${userRank})`);
      }
    }
  } catch (error) {
    console.error('❌ Auto bonus cron error:', error);
  }
}, {
  timezone: "Asia/Kolkata"
});

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
// CORS TEST ENDPOINT
// ============================================
app.get('/api/cors-test', (req, res) => {
  console.log('✅ CORS test from:', req.headers.origin);
  res.json({ 
    success: true, 
    message: 'CORS is working!',
    origin: req.headers.origin,
    timestamp: new Date().toISOString()
  });
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
    
    let user = await User.findOne({ $or: [{ firebaseUid: uid }, { email: email }] });
    
    if (!user) {
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
        bonusTimer: {
          lastClaimTime: null,
          nextClaimTime: null,
          autoBonusGiven: false,
          pendingBonus: false
        },
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
app.use('/api/settings', settingsRoutes);

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
  console.log(`\n🚀 Server is running on port ${PORT}`);
  console.log('========================================');
  console.log('📋 AVAILABLE ENDPOINTS:');
  console.log(`   GET  /                           - Root`);
  console.log(`   GET  /health                     - Health`);
  console.log(`   GET  /ping                       - Ping`);
  console.log(`   GET  /api/users/test-deploy      - Test`);
  console.log(`   GET  /api/cors-test              - CORS Test`);
  console.log(`   POST /api/users/sync             - Sync`);
  console.log(`   GET  /api/users/all              - All users`);
  console.log(`   GET  /api/users/leaderboard/top10 - Leaderboard`);
  console.log(`   POST /api/users/upload-screenshots - Upload Screenshots`);
  console.log(`   GET  /api/settings               - Get settings`);
  console.log(`   PUT  /api/settings               - Update settings`);
  console.log('========================================');
  console.log('✅ CORS enabled for all origins');
  console.log('✅ Auto Bonus Cron Job: Every hour');
  console.log('🌐 Allowed Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH');
  console.log('========================================\n');
}).on('error', (err) => {
  console.error('Server error:', err);
  process.exit(1);
});
