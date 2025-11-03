import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/user_controller.dart';
import '../controllers/notification_controller.dart';
import '../view/notification_page.dart';

class NotificationService extends GetxService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  // Tracks whether UI is ready to handle navigation
  bool _appReady = false;
  NotificationResponse? _pendingStartupResponse;

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'zerokoin_notifications',
    'ZeroKoin Notifications',
    description: 'Notifications for ZeroKoin app',
    importance: Importance.high,
    playSound: true,
  );

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      // Set up token refresh handling
      _handleTokenRefresh();

      // Note: FCM token will be sent to backend when user logs in
      // This is handled by UserController after successful authentication

      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('FCM Permission granted: ${settings.authorizationStatus}');

    // Request local notification permissions for iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Request notification permission for Android 13+
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_notificationlogo');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    // If the app was launched by tapping a notification/action while it was
    // terminated, handle it here on startup
    try {
      final NotificationAppLaunchDetails? launchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        // Defer handling until after UI is ready to avoid navigator errors
        _pendingStartupResponse = launchDetails!.notificationResponse;
        print('Stored pending notification response for startup handling');
      }
    } catch (e) {
      print('Error reading notification app launch details: $e');
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle initial message if app was opened from notification
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Should be called once the app UI is ready (after first frame)
  void onAppReady() {
    if (_appReady) return;
    _appReady = true;
    if (_pendingStartupResponse != null) {
      try {
        _onNotificationTapped(_pendingStartupResponse!);
      } catch (e) {
        print('Error handling pending startup notification: $e');
      } finally {
        _pendingStartupResponse = null;
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    print('Message data: ${message.data}');

    // Check if the message supports action buttons
    bool hasActions = message.data.containsKey('action_open') && 
                     message.data.containsKey('action_dismiss');
    
    print('Has action buttons: $hasActions');

    // Check if this is an admin notification
    final notificationType = message.data['type'];

    if (notificationType == 'admin_notification') {
      // Handle admin notification
      _handleAdminNotification(message);
    } else {
      // Handle regular notification (like session unlocked)
      _showLocalNotification(
        title: message.notification?.title ?? 'ZeroKoin',
        body: message.notification?.body ?? 'You have a new notification',
        payload: message.data.toString(),
        imageUrl: message.data['image'],
        includeActions: hasActions,
      );
    }
  }

  void _handleAdminNotification(RemoteMessage message) {
    print('Received admin notification: ${message.messageId}');
    print('Admin notification data: ${message.data}');

    // Check if the message supports action buttons
    bool hasActions = message.data.containsKey('action_open') && 
                     message.data.containsKey('action_dismiss');
    
    print('Admin notification has action buttons: $hasActions');

    // Show local notification for admin notification
    _showLocalNotification(
      title: message.notification?.title ?? message.data['title'] ?? 'ZeroKoin',
      body:
          message.notification?.body ??
          message.data['description'] ??
          'You have a new notification',
      payload: message.data.toString(),
      imageUrl: message.data['image'],
      includeActions: hasActions,
    );

    // Refresh notifications in the notification controller if available
    try {
      final notificationController = Get.find<NotificationController>();
      notificationController.fetchNotifications();
      // Also refresh unread count for badge
      notificationController.fetchUnreadCount();
    } catch (e) {
      print('NotificationController not found: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Handle notification tap - navigate to specific screen if needed
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Local notification tapped: ${response.payload}');
    print('🔔 Action ID: ${response.actionId}');
    print('🔔 Notification ID: ${response.id}');
    print('🔔 Input: ${response.input}');
    
    // Handle action button clicks
    if (response.actionId != null) {
      print('🔔 Processing action button: ${response.actionId}');
      _handleNotificationAction(
        response.actionId!,
        response.payload,
        response.id,
      );
    } else {
      print('🔔 Processing regular notification tap');
      // Handle regular notification tap
      _handleRegularNotificationTap(response.payload);
    }
  }

  // Handle action button clicks
  void _handleNotificationAction(String actionId, String? payload, int? notificationId) {
    print('Notification action triggered: $actionId');
    
    switch (actionId) {
      case 'open':
        print('Open action triggered');
        _handleOpenAction(payload);
        // Cancel the notification after opening
        try {
          if (notificationId != null) {
            _localNotifications.cancel(notificationId);
          }
        } catch (e) {
          print('Failed to cancel notification after open: $e');
        }
        break;
      case 'dismiss':
        print('Dismiss action triggered');
        _handleDismissAction(payload);
        // Dismiss action auto-cancels due to cancelNotification: true
        break;
      default:
        print('Unknown action: $actionId');
        break;
    }
  }

  // Handle open action
  void _handleOpenAction(String? payload) {
    print('🚀 Opening app from notification action');
    print('🚀 Payload: $payload');
    print('🚀 App ready status: $_appReady');
    
    // Try to navigate to notification page or relevant screen
    try {
      print('🚀 Attempting navigation to NotificationPage');
      // Use Get.offAll to ensure we navigate properly even from terminated state
      Get.offAll(() => const NotificationPage());
      print('🚀 Navigation command executed successfully');
    } catch (e) {
      print('❌ Navigation error: $e');
      // Fallback: just refresh notifications
      _refreshNotificationController();
    }
  }

  // Handle dismiss action
  void _handleDismissAction(String? payload) {
    print('Dismissing notification');
    
    // Parse payload to get notification ID if available
    if (payload != null) {
      try {
        // Try to extract notification ID from payload and mark as read
        // This is optional - you might want to implement this based on your needs
        print('Notification dismissed: $payload');
      } catch (e) {
        print('Error parsing payload for dismiss action: $e');
      }
    }
    
    // Just refresh the notification count
    _refreshNotificationController();
  }

  // Handle regular notification tap (no action button)
  void _handleRegularNotificationTap(String? payload) {
    print('Regular notification tap');
    _handleOpenAction(payload); // Same as open action
  }

  // Helper method to refresh notification controller
  void _refreshNotificationController() {
    try {
      final notificationController = Get.find<NotificationController>();
      notificationController.fetchNotificationsWithReadStatus();
      notificationController.fetchUnreadCount();
    } catch (e) {
      print('NotificationController not found: $e');
    }
  }

  // Helper method to download image for notifications
  Future<Uint8List?> _downloadImage(String imageUrl) async {
    try {
      print('📥 Downloading image for notification: $imageUrl');
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {'User-Agent': 'ZeroKoin/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        print('✅ Image downloaded successfully, size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        print('❌ Failed to download image, status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error downloading image: $e');
      return null;
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
    bool includeActions = false,
  }) async {
    print('Showing local notification with includeActions: $includeActions');
    print('Image URL provided: $imageUrl');
    
    // Define action buttons
    List<AndroidNotificationAction> actions = [];
    if (includeActions) {
      actions = [
        AndroidNotificationAction(
          'open',
          'Open',
          contextual: false,
          cancelNotification: false, // Don't auto-cancel, let us handle it
          showsUserInterface: true, // This action should open the app
        ),
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          contextual: false,
          cancelNotification: true, // Auto-cancel for dismiss
          showsUserInterface: false,
        ),
      ];
    }

    // Prepare large icon and style for Android notifications
    AndroidBitmap<Object> largeIcon = const DrawableResourceAndroidBitmap('@mipmap/ic_launcher');
    StyleInformation styleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
      contentTitle: title,
      htmlFormatContentTitle: false,
    );
    
    // Try to download and set notification image
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final imageBytes = await _downloadImage(imageUrl);
        if (imageBytes != null) {
          final bigPictureImage = ByteArrayAndroidBitmap(imageBytes);
          final largeIconImage = ByteArrayAndroidBitmap(imageBytes);
          
          // Use BigPictureStyleInformation for rich image notifications
          styleInformation = BigPictureStyleInformation(
            bigPictureImage,
            largeIcon: largeIconImage,
            contentTitle: title,
            htmlFormatContentTitle: false,
            summaryText: body,
            htmlFormatSummaryText: false,
          );
          
          largeIcon = largeIconImage;
          print('✅ Configured notification with downloaded image');
        } else {
          print('⚠️ Failed to download image, using default notification style');
        }
      } catch (e) {
        print('❌ Error processing notification image: $e');
      }
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'zerokoin_notifications',
          'ZeroKoin Notifications',
          channelDescription: 'Notifications for ZeroKoin app',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@drawable/ic_stat_notificationlogo',
          largeIcon: largeIcon,
          color: const Color(0xFF0682A2), // App's primary color
          actions: includeActions ? actions : null,
          category: AndroidNotificationCategory.message,
          styleInformation: styleInformation,
          autoCancel: false, // Don't auto-cancel on tap, let action buttons handle it
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'ZEROKOIN_CATEGORY',
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Public method to show session unlocked notification
  Future<void> showSessionUnlockedNotification({bool includeActions = true}) async {
    await _showLocalNotification(
      title: 'ZeroKoin',
      body: 'Session unlocked! Complete the session to claim 30 Zero Koins.',
      includeActions: includeActions,
    );
  }

  // Public method to show admin notification
  Future<void> showAdminNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, String>? data,
    bool includeActions = true,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: data?.toString(),
      imageUrl: imageUrl,
      includeActions: includeActions,
    );
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Send FCM token to backend
  Future<void> sendFCMTokenToBackend() async {
    try {
      print('🔄 Starting FCM token send to backend...');

      final token = await getFCMToken();
      if (token == null) {
        print('❌ No FCM token available');
        return;
      }

      print('✅ FCM token obtained: ${token.substring(0, 20)}...');

      // Get device info
      String? platform;
      if (Platform.isAndroid) {
        platform = 'android';
      } else if (Platform.isIOS) {
        platform = 'ios';
      }

      print('📱 Platform detected: $platform');

      // Check if user is logged in
      try {
        final userController = Get.find<UserController>();
        if (!userController.isUserDataLoaded) {
          print('⚠️ User not logged in yet, skipping FCM token send');
          return;
        }

        print('👤 User is logged in, sending token...');

        // Send to backend
        final success = await userController.updateFCMToken(token, platform);

        if (success) {
          print('✅ FCM token sent to backend successfully');
        } else {
          print('❌ Failed to send FCM token to backend');
        }
      } catch (userControllerError) {
        print(
          '⚠️ UserController not found or user not logged in: $userControllerError',
        );
      }
    } catch (e) {
      print('❌ Error sending FCM token to backend: $e');
    }
  }

  // Handle token refresh
  void _handleTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM token refreshed: $newToken');
      // Send new token to backend
      sendFCMTokenToBackend();
    });
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // This is invoked when a notification action is tapped while the app is in
  // the background or terminated. Avoid heavy work here; just log/cancel.
  try {
    print('🌙 BG notification response. actionId=${response.actionId}, id=${response.id}');
    print('🌙 Background payload: ${response.payload}');
    print('🌙 Background input: ${response.input}');
    // Nothing else to do here. If the action opens the app, the foreground
    // handler in `_onNotificationTapped` will run after launch.
  } catch (e) {
    print('❌ Error in background notification tap handler: $e');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  try {
    // Show a local notification with actions when we get a data-only message
    final plugin = FlutterLocalNotificationsPlugin();

    // Determine if actions are present
    final hasActions = message.data.containsKey('action_open') &&
        message.data.containsKey('action_dismiss');

    // Try to download and configure image for background notification
    AndroidBitmap<Object> largeIcon = const DrawableResourceAndroidBitmap('@mipmap/ic_launcher');
    StyleInformation styleInformation = const BigTextStyleInformation('');
    
    final imageUrl = message.data['image'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(imageUrl),
          headers: {'User-Agent': 'ZeroKoin/1.0'},
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final imageBytes = response.bodyBytes;
          final bigPictureImage = ByteArrayAndroidBitmap(imageBytes);
          final largeIconImage = ByteArrayAndroidBitmap(imageBytes);
          
          styleInformation = BigPictureStyleInformation(
            bigPictureImage,
            largeIcon: largeIconImage,
            contentTitle: message.data['title'] ?? 'ZeroKoin',
            summaryText: message.data['body'] ?? 'You have a new notification',
          );
          
          largeIcon = largeIconImage;
          print('✅ Background notification configured with image');
        }
      } catch (e) {
        print('❌ Error loading background notification image: $e');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'zerokoin_notifications',
      'ZeroKoin Notifications',
      channelDescription: 'Notifications for ZeroKoin app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@drawable/ic_stat_notificationlogo',
      largeIcon: largeIcon,
      color: const Color(0xFF0682A2),
      actions: hasActions
          ? const [
              AndroidNotificationAction(
                'open', 
                'Open', 
                cancelNotification: false,
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'dismiss', 
                'Dismiss', 
                cancelNotification: true,
                showsUserInterface: false,
              ),
            ]
          : null,
      category: AndroidNotificationCategory.message,
      styleInformation: styleInformation,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'ZEROKOIN_CATEGORY',
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.data['title'] ?? 'ZeroKoin',
      message.data['body'] ?? 'You have a new notification',
      details,
      payload: message.data.toString(),
    );
  } catch (e) {
    print('Background notification error: $e');
  }
}
