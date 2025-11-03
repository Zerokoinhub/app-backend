import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/services/time_validation_service.dart';

/// Debug widget to test time validation functionality
/// This widget should only be used for testing and removed from production
class TimeValidationDebugWidget extends StatelessWidget {
  const TimeValidationDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final timeValidationService = Get.find<TimeValidationService>();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Time Validation Debug',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Time validation status
            Obx(() => Row(
              children: [
                Icon(
                  timeValidationService.isTimeValid.value
                      ? Icons.check_circle
                      : Icons.error,
                  color: timeValidationService.isTimeValid.value
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Time Valid: ${timeValidationService.isTimeValid.value}',
                  style: TextStyle(
                    color: timeValidationService.isTimeValid.value
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )),
            
            const SizedBox(height: 8),
            
            // Server sync status
            Obx(() => Row(
              children: [
                Icon(
                  timeValidationService.isServerSynced.value
                      ? Icons.sync
                      : Icons.sync_disabled,
                  color: timeValidationService.isServerSynced.value
                      ? Colors.blue
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Server Synced: ${timeValidationService.isServerSynced.value}',
                  style: TextStyle(
                    color: timeValidationService.isServerSynced.value
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
              ],
            )),
            
            const SizedBox(height: 8),
            
            // Server time offset
            Obx(() => Text(
              'Server Offset: ${timeValidationService.serverTimeOffset.value}s',
              style: const TextStyle(fontSize: 14),
            )),
            
            const SizedBox(height: 8),
            
            // Last error
            Obx(() => timeValidationService.lastTimeValidationError.value.isNotEmpty
                ? Text(
                    'Error: ${timeValidationService.lastTimeValidationError.value}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  )
                : const SizedBox.shrink()),
            
            const SizedBox(height: 16),
            
            // Current times
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
              builder: (context, snapshot) {
                final localTime = snapshot.data ?? DateTime.now();
                final serverTime = timeValidationService.getServerTime();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Time: ${localTime.toIso8601String()}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    Text(
                      'Server Time: ${serverTime.toIso8601String()}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    Text(
                      'Difference: ${serverTime.difference(localTime).inSeconds}s',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await timeValidationService.forceTimeValidation();
                    Get.snackbar(
                      'Debug',
                      'Time validation check triggered',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Text('Force Check'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await timeValidationService.resetTimeValidation();
                    Get.snackbar(
                      'Debug',
                      'Time validation reset',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Instructions
            const Text(
              'Instructions:\n'
              '1. Note the current server offset\n'
              '2. Change your device time manually\n'
              '3. Wait 30 seconds for detection\n'
              '4. Check if "Time Valid" becomes false\n'
              '5. Reset device time to correct value',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
