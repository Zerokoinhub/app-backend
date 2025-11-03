import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:zero_koin/view/user_registeration_screen.dart';
import 'package:zero_koin/view/bottom_bar.dart';
import 'package:zero_koin/services/auth_service.dart';
import 'package:zero_koin/controllers/admob_controller.dart';
import 'package:zero_koin/services/time_validation_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _zoomController;
  late Animation<double> _glowAnimation;
  late Animation<double> _zoomAnimation;
  late Animation<double> _glowIntensityAnimation;
  late AdMobController _adMobController;

  @override
  void initState() {
    super.initState();

    // Get the existing AdMobController instance
    _adMobController = Get.find<AdMobController>();

    // Enhanced glow animation - matches HTML CSS glow effect
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 5.0, end: 20.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _glowIntensityAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Enhanced zoom animation - matches HTML CSS zoom effect
    _zoomController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut),
    );

    // Wait for all banner ads to load before navigating
    _waitForAdsAndNavigate();
  }

  void _waitForAdsAndNavigate() {
    // Set minimum splash screen duration (3 seconds)
    final minimumDuration = Future.delayed(const Duration(seconds: 3));

    // Wait for all banner ads to load
    final adsLoaded = _waitForAllAdsToLoad();

    // Initialize and wait for time validation
    final timeValidationReady = _initializeTimeValidation();

    // Add absolute maximum timeout as a safety net (20 seconds total)
    final maxTimeout = Future.delayed(const Duration(seconds: 20)).then((_) {
      print('⚠️ Maximum splash screen timeout reached - forcing navigation');
    });

    // Wait for minimum duration, ads, and time validation, or maximum timeout
    Future.any([
      Future.wait([minimumDuration, adsLoaded, timeValidationReady]),
      maxTimeout,
    ]).then((_) {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _waitForAllAdsToLoad() async {
    try {
      await Future.wait([
        _adMobController.isBannerAdReady.stream.firstWhere((ready) => ready),
        _adMobController.isLearnAndEarnBannerAdReady.stream.firstWhere(
          (ready) => ready,
        ),
        _adMobController.isNotificationBannerAdReady.stream.firstWhere(
          (ready) => ready,
        ),
      ]).timeout(const Duration(seconds: 10));
      print("✅ All ads loaded");
    } catch (_) {
      print("⚠️ Ads loading timeout, proceeding anyway");
    }
  }

  Future<void> _initializeTimeValidation() async {
    try {
      // Get the TimeValidationService instance
      final timeValidationService = Get.find<TimeValidationService>();

      // Wait for initialization with timeout
      await timeValidationService.waitForInitialization().timeout(
        const Duration(seconds: 5), // Reduced timeout to 5 seconds
        onTimeout: () {
          print(
            '⚠️ Time validation initialization timeout in splash screen - proceeding anyway',
          );
        },
      );
      print('✅ Time validation initialized successfully in splash screen');
    } catch (e) {
      print(
        '⚠️ Error initializing time validation in splash screen: $e - proceeding anyway',
      );
      // Don't rethrow the error - let the app continue
    }
  }

  void _checkAuthAndNavigate() async {
    final authService = AuthService.instance;

    if (authService.isSignedIn) {
      // User is already signed in, retry time validation with authenticated user
      try {
        final timeValidationService = Get.find<TimeValidationService>();
        await timeValidationService.retryTimeValidation();
        print('Time validation retried after authentication check');
      } catch (e) {
        print('Error retrying time validation: $e');
      }

      // Go to home screen
      Get.offAll(() => const BottomBar());
    } else {
      // User is not signed in, go to registration screen
      Get.offAll(() => const UserRegisterationScreen());
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar content to white
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/Background.jpg', fit: BoxFit.cover),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _glowAnimation,
                _zoomAnimation,
                _glowIntensityAnimation,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _zoomAnimation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glowing background circle - like your reference
                      Container(
                        width: 200 + _glowAnimation.value * 4,
                        height: 200 + _glowAnimation.value * 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(
                                alpha: _glowIntensityAnimation.value * 0.3,
                              ),
                              Colors.white.withValues(
                                alpha: _glowIntensityAnimation.value * 0.15,
                              ),
                              Colors.white.withValues(
                                alpha: _glowIntensityAnimation.value * 0.05,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                      // Additional outer glow for more intensity
                      Container(
                        width: 300 + _glowAnimation.value * 6,
                        height: 300 + _glowAnimation.value * 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(
                                alpha: _glowIntensityAnimation.value * 0.1,
                              ),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                      // The actual logo on top
                      Image.asset(
                        'assets/bluelogo.png',
                        width: 150,
                        height: 150,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Copyright text at the bottom
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '© 2024 - 2025 Zero Koin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap Learn & Earn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
