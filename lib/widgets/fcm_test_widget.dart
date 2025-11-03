import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/notification_service.dart';
import '../controllers/user_controller.dart';

class FCMTestWidget extends StatelessWidget {
  const FCMTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'FCM Token Test',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              try {
                final notificationService = Get.find<NotificationService>();
                final token = await notificationService.getFCMToken();
                
                if (token != null) {
                  Get.snackbar(
                    'FCM Token',
                    'Token: ${token.substring(0, 20)}...',
                    duration: const Duration(seconds: 3),
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                  print('FCM Token: $token');
                } else {
                  Get.snackbar(
                    'Error',
                    'No FCM token available',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to get FCM token: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Get FCM Token'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              try {
                final notificationService = Get.find<NotificationService>();
                await notificationService.sendFCMTokenToBackend();
                
                Get.snackbar(
                  'Success',
                  'FCM token sent to backend',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to send FCM token: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Send Token to Backend'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              try {
                final userController = Get.find<UserController>();
                final success = await userController.updateFCMToken('test_token', 'test_platform');
                
                Get.snackbar(
                  success ? 'Success' : 'Failed',
                  success ? 'Test token updated' : 'Failed to update test token',
                  backgroundColor: success ? Colors.green : Colors.red,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Test failed: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Test Token Update'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              try {
                final notificationService = Get.find<NotificationService>();
                await notificationService.showSessionUnlockedNotification();
                
                Get.snackbar(
                  'Success',
                  'Local notification sent',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to send local notification: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Test Local Notification'),
          ),
        ],
      ),
    );
  }
}
