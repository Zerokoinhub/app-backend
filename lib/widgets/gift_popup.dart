import 'package:flutter/material.dart';
import 'package:zero_koin/constant/app_colors.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/admob_controller.dart';
import 'dart:ui';
import 'package:zero_koin/widgets/timer_popup.dart';

class GiftPopup extends StatefulWidget {
  final int sessionNumber;
  const GiftPopup({super.key, required this.sessionNumber});

  @override
  State<GiftPopup> createState() => _GiftPopupState();
}

class _GiftPopupState extends State<GiftPopup> {
  final AdMobController _adMobController = Get.find<AdMobController>();
  bool _isAdLoading = true;
  bool _adWatched = false;

  @override
  void initState() {
    super.initState();
    _loadSessionAd();
  }

  void _loadSessionAd() {
    // Load session-specific rewarded ad
    _adMobController.createSessionRewardedAd(widget.sessionNumber);

    // Listen for ad ready state
    ever(_adMobController.isRewardedAdReady, (isReady) {
      if (mounted && isReady) {
        setState(() {
          _isAdLoading = false;
        });
        // Automatically show the ad when it's ready
        _showRewardedAd();
      }
    });
  }

  void _showRewardedAd() {
    _adMobController.showRewardedAd(
      onRewarded: () {
        // Ad was watched successfully
        setState(() {
          _adWatched = true;
        });
        // Close gift popup and show timer popup
        _proceedToTimer();
      },
    );
  }

  void _proceedToTimer() {
    if (mounted) {
      Get.back(); // Close gift popup
      Get.dialog(
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: TimerPopup(sessionIndex: widget.sessionNumber),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive calculations
    final isSmallDeviceHeight =
        screenHeight < 650; // Adjusted threshold for small height
    final containerWidth = screenWidth * 0.85;
    // Adjusted padding and inner padding to be more responsive to height on small devices
    final containerPadding =
        isSmallDeviceHeight
            ? screenWidth * 0.03 + screenHeight * 0.01
            : screenWidth * 0.05;
    final innerPadding =
        isSmallDeviceHeight
            ? screenWidth * 0.03 + screenHeight * 0.005
            : screenWidth * 0.04;
    // Adjusted image size to be more responsive to height on small devices
    final imageSize =
        isSmallDeviceHeight
            ? screenWidth * 0.20 + screenHeight * 0.02
            : screenWidth * 0.25;
    // Adjusted font sizes to be more responsive to height on small devices
    final titleFontSize =
        isSmallDeviceHeight
            ? screenWidth * 0.04 + screenHeight * 0.005
            : screenWidth * 0.045;
    final subtitleFontSize =
        isSmallDeviceHeight
            ? screenWidth * 0.025 + screenHeight * 0.003
            : screenWidth * 0.03;
    // Adjusted vertical spacing to be more responsive to height on small devices
    final verticalSpacing =
        isSmallDeviceHeight
            ? screenHeight * 0.015
            : screenHeight * 0.02; // Slightly increased spacing for better look
    final closeButtonSize =
        isSmallDeviceHeight
            ? screenWidth * 0.045
            : screenWidth * 0.05; // Further reduced close button size

    // Use flexible constraints to prevent overflow
    final maxContainerHeight =
        isSmallDeviceHeight ? screenHeight * 0.6 : screenHeight * 0.5;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: containerWidth,
        maxHeight: maxContainerHeight,
        minHeight: screenHeight * 0.25,
      ),
      child: Container(
        width: containerWidth,
        padding: EdgeInsets.all(containerPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            screenWidth * 0.05,
          ), // Responsive border radius
        ),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: innerPadding,
                    vertical: verticalSpacing,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image(
                        image: AssetImage('assets/gift_background.png'),
                        height: imageSize,
                        width: imageSize,
                      ),
                      SizedBox(height: verticalSpacing),
                      Text(
                        'Session ${widget.sessionNumber}\nWatch an Ad to Continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleFontSize, // Responsive font size
                          fontWeight: FontWeight.w900,
                          color: AppColors.blue,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                      Text(
                        _isAdLoading
                            ? 'Loading ad...\nPlease wait'
                            : _adWatched
                            ? 'Ad completed!\nStarting session...'
                            : 'Ad ready!\nWatch to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subtitleFontSize, // Responsive font size
                          color: Colors.black54,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (_isAdLoading)
                        Padding(
                          padding: EdgeInsets.only(top: verticalSpacing),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: screenWidth * 0.02, // Responsive positioning
              top: screenHeight * 0.01, // Responsive positioning
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: closeButtonSize, // Responsive close icon size
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
