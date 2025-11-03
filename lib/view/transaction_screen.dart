import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/controllers/admob_controller.dart';
import 'package:zero_koin/controllers/transaction_controller.dart';
import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/my_drawer.dart';
import 'dart:developer' as developer;

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final AdMobController _adMobController = Get.find<AdMobController>();
  late final TransactionController _transactionController;

  @override
  void initState() {
    super.initState();
    // _loadtestDeviceAds();

    // Initialize transaction controller - use Get.find if exists, otherwise create new
    if (Get.isRegistered<TransactionController>()) {
      _transactionController = Get.find<TransactionController>();
      // Clear any cached data from previous user sessions
      _transactionController.clearCache();
    } else {
      _transactionController = Get.put(TransactionController());
    }

    // Load fresh transaction data for current user
    _transactionController.fetchTransactions();

    // Load interstitial ad when screen initializes
    _adMobController.loadInterstitialAd();

    // Wait for the screen to build, then wait for ad to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _waitAndShowAd();
    });
  }

  // Future<void> _loadtestDeviceAds() async {
  //   RequestConfiguration requestConfiguration = RequestConfiguration(
  //     testDeviceIds: ['7BBFE05555556F981578D2707A0885E3'],
  //   );
  //   await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

  //   developer.log("✅ Test device ads loaded");
  // }

  /// 🧠 Opens the Ad Inspector and listens for errors
  // void openAdInspector() {
  //   MobileAds.instance.openAdInspector((error) {
  //     if (error != null) {
  //       developer.log("❌ Failed to open Ad Inspector: ${error.message}");
  //     } else {
  //       developer.log("✅ Ad Inspector closed successfully (no errors)");
  //     }
  //   });
  // }

  void _waitAndShowAd() {
    // Check if ad is ready, if not wait and check again
    if (_adMobController.isInterstitialAdReady.value) {
      _adMobController.showInterstitialAd();
    } else {
      // Wait 500ms and check again, repeat until ad is ready or timeout
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _waitAndShowAd();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final ThemeController themeController = Get.find<ThemeController>();
    return Scaffold(
      drawer: MyDrawer(),
      backgroundColor: themeController.backgroundColor,
      body: Stack(
        children: [
          Image.asset(
            'assets/Background.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Container(
            color: Colors.black.withOpacity(0.35),
            height: double.infinity,
            width: double.infinity,
          ),
          Column(
            children: [
              AppBarContainer(
                color: Colors.black.withOpacity(0.6),
                showTotalPosition: false,
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Transactions",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // ElevatedButton(
              //   onPressed: () {
              //     openAdInspector();
              //   },
              //   child: const Text('Open Ad Inspector'),
              // ),
              SizedBox(height: 32),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: themeController.contentBackgroundColor,
                  ),
                  child: Obx(() {
                    if (_transactionController.isLoading.value) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0682A2),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading transactions...',
                              style: TextStyle(
                                color: themeController.subtitleColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (_transactionController.error.value.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading transactions',
                              style: TextStyle(
                                color: themeController.subtitleColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _transactionController.error.value,
                              style: TextStyle(
                                color: themeController.subtitleColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _transactionController.refreshTransactions();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0682A2),
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!_transactionController.hasTransactions) {
                      return Column(
                        children: [
                          const SizedBox(height: 48),
                          SizedBox(
                            height: 120,
                            child: Image.asset(
                              "assets/oops.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Oops!",
                            style: TextStyle(
                              fontSize: 28,
                              color: themeController.subtitleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Nothing great ever come that easy",
                            style: TextStyle(
                              fontSize: 16,
                              color: themeController.subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _transactionController.refreshTransactions,
                      color: Color(0xFF0682A2),
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _transactionController.transactions.length,
                        itemBuilder: (context, index) {
                          final transaction =
                              _transactionController.transactions[index];
                          return _buildTransactionCard(
                            transaction,
                            themeController,
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> transaction,
    ThemeController themeController,
  ) {
    final userName = transaction['userName'] ?? 'Unknown User';
    final amount = transaction['amount'] ?? 0;
    final date = transaction['date'] ?? '';
    final status = transaction['status'] ?? 'pending';
    final formattedDate = _transactionController.getFormattedDate(date);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeController.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Transaction icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFF0682A2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.arrow_upward, color: Color(0xFF0682A2), size: 24),
          ),
          SizedBox(width: 16),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawal',
                  style: TextStyle(
                    color: themeController.subtitleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'User: $userName',
                  style: TextStyle(
                    color: themeController.subtitleColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Date: $formattedDate',
                  style: TextStyle(
                    color: themeController.subtitleColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-$amount',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'ZeroKoin',
                style: TextStyle(
                  color: themeController.subtitleColor.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
