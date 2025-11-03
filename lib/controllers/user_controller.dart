import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zero_koin/services/api_service.dart';
import 'package:zero_koin/services/notification_service.dart';
import 'package:zero_koin/controllers/transaction_controller.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  // Observable user data
  final Rx<Map<String, dynamic>> userData = Rx<Map<String, dynamic>>({});

  // Loading state
  final RxBool isLoading = false.obs;

  // Error state
  final RxString error = ''.obs;

  // Invite code (for easy access)
  final RxString inviteCode = ''.obs;

  // Recent amount (for easy access)
  final RxInt recentAmount = 0.obs;

  // Balance (for easy access)
  final RxInt balance = 0.obs;

  // Wallet addresses (for easy access)
  final RxString metamaskAddress = ''.obs;
  final RxString trustWalletAddress = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initial loading of user data
    _loadUserData();

    // Listen to auth state changes to reload data when user signs in
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData();
        // Clear transaction cache when user changes
        _clearTransactionCache();
      } else {
        // Clear user data when signed out
        userData.value = {};
        inviteCode.value = '';
        recentAmount.value = 0;
        balance.value = 0;
        metamaskAddress.value = '';
        trustWalletAddress.value = '';
        // Clear transaction cache when user signs out
        _clearTransactionCache();
      }
    });
  }

  // Helper method to clear transaction cache when user changes
  void _clearTransactionCache() {
    try {
      if (Get.isRegistered<TransactionController>()) {
        final transactionController = Get.find<TransactionController>();
        transactionController.clearCache();
      }
    } catch (e) {
      // Ignore errors if TransactionController is not registered
      print('TransactionController not found for cache clearing: $e');
    }
  }

  // Helper method to load user data with fallback
  Future<void> _loadUserData() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    try {
      // First try syncing to ensure we have the most up-to-date data
      final syncSuccess = await syncUserData();

      // If sync fails, try fetching the profile as a fallback
      if (!syncSuccess) {
        await fetchUserProfile();
      }

      // After successful user data loading, send FCM token to backend
      await _sendFCMTokenToBackend();
    } catch (e) {
      print('Error in _loadUserData: $e');
      error.value = 'Failed to load user data: ${e.toString()}';
    }
  }

  // Fetch user profile from the backend
  Future<void> fetchUserProfile() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return; // Not signed in
    }

    try {
      isLoading.value = true;
      error.value = '';

      final data = await ApiService.getUserProfile();

      if (data != null && data['user'] != null) {
        userData.value = data['user'];

        // Extract commonly used values for easy access
        inviteCode.value = data['user']['inviteCode'] ?? '';
        recentAmount.value = data['user']['recentAmount'] ?? 0;
        balance.value = data['user']['balance'] ?? 0;

        // Extract wallet addresses
        final walletAddresses = data['user']['walletAddresses'] ?? {};
        metamaskAddress.value = walletAddresses['metamask'] ?? '';
        trustWalletAddress.value = walletAddresses['trustWallet'] ?? '';

        print('User profile loaded: ${userData.value}');

        // Send FCM token to backend after successful profile fetch
        await _sendFCMTokenToBackend();
      } else {
        print('Profile data missing, trying to sync first...');
        await syncUserData();
      }
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      print('Error fetching user profile: $e');

      // If profile fetch fails (like 404), try syncing
      print('Attempting to sync user data after profile fetch failed');
      await syncUserData();
    } finally {
      isLoading.value = false;
    }
  }

  // Sync user data with the backend
  Future<bool> syncUserData() async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await ApiService.syncFirebaseUser();

      if (result != null && result['user'] != null) {
        // Extract user data directly from sync response
        userData.value = result['user'];
        inviteCode.value = result['user']['inviteCode'] ?? '';
        recentAmount.value = result['user']['recentAmount'] ?? 0;
        balance.value = result['user']['balance'] ?? 0;

        // Extract wallet addresses
        final walletAddresses = result['user']['walletAddresses'] ?? {};
        metamaskAddress.value = walletAddresses['metamask'] ?? '';
        trustWalletAddress.value = walletAddresses['trustWallet'] ?? '';

        print('User data synced successfully: ${userData.value}');

        // Send FCM token to backend after successful sync
        await _sendFCMTokenToBackend();

        return true;
      } else {
        error.value = 'Failed to sync user data';
        return false;
      }
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      print('Error syncing user data: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get user's display name
  String get name {
    return userData.value['name'] ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'User';
  }

  // Get user's email
  String get email {
    return userData.value['email'] ??
        FirebaseAuth.instance.currentUser?.email ??
        '';
  }

  // Get user's creation date
  String get createdAt {
    return userData.value['createdAt'] ?? '';
  }

  // Check if user data is loaded
  bool get isUserDataLoaded {
    return userData.value.isNotEmpty && inviteCode.value.isNotEmpty;
  }

  // Get user's Firebase UID
  String get firebaseUid {
    return userData.value['firebaseUid'] ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
  }

  // Get referrer's invite code
  String get referredBy {
    return userData.value['referredBy'] ?? '';
  }

  // Send FCM token to backend (private method)
  Future<void> _sendFCMTokenToBackend() async {
    try {
      final notificationService = Get.find<NotificationService>();
      await notificationService.sendFCMTokenToBackend();
    } catch (e) {
      print('Error sending FCM token to backend: $e');
    }
  }

  // Public method to manually trigger FCM token sending (for testing)
  Future<void> sendFCMTokenToBackend() async {
    await _sendFCMTokenToBackend();
  }

  // Update FCM token
  Future<bool> updateFCMToken(String fcmToken, String? platform) async {
    try {
      final result = await ApiService.updateFCMToken(fcmToken, platform);
      if (result != null && result['message'] != null) {
        print('FCM token updated successfully: ${result['message']}');
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }

  // Update wallet address
  Future<bool> updateWalletAddress(String walletType, String address) async {
    try {
      print(
        '🔄 UserController: Starting wallet address update for $walletType with address: $address',
      );
      isLoading.value = true;
      error.value = '';

      final result = await ApiService.updateWalletAddress(walletType, address);
      print('📡 UserController: API response received: $result');

      if (result != null) {
        try {
          // Update local state safely
          if (walletType == 'metamask') {
            metamaskAddress.value = address;
            print(
              '📱 UserController: Updated metamaskAddress to: ${metamaskAddress.value}',
            );
          } else if (walletType == 'trustWallet') {
            trustWalletAddress.value = address;
            print(
              '📱 UserController: Updated trustWalletAddress to: ${trustWalletAddress.value}',
            );
          }

          // Update userData with new wallet addresses
          final currentWalletAddresses =
              userData.value['walletAddresses'] ?? {};
          currentWalletAddresses[walletType] = address;
          userData.value = Map<String, dynamic>.from(userData.value);
          userData.value['walletAddresses'] = currentWalletAddresses;
          userData.refresh(); // Notify observers

          print(
            '✅ UserController: Wallet address updated locally: $walletType = $address',
          );
          print(
            '📊 UserController: Current userData walletAddresses: ${userData.value['walletAddresses']}',
          );
          return true;
        } catch (stateError) {
          print('⚠️ UserController: Error updating local state: $stateError');
          // Even if local state update fails, the API call succeeded
          return true;
        }
      } else {
        print('❌ UserController: API returned null result');
        error.value = 'Failed to update wallet address';
        return false;
      }
    } catch (e) {
      print('💥 UserController: Exception during wallet address update: $e');
      error.value = 'Error: ${e.toString()}';
      return false;
    } finally {
      try {
        isLoading.value = false;
      } catch (e) {
        print('⚠️ UserController: Error setting loading state: $e');
      }
    }
  }

  // Get wallet address by type
  String getWalletAddress(String walletType) {
    String address = '';
    if (walletType == 'metamask') {
      address = metamaskAddress.value;
    } else if (walletType == 'trustWallet') {
      address = trustWalletAddress.value;
    }

    print(
      '🔍 UserController: getWalletAddress($walletType) returning: "$address"',
    );
    print(
      '📊 UserController: Current metamaskAddress: "${metamaskAddress.value}"',
    );
    print(
      '📊 UserController: Current trustWalletAddress: "${trustWalletAddress.value}"',
    );
    print(
      '📊 UserController: userData walletAddresses: ${userData.value['walletAddresses']}',
    );

    return address;
  }

  // Check if wallet is connected
  bool isWalletConnected(String walletType) {
    return getWalletAddress(walletType).isNotEmpty;
  }

  // Update user balance
  Future<bool> updateBalance(int amount) async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await ApiService.updateUserBalance(amount);

      if (result != null) {
        // Update local balance
        final newBalance = result['newBalance'] ?? 0;
        balance.value = newBalance;

        // Update userData
        userData.value['balance'] = newBalance;
        userData.refresh(); // Notify observers

        print(
          '✅ Balance updated successfully: +$amount, new balance: $newBalance',
        );
        return true;
      } else {
        error.value = 'Failed to update balance';
        return false;
      }
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      print('Error updating balance: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Withdraw coins
  Future<bool> withdrawCoins(int amount, String walletAddress) async {
    try {
      isLoading.value = true;
      error.value = '';

      final result = await ApiService.withdrawCoins(amount, walletAddress);

      if (result != null) {
        // Update local balance by subtracting the withdrawal amount
        final currentBalance = balance.value;
        final newBalance = currentBalance - amount;
        balance.value = newBalance;

        // Update userData
        userData.value['balance'] = newBalance;
        userData.refresh(); // Notify observers

        print('✅ Withdrawal successful: -$amount, new balance: $newBalance');
        return true;
      } else {
        error.value = 'Failed to process withdrawal';
        return false;
      }
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      print('Error processing withdrawal: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Public method to refresh user data
  Future<void> refreshUserData() async {
    await _loadUserData();
  }
}
