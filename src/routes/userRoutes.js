const express = require('express');
const router = express.Router();
const multer = require('multer');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');
const { admin } = require('../config/firebase');
const User = require('../models/User');
const userController = require('../controllers/userController');
const { getUserSessions, unlockNextSession, completeSession } = require('../controllers/userController');

// ✅ IMPORT MIDDLEWARES (FIXED - YEH ADD KIYA)
const { authMiddleware, adminMiddleware } = require('../middleware/auth');

// ✅ IMPORT CLOUDINARY CONFIG
const { uploadScreenshots } = require('../config/cloudinary');

// ============================================
// ✅ MULTER CONFIGURATION FOR PROFILE PICTURE
// ============================================
const storage = multer.memoryStorage();
const upload = multer({ 
  storage: storage,
  limits: { 
    fileSize: 10 * 1024 * 1024,
    files: 1
  },
  fileFilter: (req, file, cb) => {
    if (!file.originalname.match(/\.(jpg|jpeg|png|gif|webp)$/)) {
      return cb(new Error('Only image files are allowed!'), false);
    }
    cb(null, true);
  }
});

// ============================================
// ✅ RANK BONUS TRIGGER ROUTE
// ============================================
router.post('/trigger-rank-bonus', verifyFirebaseToken, userController.triggerRankBonusNotification);

