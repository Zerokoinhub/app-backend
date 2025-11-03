import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';

class DeviceAuthService {
  static const String _keyLastUserEmail = 'last_user_email';
  static const String _keyDeviceId = 'device_id';
  static const String _keyFirstSignInTime = 'first_signin_time';
  static const String _keyIsSignedOut = 'is_signed_out';
  
  static DeviceAuthService? _instance;
  static DeviceAuthService get instance {
    _instance ??= DeviceAuthService._();
    return _instance!;
  }
  
  DeviceAuthService._();
  
  /// Get unique device identifier
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_keyDeviceId);
    
    if (deviceId == null) {
      // Generate device ID based on device info
      deviceId = await _generateDeviceId();
      await prefs.setString(_keyDeviceId, deviceId);
    }
    
    return deviceId;
  }
  
  /// Generate a unique device identifier
  Future<String> _generateDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String identifier = '';
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        identifier = '${androidInfo.model}_${androidInfo.id}_${androidInfo.fingerprint}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        identifier = '${iosInfo.model}_${iosInfo.identifierForVendor}_${iosInfo.systemVersion}';
      } else {
        // Fallback for other platforms
        identifier = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      // Fallback if device info fails
      identifier = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Hash the identifier for privacy and consistency
    final bytes = utf8.encode(identifier);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Check if this is the first user to sign in on this device
  Future<bool> isFirstUserOnDevice() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_keyLastUserEmail);
  }
  
  /// Get the last signed-in user email
  Future<String?> getLastUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastUserEmail);
  }
  
  /// Check if the provided email is different from the last signed-in user
  Future<bool> isDifferentUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = await getLastUserEmail();
    final isSignedOut = prefs.getBool(_keyIsSignedOut) ?? true;

    // If no previous user found, allow sign in
    if (lastEmail == null) {
      print('🔍 No previous user found - allowing sign in');
      return false;
    }

    // If same user is trying to sign in again, allow it
    if (lastEmail.toLowerCase() == email.toLowerCase()) {
      print('🔍 Same user trying to sign in again - allowing');
      return false;
    }

    // Different user trying to sign in - this should trigger warning
    final result = true;

    // Debug logging
    print('🔍 DeviceAuthService.isDifferentUser():');
    print('  - Last email: $lastEmail');
    print('  - New email: $email');
    print('  - Is signed out: $isSignedOut');
    print('  - Is different: $result');

    return result;
  }
  
  /// Store the current user as the device's signed-in user
  Future<void> setCurrentUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUserEmail, email.toLowerCase());
    await prefs.setBool(_keyIsSignedOut, false); // Mark as signed in

    // Store first sign-in time if this is the first user
    if (!prefs.containsKey(_keyFirstSignInTime)) {
      await prefs.setInt(_keyFirstSignInTime, DateTime.now().millisecondsSinceEpoch);
    }

    // Debug logging
    print('✅ DeviceAuthService.setCurrentUser():');
    print('  - Email stored: ${email.toLowerCase()}');
    print('  - Marked as signed in');
    print('  - First sign-in time set: ${!prefs.containsKey(_keyFirstSignInTime)}');
  }
  
  /// Clear device authentication data but keep the last user for comparison
  /// This ensures we can still detect different users trying to sign in
  Future<void> clearDeviceAuth() async {
    // Don't actually clear the last user email - just mark as signed out
    // This way we can still detect different users trying to sign in
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString(_keyLastUserEmail);
    await prefs.setBool(_keyIsSignedOut, true); // Mark as signed out

    // Debug logging
    print('🧹 DeviceAuthService.clearDeviceAuth():');
    print('  - Last email preserved: $lastEmail');
    print('  - Marked as signed out');
    print('  - Device ID kept: ${await getDeviceId()}');
  }
  
  /// Get device authentication info for debugging
  Future<Map<String, dynamic>> getDeviceAuthInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await getDeviceId();

    return {
      'deviceId': deviceId,
      'lastUserEmail': prefs.getString(_keyLastUserEmail),
      'firstSignInTime': prefs.getInt(_keyFirstSignInTime),
      'isFirstUser': await isFirstUserOnDevice(),
      'isSignedOut': prefs.getBool(_keyIsSignedOut) ?? true,
    };
  }
  
  /// Reset all device data (for testing purposes)
  Future<void> resetDeviceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastUserEmail);
    await prefs.remove(_keyDeviceId);
    await prefs.remove(_keyFirstSignInTime);
    await prefs.remove(_keyIsSignedOut);
  }
}
