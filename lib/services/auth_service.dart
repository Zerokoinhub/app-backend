import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'device_auth_service.dart';
import 'time_validation_service.dart';
import '../widgets/device_auth_warning_dialog.dart';
import 'dart:developer' as developer;

class AuthService extends GetxController {
  static AuthService get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Remove serverClientId for Android - let it use the one from google-services.json
    // serverClientId is mainly needed for iOS
  );

  // Observable user state
  Rxn<User> user = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    user.bindStream(_auth.authStateChanges());
  }

  // Check if user is signed in
  bool get isSignedIn => user.value != null;

  // Get current user
  User? get currentUser => user.value;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        Get.back(); // Close loading dialog
        return null;
      }

      // Check device authentication before proceeding
      final deviceAuthService = DeviceAuthService.instance;
      final userEmail = googleUser.email;

      // Debug: Print device auth info
      if (Get.isLogEnable) {
        final debugInfo = await deviceAuthService.getDeviceAuthInfo();
        developer.log('🔍 Device Auth Debug Info: $debugInfo');
        developer.log('🔍 Current user trying to sign in: $userEmail');
        developer.log(
          '🔍 Is different user: ${await deviceAuthService.isDifferentUser(userEmail)}',
        );
      }

      // Check if this is a different user trying to sign in
      if (await deviceAuthService.isDifferentUser(userEmail)) {
        Get.back(); // Close loading dialog

        final lastUserEmail = await deviceAuthService.getLastUserEmail();

        if (Get.isLogEnable) {
          developer.log(
            '🚨 Different user detected! Last: $lastUserEmail, New: $userEmail',
          );
        }

        // Show access denied dialog
        await DeviceAuthWarningDialog.show();

        // Sign out from Google and return null to prevent sign-in
        await _googleSignIn.signOut();
        if (Get.isLogEnable) {
          developer.log('❌ Different user blocked from signing in');
        }
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Update device authentication data
      await deviceAuthService.setCurrentUser(userEmail);

      // Sync user data to MongoDB
      await _syncUserToMongoDB();

      // Retry time validation now that user is authenticated
      try {
        final timeValidationService = Get.find<TimeValidationService>();
        await timeValidationService.retryTimeValidation();
        if (Get.isLogEnable) {
          print('🕐 Time validation retried after successful sign-in');
        }
      } catch (e) {
        if (Get.isLogEnable) {
          print('⚠️ Error retrying time validation after sign-in: $e');
        }
      }

      Get.back(); // Close loading dialog

      // Show success message
      Get.snackbar(
        'Success',
        'Successfully signed in with Google!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF086F8A),
        colorText: Colors.white,
      );

      return userCredential;
    } catch (e) {
      Get.back(); // Close loading dialog if open

      String errorMessage = 'Failed to sign in with Google';

      // Provide more specific error messages
      if (e.toString().contains('network_error')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMessage = 'Sign-in was canceled.';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage = 'Google Sign-in failed. Please try again.';
      } else if (e.toString().contains(
        'account-exists-with-different-credential',
      )) {
        errorMessage =
            'An account already exists with a different sign-in method.';
      }

      // Show error message
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      // Log detailed error for debugging
      if (Get.isLogEnable) {
        print('🚨 Google Sign-In Error Details:');
        print('   Error: $e');
        print('   Error Type: ${e.runtimeType}');
        if (e is FirebaseAuthException) {
          print('   Firebase Error Code: ${e.code}');
          print('   Firebase Error Message: ${e.message}');
        }
      }
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Mark user as signed out but keep device association
      final deviceAuthService = DeviceAuthService.instance;
      await deviceAuthService.clearDeviceAuth();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Firebase
      await _auth.signOut();

      Get.back(); // Close loading dialog

      // Show success message
      Get.snackbar(
        'Success',
        'Successfully signed out!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF086F8A),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back(); // Close loading dialog if open

      // Show error message
      Get.snackbar(
        'Error',
        'Failed to sign out: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        colorText: Colors.white,
      );

      // Log error for debugging
      if (Get.isLogEnable) {
        print('Sign Out Error: $e');
      }
    }
  }

  // Get user display name
  String? get userDisplayName => currentUser?.displayName;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user photo URL
  String? get userPhotoURL => currentUser?.photoURL;

  // Get user ID
  String? get userId => currentUser?.uid;

  // Get formatted user creation date
  Future<String?> get userCreationDate async {
    try {
      final profile = await ApiService.getUserProfile();
      if (profile != null && profile['createdAt'] != null) {
        final createdAt = DateTime.parse(profile['createdAt']);
        final formatter = DateFormat('dd MMM yyyy');
        return formatter.format(createdAt);
      }
      // Fallback to Firebase metadata if MongoDB data is not available
      final creationTime = currentUser?.metadata.creationTime;
      if (creationTime == null) return null;

      final formatter = DateFormat('dd MMM yyyy');
      return formatter.format(creationTime);
    } catch (e) {
      if (Get.isLogEnable) {
        print('Error getting user creation date: $e');
      }
      // Fallback to Firebase metadata if there's an error
      final creationTime = currentUser?.metadata.creationTime;
      if (creationTime == null) return null;

      final formatter = DateFormat('dd MMM yyyy');
      return formatter.format(creationTime);
    }
  }

  // Get formatted last sign-in time
  String? get userLastSignInTime {
    final lastSignInTime = currentUser?.metadata.lastSignInTime;
    if (lastSignInTime == null) return null;

    final now = DateTime.now();
    final difference = now.difference(lastSignInTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      final formatter = DateFormat('dd MMM yyyy');
      return formatter.format(lastSignInTime);
    }
  }

  // Reauthenticate user (useful for sensitive operations)
  Future<bool> reauthenticateWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await currentUser?.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      // Log error for debugging
      if (Get.isLogEnable) {
        print('Reauthentication Error: $e');
      }
      return false;
    }
  }

  // Sync user data to MongoDB
  Future<void> _syncUserToMongoDB() async {
    try {
      final result = await ApiService.syncFirebaseUser();
      if (result != null) {
        if (Get.isLogEnable) {
          print('User synced to MongoDB: ${result['message']}');
        }
      } else {
        if (Get.isLogEnable) {
          print('Failed to sync user to MongoDB');
        }
      }
    } catch (e) {
      if (Get.isLogEnable) {
        print('Error syncing user to MongoDB: $e');
      }
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    try {
      // Reauthenticate first for security
      final reauthenticated = await reauthenticateWithGoogle();

      if (!reauthenticated) {
        Get.snackbar(
          'Error',
          'Reauthentication failed. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
        );
        return false;
      }

      // Delete the user account
      await currentUser?.delete();

      // Sign out from Google as well
      await _googleSignIn.signOut();

      Get.snackbar(
        'Success',
        'Account deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete account: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );

      // Log error for debugging
      if (Get.isLogEnable) {
        print('Delete Account Error: $e');
      }
      return false;
    }
  }

  // Get device authentication info for debugging
  Future<Map<String, dynamic>> getDeviceAuthInfo() async {
    final deviceAuthService = DeviceAuthService.instance;
    return await deviceAuthService.getDeviceAuthInfo();
  }

  // Reset device authentication data (for testing purposes)
  Future<void> resetDeviceAuth() async {
    final deviceAuthService = DeviceAuthService.instance;
    await deviceAuthService.resetDeviceData();
  }
}
