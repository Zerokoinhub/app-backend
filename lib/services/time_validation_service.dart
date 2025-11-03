import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zero_koin/services/api_service.dart';

/// Service to detect and prevent system time manipulation
class TimeValidationService extends GetxService {
  static TimeValidationService get instance =>
      Get.find<TimeValidationService>();

  // Constants
  static const String _baseUrl = 'https://zero-koin-backend.onrender.com/api';
  static const String _keyLastKnownTime = 'last_known_time';
  static const String _keyServerTimeOffset = 'server_time_offset';
  static const String _keyTimeValidationEnabled = 'time_validation_enabled';
  static const String _keyLastServerSync = 'last_server_sync';

  // Thresholds for detecting time manipulation
  static const int _maxAllowedTimeJump =
      3600; // 1 hour in seconds (very lenient for user time changes)
  static const int _serverSyncInterval = 3600; // 1 hour in seconds
  static const int _timeCheckInterval = 120; // 2 minutes (reduced frequency)

  // Observable state
  final RxBool isTimeValid = true.obs;
  final RxBool isServerSynced = false.obs;
  final RxBool isInitialized = false.obs;
  final RxString lastTimeValidationError = ''.obs;
  final RxInt serverTimeOffset =
      0.obs; // Difference between server and local time

  Timer? _timeCheckTimer;
  DateTime? _lastKnownTime;
  DateTime? _lastServerSyncTime;
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    // Don't set initial states - let initialization determine the real state
    _initializeTimeValidation();
  }

  @override
  void onClose() {
    _timeCheckTimer?.cancel();
    super.onClose();
  }

  /// Public method to wait for initialization to complete
  Future<void> waitForInitialization() async {
    while (!isInitialized.value) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Initialize time validation service
  Future<void> _initializeTimeValidation() async {
    try {
      await _loadStoredTimeData();

      // Try to sync with server time, but don't fail if user is not authenticated
      final syncSuccess = await _syncWithServerTime();
      if (syncSuccess) {
        // Server sync successful - we have valid time
        isTimeValid.value = true;
        isServerSynced.value = true;
      } else {
        // If sync fails (e.g., user not authenticated), set appropriate states
        isTimeValid.value = false; // Show "Time Sync..." until we can validate
        isServerSynced.value = false;
        print(
          '⚠️ Initial server sync failed, will retry when user authenticates',
        );
      }

      _startTimeValidationTimer();
      _isInitialized = true;
      isInitialized.value = true;
      print('🕐 Time validation service initialized');
    } catch (e) {
      print('❌ Error initializing time validation: $e');
      lastTimeValidationError.value = 'Initialization failed: $e';
      // Set states to show sync needed
      isTimeValid.value = false;
      isServerSynced.value = false;
      // Still mark as initialized to prevent blocking the app
      isInitialized.value = true;
    }
  }

  /// Load stored time validation data
  Future<void> _loadStoredTimeData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load last known time
    final lastTimeMs = prefs.getInt(_keyLastKnownTime);
    if (lastTimeMs != null) {
      final storedTime = DateTime.fromMillisecondsSinceEpoch(lastTimeMs);
      final currentTime = DateTime.now();
      final timeDifference = currentTime.difference(storedTime).inSeconds.abs();

      // If stored time is more than 24 hours old, clear it to avoid false positives
      if (timeDifference > 86400) {
        // 24 hours
        print(
          '🔄 Clearing stale time validation data (${timeDifference}s old)',
        );
        await prefs.remove(_keyLastKnownTime);
        _lastKnownTime = null;
      } else {
        _lastKnownTime = storedTime;
      }
    }

    // Load server time offset
    serverTimeOffset.value = prefs.getInt(_keyServerTimeOffset) ?? 0;

    // Load last server sync time
    final lastSyncMs = prefs.getInt(_keyLastServerSync);
    if (lastSyncMs != null) {
      _lastServerSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }

    // Check if time validation is enabled
    final isEnabled = prefs.getBool(_keyTimeValidationEnabled) ?? true;
    if (!isEnabled) {
      print('⚠️ Time validation is disabled');
    }
  }

  /// Sync with server time to get authoritative timestamp
  Future<bool> _syncWithServerTime() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ No authenticated user for server time sync');
        return false;
      }

      final requestTime = DateTime.now();
      final data = await ApiService.getServerTime();

      if (data != null && data['serverTime'] != null) {
        final responseTime = DateTime.now();
        final serverTime = DateTime.parse(data['serverTime']);

        // Calculate network latency and adjust server time
        final networkLatency =
            responseTime.difference(requestTime).inMilliseconds ~/ 2;
        final adjustedServerTime = serverTime.add(
          Duration(milliseconds: networkLatency),
        );

        // Calculate offset between server and local time
        final offset = adjustedServerTime.difference(responseTime).inSeconds;
        serverTimeOffset.value = offset;

        // Store sync data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyServerTimeOffset, offset);
        await prefs.setInt(
          _keyLastServerSync,
          responseTime.millisecondsSinceEpoch,
        );

        _lastServerSyncTime = responseTime;
        isServerSynced.value = true;

        print('✅ Server time synced. Offset: ${offset}s');
        return true;
      } else {
        print('❌ Server time sync failed: No data received');
        return false;
      }
    } catch (e) {
      print('❌ Error syncing server time: $e');
      lastTimeValidationError.value = 'Server sync failed: $e';
      return false;
    }
  }

  /// Start periodic time validation checks
  void _startTimeValidationTimer() {
    _timeCheckTimer?.cancel();
    _timeCheckTimer = Timer.periodic(
      Duration(seconds: _timeCheckInterval),
      (_) => _validateCurrentTime(),
    );
  }

  /// Validate current time against expected progression
  Future<void> _validateCurrentTime() async {
    try {
      final currentTime = DateTime.now();

      // Always check server sync first to get accurate time reference
      if (_shouldSyncWithServer()) {
        await _syncWithServerTime();
      }

      // If we have server time, check if local time is close to server time
      if (isServerSynced.value) {
        final serverTime = getServerTime();
        final timeDifference =
            serverTime.difference(currentTime).inSeconds.abs();

        // If time is synchronized with server (within 5 minutes), consider it valid
        if (timeDifference <= 300) {
          await _updateLastKnownTime(currentTime);
          isTimeValid.value = true;
          lastTimeValidationError.value = '';
          return; // Skip jump detection if time is synchronized
        }
      }

      // Validate time progression only if not synchronized with server
      final timeJumpDetected = _detectTimeJump(currentTime);

      if (timeJumpDetected) {
        await _handleTimeManipulation();
      } else {
        // Update last known time if validation passes
        await _updateLastKnownTime(currentTime);
        isTimeValid.value = true;
        lastTimeValidationError.value = '';
      }
    } catch (e) {
      print('❌ Error during time validation: $e');
      lastTimeValidationError.value = 'Validation error: $e';
    }
  }

  /// Check if we should sync with server
  bool _shouldSyncWithServer() {
    if (_lastServerSyncTime == null) return true;

    final timeSinceLastSync =
        DateTime.now().difference(_lastServerSyncTime!).inSeconds;
    return timeSinceLastSync >= _serverSyncInterval;
  }

  /// Detect if time has been manipulated
  bool _detectTimeJump(DateTime currentTime) {
    if (_lastKnownTime == null) {
      // First time check, no baseline to compare
      return false;
    }

    final timeDifference =
        currentTime.difference(_lastKnownTime!).inSeconds.abs();

    // If the time difference is extremely large (more than 24 hours),
    // it's likely due to app being closed for a long time, not manipulation
    if (timeDifference > 86400) {
      // 24 hours
      print(
        '⚠️ Large time gap detected (${timeDifference}s), likely app was closed for extended period. Resetting baseline.',
      );
      // Reset the baseline instead of treating as manipulation
      _lastKnownTime = currentTime;
      return false;
    }

    // If the time difference is moderate (between 30 minutes and 24 hours),
    // it could be user adjusting time settings. Be more lenient.
    if (timeDifference > 1800 && timeDifference <= 86400) {
      // 30 minutes to 24 hours
      print(
        '⚠️ Moderate time gap detected (${timeDifference}s), likely user time adjustment. Syncing with server and resetting baseline.',
      );
      // Force a server sync to get accurate time and reset baseline
      _lastKnownTime = currentTime;
      // Trigger server sync but don't treat as manipulation
      Future.delayed(Duration.zero, () => _syncWithServerTime());
      return false;
    }

    final expectedMinTime = _lastKnownTime!.add(
      Duration(seconds: _timeCheckInterval - 60), // Very lenient minimum
    );
    final expectedMaxTime = _lastKnownTime!.add(
      Duration(seconds: _timeCheckInterval + _maxAllowedTimeJump),
    );

    // Check if current time is outside expected range
    if (currentTime.isBefore(expectedMinTime) ||
        currentTime.isAfter(expectedMaxTime)) {
      print('⚠️ Time jump detected: ${timeDifference}s from last known time');
      return true;
    }

    return false;
  }

  /// Handle detected time manipulation
  Future<void> _handleTimeManipulation() async {
    print('🚨 Time manipulation detected!');

    // Try to re-sync with server to get accurate time first
    final syncSuccess = await _syncWithServerTime();

    if (syncSuccess) {
      // Check if the current time is now close to server time
      final serverTime = getServerTime();
      final localTime = DateTime.now();
      final timeDifference = serverTime.difference(localTime).inSeconds.abs();

      // If time is now synchronized (within 5 minutes), clear the error
      if (timeDifference <= 300) {
        print(
          '✅ Time is now synchronized with server, clearing validation error',
        );
        isTimeValid.value = true;
        lastTimeValidationError.value = '';
        _lastKnownTime = localTime; // Reset baseline
        return; // Don't show error or reload sessions
      }
    }

    // Only set error state if time is still not synchronized
    isTimeValid.value = false;
    lastTimeValidationError.value = 'Device time has been manually changed';

    if (syncSuccess) {
      // Force reload of session data from server
      try {
        // Use dynamic approach to avoid circular dependency
        if (Get.isRegistered(tag: 'SessionController')) {
          final sessionController = Get.find(tag: 'SessionController');
          await sessionController.loadSessions();
          print('🔄 Session data reloaded after time manipulation');
        }
      } catch (e) {
        print('❌ Error reloading sessions after time manipulation: $e');
      }
    }

    if (Get.context != null) {
      // Only show snackbar if time is still not synchronized
      Get.snackbar(
        'Time Validation Error',
        'Device time has been manually changed. Please ensure your device time is correct.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );
    } else {
      print("⚠ Snackbar skipped: overlay not ready.");
    }
  }

  /// Update last known time
  Future<void> _updateLastKnownTime(DateTime time) async {
    _lastKnownTime = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastKnownTime, time.millisecondsSinceEpoch);
  }

  /// Get server-adjusted current time
  DateTime getServerTime() {
    final localTime = DateTime.now();
    return localTime.add(Duration(seconds: serverTimeOffset.value));
  }

  /// Check if time validation is currently passing
  bool get isTimeValidationPassing => isTimeValid.value && isServerSynced.value;

  /// Force a time validation check
  Future<void> forceTimeValidation() async {
    await _validateCurrentTime();
  }

  /// Retry time validation when user authenticates
  Future<void> retryTimeValidation() async {
    if (!isServerSynced.value) {
      print('🔄 Retrying time validation after user authentication');
      final syncSuccess = await _syncWithServerTime();
      if (syncSuccess) {
        isTimeValid.value = true;
        print('✅ Time validation successful after authentication');
      } else {
        print('❌ Time validation failed after authentication');
      }
    }
  }

  /// Reset time validation (for testing purposes)
  Future<void> resetTimeValidation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastKnownTime);
    await prefs.remove(_keyServerTimeOffset);
    await prefs.remove(_keyLastServerSync);

    _lastKnownTime = null;
    _lastServerSyncTime = null;
    serverTimeOffset.value = 0;
    isTimeValid.value = true;
    isServerSynced.value = false;
    lastTimeValidationError.value = '';

    // Cancel existing timer
    _timeCheckTimer?.cancel();

    await _initializeTimeValidation();
  }

  /// Clear time validation errors and force re-sync
  Future<void> clearTimeValidationError() async {
    lastTimeValidationError.value = '';
    isTimeValid.value = true;

    // Reset the last known time to current time to avoid false positives
    _lastKnownTime = DateTime.now();

    // Force a fresh sync with server
    final syncSuccess = await _syncWithServerTime();
    if (syncSuccess) {
      print('✅ Time validation cleared and re-synced successfully');
    } else {
      print('⚠️ Time validation cleared but sync failed');
    }
  }
}
