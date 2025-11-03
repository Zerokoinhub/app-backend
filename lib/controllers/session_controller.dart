import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:zero_koin/services/api_service.dart';
import 'package:zero_koin/services/notification_service.dart';
import 'package:zero_koin/services/time_validation_service.dart';
import 'dart:async';

class SessionController extends GetxController {
  static SessionController get instance => Get.find();

  // Observable session data
  final RxList<Map<String, dynamic>> sessions = <Map<String, dynamic>>[].obs;

  // Loading state
  final RxBool isLoading = false.obs;

  // Error state
  final RxString error = ''.obs;

  // Countdown timers for locked sessions
  final RxMap<int, int> countdownTimers = <int, int>{}.obs;

  // Time validation state
  final RxBool isTimeValidationEnabled = true.obs;
  final RxBool isTimeValid = true.obs;

  // Timer for updating countdowns
  Timer? _countdownTimer;

  // Track recent session 4 completion to prevent immediate timer popup
  bool _recentSession4Reset = false;

  // Time validation service
  TimeValidationService? _timeValidationService;

  @override
  void onInit() {
    super.onInit();
    _initializeTimeValidation();
    loadSessions();
    _startCountdownTimer();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  void _showSafeSnackbar(String title, String message) {
    if (Get.context != null) {
      Future.delayed(Duration.zero, () {
        Get.snackbar(
          'Time Validation Failed',
          'Please check your time settings.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    } else {
      print("⚠ Snackbar skipped: overlay not ready.");
    }
  }

  // Initialize time validation service
  void _initializeTimeValidation() {
    try {
      _timeValidationService = Get.find<TimeValidationService>();

      // Listen to time validation state changes
      ever(_timeValidationService!.isTimeValid, (bool isValid) {
        isTimeValid.value = isValid;
        if (!isValid) {
          // Delay snackbar until overlay is ready
          Future.microtask(() {
            if (Get.context != null) {
              _handleTimeValidationFailure();
            } else {
              print('⚠ Snackbar skipped: overlay not ready.');
            }
          });
        }
      });

      print('🕐 Time validation service connected to session controller');
    } catch (e) {
      print('⚠️ Time validation service not available: $e');
      isTimeValidationEnabled.value = false;
    }
  }

  // Handle time validation failure
  void _handleTimeValidationFailure() {
    print('🚨 Time validation failed - reloading sessions from server');

    // Force reload sessions from server when time manipulation is detected
    loadSessions();

    _showSafeSnackbar(
      'Time Sync Warning',
      'Your device time appears to be incorrect...',
    );
  }

  // Load sessions from backend
  Future<void> loadSessions() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Retry time validation if not synced (user just authenticated)
      if (_timeValidationService != null &&
          !_timeValidationService!.isServerSynced.value) {
        await _timeValidationService!.retryTimeValidation();
      }

      final data = await ApiService.getUserSessions();

      if (data != null && data['sessions'] != null) {
        sessions.value = List<Map<String, dynamic>>.from(data['sessions']);
        _updateCountdownTimers();
        print('Sessions loaded: ${sessions.length}');
      } else {
        error.value = 'Failed to load sessions';
      }
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      print('Error loading sessions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Complete a session
  Future<Map<String, dynamic>> completeSession(int sessionNumber) async {
    try {
      isLoading.value = true;
      error.value = '';

      final data = await ApiService.completeSession(sessionNumber);

      if (data != null) {
        print('Complete session response data: $data');

        // Check if this was session 4 (cyclical reset)
        final bool sessionsReset = data['sessionsReset'] == true;

        // Reload sessions to get updated state
        await loadSessions();

        if (sessionsReset) {
          print('Session 4 completed! Starting new cycle from session 1.');

          // Set flag to prevent immediate timer popup
          _recentSession4Reset = true;

          // Clear the flag after a delay
          Future.delayed(Duration(seconds: 5), () {
            _recentSession4Reset = false;
          });

          // Don't show snackbar here - it will be shown in timer popup
          // Return success with reset flag
          return {'success': true, 'sessionsReset': true};
        } else {
          print('Session $sessionNumber completed successfully');
        }

        return {'success': true, 'sessionsReset': false};
      } else {
        error.value = 'Failed to complete session';
        return {'success': false, 'sessionsReset': false};
      }
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      print('Error completing session: $e');
      return {'success': false, 'sessionsReset': false};
    } finally {
      isLoading.value = false;
    }
  }

  // Check if a session is enabled (unlocked and not completed)
  bool isSessionEnabled(int sessionNumber) {
    final session = sessions.firstWhereOrNull(
      (s) => s['sessionNumber'] == sessionNumber,
    );

    if (session == null) return false;

    // Prevent session 1 from being enabled immediately after session 4 reset
    if (sessionNumber == 1 && _recentSession4Reset) {
      return false;
    }

    // Session is enabled if it's unlocked and not completed and not locked
    return session['unlockedAt'] != null &&
        session['completedAt'] == null &&
        !(session['isLocked'] ?? false);
  }

  // Check if a session is completed
  bool isSessionCompleted(int sessionNumber) {
    final session = sessions.firstWhereOrNull(
      (s) => s['sessionNumber'] == sessionNumber,
    );

    return session?['completedAt'] != null;
  }

  // Check if a session is locked (in countdown)
  bool isSessionLocked(int sessionNumber) {
    final session = sessions.firstWhereOrNull(
      (s) => s['sessionNumber'] == sessionNumber,
    );

    return session?['isLocked'] ?? false;
  }

  // Get countdown time remaining for a session
  int getCountdownRemaining(int sessionNumber) {
    return countdownTimers[sessionNumber] ?? 0;
  }

  // Update countdown timers based on session data
  void _updateCountdownTimers() {
    countdownTimers.clear();

    for (var session in sessions) {
      print(
        'Session ${session['sessionNumber']}: isLocked=${session['isLocked']}, nextUnlockAt=${session['nextUnlockAt']}, completedAt=${session['completedAt']}',
      );

      if (session['isLocked'] == true && session['nextUnlockAt'] != null) {
        final nextUnlockAt = DateTime.parse(session['nextUnlockAt']);

        // Use server time if time validation is available and valid
        DateTime now;
        if (_timeValidationService != null && isTimeValid.value) {
          now = _timeValidationService!.getServerTime();
          print('Using server-adjusted time for countdown calculation');
        } else {
          now = DateTime.now();
          print(
            'Using local time for countdown calculation (time validation unavailable)',
          );
        }

        final remaining = nextUnlockAt.difference(now).inSeconds;

        print(
          'Session ${session['sessionNumber']} countdown: ${remaining} seconds remaining',
        );

        if (remaining > 0) {
          countdownTimers[session['sessionNumber']] = remaining;
        }
      }
    }

    print('Active countdown timers: ${countdownTimers.keys.toList()}');
  }

  // Start the countdown timer
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool hasActiveCountdowns = false;

      // Update all countdown timers
      for (var sessionNumber in countdownTimers.keys.toList()) {
        final remaining = countdownTimers[sessionNumber]! - 1;

        if (remaining <= 0) {
          countdownTimers.remove(sessionNumber);
          // Trigger notification when session countdown reaches 0
          _triggerSessionUnlockedNotification();
          // Reload sessions when countdown expires
          loadSessions();
        } else {
          countdownTimers[sessionNumber] = remaining;
          hasActiveCountdowns = true;
        }
      }

      // If no active countdowns, we can reduce timer frequency
      if (!hasActiveCountdowns) {
        // Still check every 10 seconds for any new countdowns
        Future.delayed(const Duration(seconds: 9), () {
          if (countdownTimers.isEmpty) {
            loadSessions();
          }
        });
      }
    });
  }

  // Format countdown time in HH:MM:SS format
  String formatCountdown(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Get session display text
  String getSessionDisplayText(int sessionNumber) {
    if (isSessionCompleted(sessionNumber)) {
      return 'Session $sessionNumber - Completed';
    } else if (isSessionLocked(sessionNumber)) {
      final countdown = getCountdownRemaining(sessionNumber);
      if (countdown > 0) {
        return 'Session $sessionNumber - ${formatCountdown(countdown)}';
      }
    }
    return 'Session $sessionNumber';
  }

  // Refresh sessions (pull to refresh)
  Future<void> refreshSessions() async {
    await loadSessions();
  }

  // Reset sessions (for testing)
  Future<bool> resetSessions() async {
    try {
      isLoading.value = true;
      error.value = '';

      final data = await ApiService.resetUserSessions();

      if (data != null) {
        // Reload sessions to get updated state
        await loadSessions();
        print('Sessions reset successfully');

        _showSafeSnackbar(
          'Time Sync Warning',
          'Your device time appears to be incorrect...',
        );

        return true;
      } else {
        error.value = 'Failed to reset sessions';
        return false;
      }
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      print('Error resetting sessions: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Trigger notification when session countdown reaches 0
  void _triggerSessionUnlockedNotification() {
    try {
      final notificationService = Get.find<NotificationService>();
      notificationService.showSessionUnlockedNotification();
    } catch (e) {
      print('Error triggering notification: $e');
    }
  }
}
