import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zero_koin/services/api_service.dart';

class TransactionController extends GetxController {
  static TransactionController get instance => Get.find();

  // Observable transaction data
  final RxList<Map<String, dynamic>> transactions =
      <Map<String, dynamic>>[].obs;

  // Loading state
  final RxBool isLoading = false.obs;

  // Error state
  final RxString error = ''.obs;

  // Note: onInit removed to avoid auto-loading transactions
  // fetchTransactions will be called explicitly when needed

  // Fetch withdrawal transactions from the backend
  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Debug: Check current Firebase user
      final currentUser = FirebaseAuth.instance.currentUser;
      print(
        '🔍 DEBUG: Current Firebase user: ${currentUser?.email} (UID: ${currentUser?.uid})',
      );

      final result = await ApiService.getWithdrawalTransactions();

      if (result != null && result['transactions'] != null) {
        final List<dynamic> transactionList = result['transactions'];

        // Convert to List<Map<String, dynamic>> and sort by date (newest first)
        transactions.value =
            transactionList
                .map((transaction) => Map<String, dynamic>.from(transaction))
                .toList();

        // Sort by date (newest first)
        transactions.sort((a, b) {
          final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });

        print(
          '✅ Transactions loaded successfully: ${transactions.length} transactions',
        );
      } else {
        error.value = 'Failed to load transactions';
        transactions.clear();
      }
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      print('Error fetching transactions: $e');
      transactions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Clear cached data and fetch fresh transactions
  Future<void> refreshTransactions() async {
    transactions.clear();
    error.value = '';
    await fetchTransactions();
  }

  // Clear all cached data (useful when user switches accounts)
  void clearCache() {
    transactions.clear();
    error.value = '';
    isLoading.value = false;
  }

  // Get formatted date string
  String getFormattedDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Check if there are any transactions
  bool get hasTransactions => transactions.isNotEmpty;
}
