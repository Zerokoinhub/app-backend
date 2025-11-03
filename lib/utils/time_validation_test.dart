import 'package:get/get.dart';
import 'package:zero_koin/services/time_validation_service.dart';

/// Utility class for testing time validation functionality
/// This should only be used for testing and removed from production
class TimeValidationTest {
  static TimeValidationService? get _service {
    try {
      return Get.find<TimeValidationService>();
    } catch (e) {
      print('TimeValidationService not found: $e');
      return null;
    }
  }

  /// Test if time validation service is properly initialized
  static bool isServiceInitialized() {
    final service = _service;
    if (service == null) return false;
    
    return service.isInitialized.value;
  }

  /// Test if server time sync is working
  static bool isServerSynced() {
    final service = _service;
    if (service == null) return false;
    
    return service.isServerSynced.value;
  }

  /// Test if time validation is currently passing
  static bool isTimeValid() {
    final service = _service;
    if (service == null) return false;
    
    return service.isTimeValid.value;
  }

  /// Get current server time offset
  static int getServerTimeOffset() {
    final service = _service;
    if (service == null) return 0;
    
    return service.serverTimeOffset.value;
  }

  /// Get last validation error
  static String getLastError() {
    final service = _service;
    if (service == null) return 'Service not available';
    
    return service.lastTimeValidationError.value;
  }

  /// Force a time validation check
  static Future<void> forceValidationCheck() async {
    final service = _service;
    if (service == null) {
      print('Cannot force validation check: service not available');
      return;
    }
    
    await service.forceTimeValidation();
  }

  /// Reset time validation for testing
  static Future<void> resetValidation() async {
    final service = _service;
    if (service == null) {
      print('Cannot reset validation: service not available');
      return;
    }
    
    await service.resetTimeValidation();
  }

  /// Print current time validation status
  static void printStatus() {
    print('=== Time Validation Status ===');
    print('Service Initialized: ${isServiceInitialized()}');
    print('Server Synced: ${isServerSynced()}');
    print('Time Valid: ${isTimeValid()}');
    print('Server Offset: ${getServerTimeOffset()}s');
    print('Last Error: ${getLastError()}');
    print('==============================');
  }

  /// Test time manipulation detection
  /// This simulates what happens when device time is changed
  static void simulateTimeManipulation() {
    final service = _service;
    if (service == null) {
      print('Cannot simulate time manipulation: service not available');
      return;
    }

    print('🧪 Simulating time manipulation detection...');
    print('In a real scenario, you would:');
    print('1. Change your device time manually');
    print('2. Wait 30 seconds for detection');
    print('3. Check if time validation fails');
    print('4. Verify that "Time Sync..." appears on start button');
    print('5. Reset device time to correct value');
  }

  /// Instructions for manual testing
  static void printTestInstructions() {
    print('=== Manual Testing Instructions ===');
    print('1. Run the app and note current time validation status');
    print('2. Go to device settings and change the time forward by 2+ hours');
    print('3. Return to the app and wait 30 seconds');
    print('4. Check if start button shows "Time Sync..." instead of "Start"');
    print('5. Check if a warning snackbar appears');
    print('6. Reset device time to automatic/correct time');
    print('7. Verify that the app returns to normal operation');
    print('===================================');
  }
}
