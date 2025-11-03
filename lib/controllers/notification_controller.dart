import 'package:get/get.dart';
import 'package:zero_koin/models/notification_model.dart';
import 'package:zero_koin/services/api_service.dart';

class NotificationController extends GetxController {
  // Observable list of notifications
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  // Loading state
  final RxBool isLoading = false.obs;

  // Error state
  final RxString error = ''.obs;

  // Unread notification count for badge
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch notifications when controller is initialized
    fetchNotifications();
    // Fetch unread count when controller is initialized
    fetchUnreadCount();
  }

  // Fetch all notifications from backend
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      error.value = '';

      print('🔄 Fetching notifications from backend...');

      final response = await ApiService.getAllNotifications();

      if (response != null && response['notifications'] != null) {
        final List<dynamic> notificationData = response['notifications'];

        // Convert to NotificationModel objects
        final List<NotificationModel> fetchedNotifications =
            notificationData
                .map((json) => NotificationModel.fromJson(json))
                .toList();

        notifications.value = fetchedNotifications;

        print(
          '✅ Successfully fetched ${fetchedNotifications.length} notifications',
        );
      } else {
        print('⚠️ No notifications data received from backend');
        notifications.value = [];
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      error.value = 'Failed to load notifications: $e';
      notifications.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh notifications (pull to refresh)
  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }

  // Get recent notifications (last 10)
  List<NotificationModel> get recentNotifications {
    return notifications.take(10).toList();
  }

  // Get sent notifications only
  List<NotificationModel> get sentNotifications {
    return notifications.where((notification) => notification.isSent).toList();
  }

  // Get unsent notifications only
  List<NotificationModel> get unsentNotifications {
    return notifications.where((notification) => !notification.isSent).toList();
  }

  // Check if there are any notifications
  bool get hasNotifications {
    return notifications.isNotEmpty;
  }

  // Get notification count
  int get notificationCount {
    return notifications.length;
  }

  // Get recent notification count
  int get recentNotificationCount {
    return recentNotifications.length;
  }

  // Clear error
  void clearError() {
    error.value = '';
  }

  // Fetch notifications with read status from backend
  Future<void> fetchNotificationsWithReadStatus() async {
    try {
      isLoading.value = true;
      error.value = '';

      print('🔄 Fetching notifications with read status from backend...');

      final response = await ApiService.getNotificationsWithReadStatus();

      if (response != null && response['notifications'] != null) {
        final List<dynamic> notificationData = response['notifications'];

        // Convert to NotificationModel objects
        final List<NotificationModel> fetchedNotifications =
            notificationData
                .map((json) => NotificationModel.fromJson(json))
                .toList();

        notifications.value = fetchedNotifications;

        // Update unread count
        updateUnreadCount();

        print(
          '✅ Successfully fetched ${fetchedNotifications.length} notifications with read status',
        );
      } else {
        print('⚠️ No notifications data received from backend');
        notifications.value = [];
        unreadCount.value = 0;
      }
    } catch (e) {
      print('❌ Error fetching notifications with read status: $e');
      error.value = 'Failed to load notifications: $e';
      notifications.value = [];
      unreadCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch unread notification count from backend
  Future<void> fetchUnreadCount() async {
    try {
      print('🔄 Fetching unread notification count from backend...');

      final count = await ApiService.getUnreadNotificationCount();

      if (count != null) {
        unreadCount.value = count;
        print('✅ Successfully fetched unread count: $count');
      } else {
        print('⚠️ Failed to fetch unread count');
        unreadCount.value = 0;
      }
    } catch (e) {
      print('❌ Error fetching unread count: $e');
      unreadCount.value = 0;
    }
  }

  // Update unread count based on current notifications
  void updateUnreadCount() {
    final unreadNotifications =
        notifications.where((notification) => !notification.isRead).toList();
    unreadCount.value = unreadNotifications.length;
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final success = await ApiService.markNotificationAsRead(notificationId);

      if (success) {
        // Update local notification status
        final index = notifications.indexWhere(
          (notification) => notification.id == notificationId,
        );
        if (index != -1) {
          final updatedNotification = NotificationModel(
            id: notifications[index].id,
            image: notifications[index].image,
            title: notifications[index].title,
            content: notifications[index].content,
            link: notifications[index].link,
            isSent: notifications[index].isSent,
            sentAt: notifications[index].sentAt,
            createdAt: notifications[index].createdAt,
            isRead: true,
          );
          notifications[index] = updatedNotification;
          updateUnreadCount();
        }
        print('✅ Successfully marked notification as read');
      } else {
        print('❌ Failed to mark notification as read');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final success = await ApiService.markAllNotificationsAsRead();

      if (success) {
        // Update all local notifications to read status
        final updatedNotifications =
            notifications
                .map(
                  (notification) => NotificationModel(
                    id: notification.id,
                    image: notification.image,
                    title: notification.title,
                    content: notification.content,
                    link: notification.link,
                    isSent: notification.isSent,
                    sentAt: notification.sentAt,
                    createdAt: notification.createdAt,
                    isRead: true,
                  ),
                )
                .toList();

        notifications.value = updatedNotifications;
        unreadCount.value = 0;
        print('✅ Successfully marked all notifications as read');
      } else {
        print('❌ Failed to mark all notifications as read');
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  // Method to call when notification page is opened
  Future<void> onNotificationPageOpened() async {
    // Mark all notifications as read when page is opened
    await markAllNotificationsAsRead();
    // Refresh notifications with read status
    await fetchNotificationsWithReadStatus();
  }

  // Handle notification tap (for future use)
  void onNotificationTap(NotificationModel notification) {
    print('Notification tapped: ${notification.title}');
    // Mark this specific notification as read
    if (!notification.isRead) {
      markNotificationAsRead(notification.id);
    }
  }

  // Get unread notifications only
  List<NotificationModel> get unreadNotifications {
    return notifications.where((notification) => !notification.isRead).toList();
  }

  // Get read notifications only
  List<NotificationModel> get readNotifications {
    return notifications.where((notification) => notification.isRead).toList();
  }

  // Check if there are unread notifications
  bool get hasUnreadNotifications {
    return unreadCount.value > 0;
  }
}
