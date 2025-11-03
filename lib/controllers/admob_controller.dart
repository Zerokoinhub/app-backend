import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:zero_koin/services/admob_service.dart';
import 'dart:developer' as developer;

class AdMobController extends GetxController {
  Rx<BannerAd?> bannerAd = Rx<BannerAd?>(null);
  BannerAd? learnAndEarnBannerAd;
  BannerAd? notificationBannerAd;
  InterstitialAd? interstitialAd;
  RewardedAd? rewardedAd;

  final RxBool isBannerAdReady = false.obs;
  final RxBool isLearnAndEarnBannerAdReady = false.obs;
  final RxBool isNotificationBannerAdReady = false.obs;
  final RxBool isInterstitialAdReady = false.obs;
  final RxBool isRewardedAdReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    _createBannerAd();
    _createLearnAndEarnBannerAd();
    _createNotificationBannerAd();
  }

  @override
  void onClose() {
    learnAndEarnBannerAd?.dispose();
    notificationBannerAd?.dispose();
    interstitialAd?.dispose();
    rewardedAd?.dispose();
    super.onClose();
  }

  void _createBannerAd() {
    try {
      final ad = BannerAd(
        adUnitId: AdMobService.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            bannerAd.value = ad as BannerAd;
            //Check the mediation adapter that filled this add
            developer.log(
              "Banner ad loaded from ${ad.responseInfo?.mediationAdapterClassName}",
            );
            isBannerAdReady.value = true;
            developer.log("✅ Banner ad loaded");
          },
          onAdFailedToLoad: (ad, err) {
            developer.log("❌ Banner ad failed: ${err.message}");
            print('Failed to load a banner ad: ${err.message}');
            ad.dispose();

            isBannerAdReady.value = false;
          },
        ),
      );

      ad.load();
    } catch (e) {
      developer.log("❌ Banner ad failed: $e");
      print('Failed to load a banner ad: $e');
      isBannerAdReady.value = false;
    }
  }

  void _createLearnAndEarnBannerAd() {
    learnAndEarnBannerAd = BannerAd(
      adUnitId: AdMobService.learnAndEarnBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isLearnAndEarnBannerAdReady.value = true;
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a learn and earn banner ad: ${err.message}');
          isLearnAndEarnBannerAdReady.value =
              false; // Set to true to prevent blocking splash screen
          ad.dispose();
        },
      ),
    );

    learnAndEarnBannerAd!.load();
  }

  void _createNotificationBannerAd() {
    notificationBannerAd = BannerAd(
      adUnitId: AdMobService.notificationBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isNotificationBannerAdReady.value = true;
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a notification banner ad: ${err.message}');
          isNotificationBannerAdReady.value =
              false; // Set to true to prevent blocking splash screen
          ad.dispose();
        },
      ),
    );

    notificationBannerAd!.load();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdMobService.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          developer.log(
            "✅ Interstitial ad loaded from ${ad.responseInfo?.mediationAdapterClassName}",
          );

          isInterstitialAdReady.value = true;
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
          isInterstitialAdReady.value = false;
        },
      ),
    );
  }

  void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: AdMobService.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          isRewardedAdReady.value = true;
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
          isRewardedAdReady.value = false;
        },
      ),
    );
  }

  // Create session-specific rewarded ad
  void createSessionRewardedAd(int sessionNumber) {
    RewardedAd.load(
      adUnitId: AdMobService.getSessionRewardedAdUnitId(sessionNumber),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          isRewardedAdReady.value = true;
          print('Session $sessionNumber rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (err) {
          print(
            'Failed to load session $sessionNumber rewarded ad: ${err.message}',
          );
          isRewardedAdReady.value = false;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (isInterstitialAdReady.value && interstitialAd != null) {
      interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          print('Failed to show interstitial ad: ${err.message}');
          ad.dispose();
          _createInterstitialAd();
        },
      );
      interstitialAd!.show();
      interstitialAd = null;
      isInterstitialAdReady.value = false;
    }
  }

  void showRewardedAd({Function? onRewarded}) {
    if (isRewardedAdReady.value && rewardedAd != null) {
      rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          // Don't automatically reload ad after showing - let the caller decide
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          print('Failed to show rewarded ad: ${err.message}');
          ad.dispose();
          // Don't automatically reload ad after failure - let the caller decide
        },
      );

      rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
          if (onRewarded != null) {
            onRewarded();
          }
        },
      );
      rewardedAd = null;
      isRewardedAdReady.value = false;
    }
  }

  void loadInterstitialAd() {
    if (!isInterstitialAdReady.value) {
      _createInterstitialAd();
    }
  }

  void loadRewardedAd() {
    if (!isRewardedAdReady.value) {
      _createRewardedAd();
    }
  }
}