// ============================================
// ✅ FORCE PENDING BONUS ROUTE
// ============================================
// Add this route in userRoutes.js
router.post('/sync-rank', verifyFirebaseToken, userController.syncUserRank);
router.post('/force-pending-bonus', verifyFirebaseToken, async (req, res) => {
  try {
    const { uid } = req.user;
    const user = await User.findOne({ firebaseUid: uid });
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // Force create pending bonus
    user.pendingBonus = {
      amount: 20,
      rank: 1,
      claimed: false,
      earnedAt: new Date()
    };
    
    await user.save();
    
    console.log(`✅ Force created pending bonus for ${user.email}`);
    
    res.json({ 
      success: true, 
      message: 'Pending bonus created',
      pendingBonus: user.pendingBonus
    });
  } catch (error) {
    console.error('Force pending bonus error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================
// ✅ TEST BONUS NOTIFICATION
// ============================================
router.post('/test-bonus-notification', verifyFirebaseToken, async (req, res) => {
  try {
    const NotificationService = require('../services/notificationService');
    const notificationService = new NotificationService();
    
    const user = await User.findOne({ firebaseUid: req.user.uid });
    
    if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
      return res.status(400).json({ 
        success: false, 
        message: 'No FCM tokens found for user' 
      });
    }
    
    const activeToken = user.fcmTokens.find(t => t.isActive);
    if (!activeToken) {
      return res.status(400).json({ 
        success: false, 
        message: 'No active FCM token found' 
      });
    }
    
    const result = await notificationService.sendDailyBonusNotification(
      activeToken.token,
      1,
      20,
      user.name || 'Miner'
    );
    
    res.json({
      success: result.success,
      message: result.success ? 'Test notification sent!' : 'Failed to send',
      result: result
    });
    
  } catch (error) {
    console.error('Test notification error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================
// ✅ PROFILE PICTURE UPLOAD
// ============================================
router.post('/upload-profile-picture', 
  verifyFirebaseToken,
  (req, res, next) => {
    console.log('📤 Upload request received');
    const imageUpload = upload.single('image');
    
    imageUpload(req, res, (err) => {
      if (!err && req.file) {
        console.log('✅ File received via field: image');
        return next();
      }
      
      console.log('❌ No file uploaded');
      return res.status(400).json({ 
        success: false, 
        message: 'No file uploaded. Expected field: image' 
      });
    });
  },
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ success: false, message: 'No file uploaded' });
      }
      
      const userId = req.user.uid;
      const userEmail = req.user.email || '';
      
      const fileExtension = req.file.originalname.split('.').pop() || 'jpg';
      const fileName = `${userId}_${Date.now()}.${fileExtension}`;
      const filePath = `profile_pics/${fileName}`;
      
      const bucket = admin.storage().bucket();
      const file = bucket.file(filePath);
      const downloadToken = require('crypto').randomBytes(16).toString('hex');
      
      await file.save(req.file.buffer, {
        metadata: {
          contentType: req.file.mimetype,
          metadata: {
            firebaseStorageDownloadTokens: downloadToken,
            uploadedBy: userId,
            uploadedAt: new Date().toISOString()
          }
        }
      });
      
      await file.makePublic();
      
      const photoURL = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(filePath)}?alt=media&token=${downloadToken}`;
      
      let user = await User.findOne({ firebaseUid: userId });
      
      if (!user) {
        user = new User({
          firebaseUid: userId,
          email: userEmail,
          name: req.user.name || '',
          photoURL: photoURL,
          createdAt: new Date(),
          updatedAt: new Date()
        });
      } else {
        user.photoURL = photoURL;
        user.updatedAt = new Date();
      }
      
      await user.save();
      
      res.status(200).json({ 
        success: true, 
        message: 'Profile picture uploaded successfully',
        photoURL: photoURL
      });
      
    } catch (error) {
      console.error('Upload error:', error);
      res.status(500).json({ success: false, message: error.message });
    }
  }
);

// ============================================
// ✅ BONUS CLAIM ROUTE
// ============================================
router.post('/bonus/claim', verifyFirebaseToken, async (req, res) => {
  try {
    const { uid } = req.user;
    console.log(`🔵 Claim bonus for UID: ${uid}`);
    
    const user = await User.findOne({ firebaseUid: uid });
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    if (!user.pendingBonus || user.pendingBonus.claimed) {
      return res.status(400).json({ 
        success: false, 
        message: 'No pending bonus to claim' 
      });
    }
    
    const bonusAmount = user.pendingBonus.amount;
    const rank = user.pendingBonus.rank;
    
    const updatedUser = await User.findOneAndUpdate(
      { firebaseUid: uid },
      {
        $inc: { balance: bonusAmount },
        $set: {
          'pendingBonus.claimed': true,
          'pendingBonus.claimedAt': new Date(),
          lastBonusClaimTime: new Date(),
          lastBonusRank: rank,
          lastBonusAmount: bonusAmount
        }
      },
      { new: true }
    );
    
    console.log(`✅ Claim successful! +${bonusAmount} coins, new balance: ${updatedUser.balance}`);
    
    res.json({
      success: true,
      message: `You claimed ${bonusAmount} coins!`,
      data: {
        bonusAmount: bonusAmount,
        rank: rank,
        oldBalance: updatedUser.balance - bonusAmount,
        newBalance: updatedUser.balance
      }
    });
  } catch (error) {
    console.error('Error claiming bonus:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/bonus/cancel', verifyFirebaseToken, userController.cancelBonusFromNotification);

// ============================================
// ✅ SCREENSHOT UPLOAD ROUTE
// ============================================
router.post('/upload-screenshots', 
  verifyFirebaseToken, 
  uploadScreenshots.array('screenshots', 10), 
  userController.uploadScreenshots
);

// ============================================
// ✅ DEBUG ROUTE
// ============================================
router.get('/debug/direct-pending', verifyFirebaseToken, async (req, res) => {
  try {
    const { uid } = req.user;
    
    const result = await User.aggregate([
      { $match: { firebaseUid: uid } },
      { $project: { 
          email: 1, 
          balance: 1,
          pendingBonus: 1,
          hasPendingBonus: { $cond: [{ $ifNull: ['$pendingBonus', false] }, true, false] }
        } 
      }
    ]);
    
    res.json({ success: true, data: result[0] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============================================
// ✅ BONUS ROUTES
// ============================================
router.get('/bonus/status', verifyFirebaseToken, userController.checkBonusStatus);
router.post('/daily-bonus', verifyFirebaseToken, userController.claimDailyBonus);

// ============================================
// ✅ LEADERBOARD ROUTES
// ============================================
router.get('/leaderboard/complete', userController.getCompleteLeaderboard);

// ============================================
// ✅ AUTH & USER ROUTES
// ============================================
router.post('/register', userController.registerUser);
router.get('/invite/:inviteCode', userController.getInviteDetails);
router.post('/referral', userController.processReferral);
router.post('/sync', verifyFirebaseToken, userController.syncFirebaseUser);
router.get('/profile', verifyFirebaseToken, userController.getUserProfile);
router.put('/profile', verifyFirebaseToken, userController.updateUserProfile);
router.get('/user-details', verifyFirebaseToken, userController.getUserDetails);

// ✅ ADMIN ROUTES (FIXED - USING authMiddleware and adminMiddleware)
router.put('/admin/update-user-balance', verifyFirebaseToken, 
  userController.updateUserBalanceByAdmin
);

// ============================================
// ✅ SESSION ROUTES
// ============================================
router.get('/sessions', verifyFirebaseToken, getUserSessions);
router.post('/unlock', verifyFirebaseToken, unlockNextSession);
router.post('/complete-session', verifyFirebaseToken, completeSession);
router.post('/reset-sessions', verifyFirebaseToken, userController.resetUserSessions);

// ============================================
// ✅ WALLET & BALANCE ROUTES
// ============================================
router.put('/wallet-address', verifyFirebaseToken, userController.updateWalletAddress);
router.put('/update-balance', verifyFirebaseToken, userController.updateUserBalance);
router.put('/calculator-usage', verifyFirebaseToken, userController.incrementCalculatorUsage);

// ============================================
// ✅ NOTIFICATION ROUTES
// ============================================
router.post('/fcm-token', verifyFirebaseToken, userController.updateFCMToken);
router.delete('/fcm-token', verifyFirebaseToken, userController.removeFCMToken);
router.put('/notification-settings', verifyFirebaseToken, userController.updateNotificationSettings);

// ============================================
// ✅ UTILITY ROUTES
// ============================================
router.get('/count', userController.getUserCount);

module.exports = router;
