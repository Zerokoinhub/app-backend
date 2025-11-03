import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-4488050346002973/5068038939';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4488050346002973/5068038939'; // Use same ID or create iOS specific
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get learnAndEarnBannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-4488050346002973/5484640208';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4488050346002973/5484640208'; // Use same ID or create iOS specific
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get notificationBannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-4488050346002973/6225062141';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4488050346002973/6225062141'; // Use same ID or create iOS specific
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-4488050346002973/9374432685';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4488050346002973/9374432685'; // Use same ID or create iOS specific
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-4488050346002973/6824005550'; // Default to session 1 rewarded ad
    } else if (Platform.isIOS) {
      return 'ca-app-pub-4488050346002973/6824005550'; // Default to session 1 rewarded ad
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Session-specific rewarded ad unit IDs
  static String getSessionRewardedAdUnitId(int sessionNumber) {
    if (Platform.isAndroid) {
      switch (sessionNumber) {
        case 1:
          return 'ca-app-pub-4488050346002973/6824005550';
        case 2:
          return 'ca-app-pub-4488050346002973/7382694160';
        case 3:
          return 'ca-app-pub-4488050346002973/1879086040';
        case 4:
          return 'ca-app-pub-4488050346002973/4045798972';
        default:
          return 'ca-app-pub-4488050346002973/6824005550'; // Default to session 1
      }
    } else if (Platform.isIOS) {
      // Use same IDs for iOS or create iOS-specific ones
      switch (sessionNumber) {
        case 1:
          return 'ca-app-pub-4488050346002973/6824005550';
        case 2:
          return 'ca-app-pub-4488050346002973/7382694160';
        case 3:
          return 'ca-app-pub-4488050346002973/1879086040';
        case 4:
          return 'ca-app-pub-4488050346002973/4045798972';
        default:
          return 'ca-app-pub-4488050346002973/6824005550'; // Default to session 1
      }
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }
}
