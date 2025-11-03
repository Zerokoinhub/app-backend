import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/controllers/user_controller.dart';
import 'package:zero_koin/controllers/user_stats_controller.dart';
import 'package:zero_koin/controllers/course_controller.dart'; // Import CourseController
import 'package:zero_koin/controllers/notification_controller.dart'; // Import NotificationController
import 'package:zero_koin/controllers/session_controller.dart'; // Import SessionController
import 'package:zero_koin/controller/language_controller.dart'; // Import LanguageController
import 'package:zero_koin/controllers/admob_controller.dart'; // Import AdMobController
import 'package:zero_koin/services/auth_service.dart';
import 'package:zero_koin/services/notification_service.dart';
import 'package:zero_koin/services/admob_service.dart';
import 'package:zero_koin/services/time_validation_service.dart';
import 'package:zero_koin/view/home_screen.dart';
import 'package:zero_koin/view/splash_screen.dart';
import 'firebase_options.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize().then((initializationStatus) {
    initializationStatus.adapterStatuses.forEach((key, value) {
      developer.log('Adapter status for $key: ${value.description}');
    });
  });
  // RequestConfiguration configuration = RequestConfiguration(
  //   testDeviceIds: ['YOUR_DEVICE_ID'],
  // );
  // MobileAds.instance.updateRequestConfiguration(configuration);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize AdMob
  await AdMobService.initialize();

  // Initialize AdMobController
  Get.put(AdMobController());

  // Initialize TimeValidationService first (required by SessionController)
  Get.put(TimeValidationService());

  // Initialize ThemeController
  Get.put(ThemeController());

  // Initialize AuthService
  Get.put(AuthService());

  // Initialize UserController
  Get.put(UserController());

  // Initialize LanguageController
  Get.put(LanguageController());

  // Initialize UserStatsController
  Get.put(UserStatsController());

  // Initialize CourseController
  Get.put(CourseController());

  // Initialize NotificationController
  Get.put(NotificationController());

  // Initialize NotificationService
  Get.put(NotificationService());
  Get.put(SessionController());

  // Set status bar to light content (white text/icons)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    // Notify NotificationService when first frame is rendered so it can
    // process any pending notification tap that launched the app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final notificationService = Get.find<NotificationService>();
        notificationService.onAppReady();
      } catch (e) {
        // ignore if service not available
      }
    });

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeController.lightTheme,
      darkTheme: themeController.darkTheme,
      themeMode: ThemeMode.system, // This will be overridden by Get.changeTheme
      home: const SplashScreen(),
    );
  }
}
