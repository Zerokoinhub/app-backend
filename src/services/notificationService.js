const { admin } = require('../config/firebase');

class NotificationService {
  constructor() {
    this.messaging = admin.messaging();
  }

  // ============ YOUR EXISTING FUNCTIONS ============
  
  async sendNotificationToUser(fcmToken, title, body, data = {}) {
    try {
      if (!fcmToken) {
        console.warn('No FCM token provided for notification');
        return { success: false, error: 'No FCM token' };
      }

      const message = {
        token: fcmToken,
        data: {
          ...data,
          timestamp: Date.now().toString(),
          title: title,
          body: body,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          action_open: 'true',
          action_dismiss: 'true',
        },
        android: {
          priority: 'high',
          data: {
            ...Object.fromEntries(
              Object.entries(data).map(([key, value]) => [key, String(value)])
            ),
            timestamp: Date.now().toString(),
            title: String(title),
            body: String(body),
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            action_open: 'true',
            action_dismiss: 'true',
            has_actions: 'true'
          }
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body },
              badge: 1,
              sound: 'default',
              'content-available': 1,
              category: 'ZEROKOIN_CATEGORY',
            },
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            action_open: 'true',
            action_dismiss: 'true',
          },
          headers: {
            'apns-priority': '10',
          },
        },
      };

      const response = await this.messaging.send(message);
      console.log('✅ Push notification sent successfully:', response);
      return { success: true, messageId: response };
    } catch (error) {
      console.error('❌ Error sending push notification:', error);
      
      if (error.code === 'messaging/invalid-registration-token' || 
          error.code === 'messaging/registration-token-not-registered') {
        console.log('🗑️ Invalid FCM token, should be removed from database');
        return { success: false, error: 'Invalid token', shouldRemoveToken: true };
      }
      
      return { success: false, error: error.message };
    }
  }

  // ✅ ADD THIS FUNCTION - Send daily bonus notification to user
  async sendDailyBonusNotification(fcmToken, rank, bonusAmount, userName = 'Miner') {
    const rankEmoji = rank === 1 ? '🥇' : rank === 2 ? '🥈' : '🥉';
    const rankText = rank === 1 ? 'FIRST' : rank === 2 ? 'SECOND' : 'THIRD';
    
    const title = `🎉 Daily Bonus Available!`;
    const body = `${rankEmoji} Congratulations ${userName}! You're in ${rankText} place! Claim ${bonusAmount} coins now!`;
    
    const data = {
      type: 'daily_bonus',
      rank: rank.toString(),
      bonusAmount: bonusAmount.toString(),
      screen: 'leaderboard',
      action: 'claim_bonus'
    };

    return await this.sendNotificationToUser(fcmToken, title, body, data);
  }

  // ✅ ADD THIS FUNCTION - Send daily bonus to all top 3 users
  async sendDailyBonusToTopUsers() {
    try {
      const User = require('../models/User');
      const today = new Date().toISOString().split('T')[0];
      
      console.log('🎁 Sending daily bonus notifications to top 3 users...');
      
      // Get top 3 users
      const topUsers = await User.find({})
        .sort({ balance: -1 })
        .limit(3)
        .lean();
      
      const bonuses = [20, 10, 5];
      const results = [];
      
      for (let i = 0; i < topUsers.length; i++) {
        const user = topUsers[i];
        const rank = i + 1;
        const bonusAmount = bonuses[i];
        
        // Check if already claimed today
        const fullUser = await User.findOne({ firebaseUid: user.firebaseUid });
        
        if (fullUser && fullUser.lastBonusClaimDate !== today) {
          // Get all active FCM tokens
          const activeTokens = fullUser.fcmTokens
            .filter(t => t.isActive && t.token)
            .map(t => t.token);
          
          if (activeTokens.length > 0) {
            // Send to first token (or loop through all)
            for (const token of activeTokens) {
              const sent = await this.sendDailyBonusNotification(
                token, 
                rank, 
                bonusAmount, 
                user.name || user.email
              );
              results.push({
                email: user.email,
                rank: rank,
                bonusAmount: bonusAmount,
                notificationSent: sent.success,
                tokensCount: activeTokens.length
              });
            }
          } else {
            results.push({
              email: user.email,
              rank: rank,
              bonusAmount: bonusAmount,
              notificationSent: false,
              reason: 'No active FCM tokens'
            });
          }
        } else {
          results.push({
            email: user.email,
            rank: rank,
            bonusAmount: bonusAmount,
            notificationSent: false,
            reason: 'Already claimed today'
          });
        }
      }
      
      console.log('📱 Daily bonus notifications sent:', results);
      return results;
      
    } catch (error) {
      console.error('❌ Error sending daily bonus notifications:', error);
      return [];
    }
  }

  // ✅ ADD THIS FUNCTION - Send reminder to claim bonus (if not claimed by evening)
  async sendBonusReminder(fcmToken, rank, bonusAmount) {
    const title = `⏰ Bonus Reminder!`;
    const body = `Don't forget to claim your daily bonus of ${bonusAmount} coins! You're still in top ${rank} position.`;
    
    const data = {
      type: 'bonus_reminder',
      rank: rank.toString(),
      bonusAmount: bonusAmount.toString(),
      screen: 'leaderboard'
    };

    return await this.sendNotificationToUser(fcmToken, title, body, data);
  }

  // ============ YOUR EXISTING FUNCTIONS ============
  
  async sendSessionUnlockedNotification(fcmToken, sessionNumber) {
    const title = 'ZeroKoin';
    const body = `Session ${sessionNumber} unlocked! Complete the session to claim 30 Zero Koins.`;
    const data = {
      type: 'session_unlocked',
      sessionNumber: sessionNumber.toString(),
    };

    return await this.sendNotificationToUser(fcmToken, title, body, data);
  }

  async sendBatchNotifications(notifications) {
    const results = [];
    
    for (const notification of notifications) {
      const result = await this.sendNotificationToUser(
        notification.fcmToken,
        notification.title,
        notification.body,
        notification.data
      );
      results.push({
        ...result,
        userId: notification.userId,
        fcmToken: notification.fcmToken,
      });
    }
    
    return results;
  }

  async validateFCMToken(fcmToken) {
    try {
      if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.length < 50) {
        return { valid: false, error: 'Invalid token format' };
      }
      return { valid: true };
    } catch (error) {
      console.error('FCM token validation failed:', error);
      return { valid: false, error: error.message };
    }
  }
}

// Export both the class and a singleton instance
module.exports = NotificationService;
module.exports.instance = new NotificationService();
