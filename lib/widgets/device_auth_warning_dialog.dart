import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeviceAuthWarningDialog extends StatelessWidget {
  final VoidCallback onOkay;

  const DeviceAuthWarningDialog({
    Key? key,
    required this.onOkay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 8),
          const Text(
            'Access Denied',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'This device is already registered to another user account. Only one user can use this device.',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        ElevatedButton(
          onPressed: onOkay,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF086F8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'OK',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show the access denied dialog
  static Future<void> show() async {
    final completer = Completer<void>();

    Get.dialog(
      DeviceAuthWarningDialog(
        onOkay: () {
          Get.back();
          completer.complete();
        },
      ),
      barrierDismissible: false,
    );

    return completer.future;
  }
}
