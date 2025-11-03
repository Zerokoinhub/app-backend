import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/controllers/session_controller.dart';
import 'package:zero_koin/services/time_validation_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePageWidgets extends StatelessWidget {
  const HomePageWidgets({
    super.key,
    required this.title,

    required this.subtitle,
    required this.imageURL,

    required this.buttonText,
    required this.color,
    required this.buttonImage,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String imageURL;
  final String buttonImage;
  final String buttonText;
  final Color color;
  final VoidCallback onPressed;

  // Method to get the display text for the button
  String _getButtonDisplayText() {
    // Only show timer for the start button (identified by buttonText "Start")
    if (buttonText == "Start") {
      try {
        final sessionController = Get.find<SessionController>();
        final timeValidationService = Get.find<TimeValidationService>();

        // Check if time validation service is still initializing
        if (!timeValidationService.isInitialized.value) {
          return "Time Sync...";
        }

        // Check if time validation is failing
        if (!timeValidationService.isTimeValid.value) {
          return "Time Sync...";
        }

        // Check if there are any active countdown timers
        if (sessionController.countdownTimers.isNotEmpty) {
          // Get the first active countdown timer
          final firstActiveTimer =
              sessionController.countdownTimers.values.first;
          return sessionController.formatCountdown(firstActiveTimer);
        }
      } catch (e) {
        // If controllers are not found, show sync status
        return "Time Sync...";
      }
    }

    // Return original button text for all other cases
    return buttonText;
  }

  // Method to check if timer is active for the start button
  bool _isTimerActive() {
    if (buttonText == "Start") {
      try {
        final sessionController = Get.find<SessionController>();
        final timeValidationService = Get.find<TimeValidationService>();

        // Consider timer active if time validation is not ready or if there are countdown timers
        return !timeValidationService.isInitialized.value ||
            !timeValidationService.isTimeValid.value ||
            sessionController.countdownTimers.isNotEmpty;
      } catch (e) {
        // If controllers are not found, consider timer active (show progress popup)
        return true;
      }
    }
    return false;
  }

  // Method to check if button should be disabled
  bool _isButtonDisabled() {
    if (buttonText == "Start") {
      try {
        final timeValidationService = Get.find<TimeValidationService>();

        // Disable button if time validation is not ready or time is invalid
        return !timeValidationService.isInitialized.value ||
            !timeValidationService.isTimeValid.value;
      } catch (e) {
        // If service not found, disable button for safety
        return true;
      }
    }
    return false;
  }

  // Method to get the appropriate icon for the button
  Widget _getButtonIcon(double screenWidth) {
    if (buttonText == "Start") {
      try {
        final timeValidationService = Get.find<TimeValidationService>();
        final sessionController = Get.find<SessionController>();

        // Show sync icon if time validation is not ready or time is invalid
        if (!timeValidationService.isInitialized.value ||
            !timeValidationService.isTimeValid.value) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 1),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * 3.14159, // Full rotation
                child: Icon(
                  Icons.sync,
                  color: Colors.white,
                  size: screenWidth * 0.04,
                ),
              );
            },
          );
        }

        // Show timer icon if there are active countdown timers
        if (sessionController.countdownTimers.isNotEmpty) {
          return Icon(
            Icons.timer,
            color: Colors.white,
            size: screenWidth * 0.04,
          );
        }
      } catch (e) {
        // If controllers not found, show animated sync icon
        return TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 2 * 3.14159, // Full rotation
              child: Icon(
                Icons.sync,
                color: Colors.white,
                size: screenWidth * 0.04,
              ),
            );
          },
        );
      }
    }

    // Default icon for other buttons or when everything is ready
    return buttonImage.toLowerCase().endsWith('.svg')
        ? SvgPicture.asset(buttonImage, fit: BoxFit.contain)
        : Image.asset(buttonImage);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final ThemeController themeController = Get.find<ThemeController>();
    return Obx(
      () => Container(
        width: double.infinity,
        height: screenHeight * 0.09, // Adjusted height for responsiveness
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: themeController.borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8, // Further reduced padding
            vertical: 6, // Further reduced padding
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: screenWidth * 0.13, // Further reduced width
                height: screenHeight * 0.06, // Further reduced height
                child:
                    imageURL.toLowerCase().endsWith('.svg')
                        ? SvgPicture.asset(imageURL, fit: BoxFit.contain)
                        : Image.asset(imageURL),
              ),
              SizedBox(width: screenWidth * 0.03), // Further reduced gap
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenHeight * 0.018,
                          color: themeController.textColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 1), // Further reduced gap
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            subtitle == '600'
                                ? themeController.textColor
                                : themeController.subtitleColor,
                        fontSize:
                            subtitle == '600'
                                ? screenHeight * 0.017
                                : screenHeight * 0.012,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.03), // Further reduced gap
              SizedBox(
                width: screenWidth * 0.28, // Further reduced width
                height: screenHeight * 0.05, // Further reduced height
                child: ElevatedButton(
                  onPressed: _isButtonDisabled() ? null : onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isButtonDisabled() ? Colors.grey : color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10.0,
                      ), // Adjusted border radius
                    ),
                    padding: EdgeInsets.all(
                      screenWidth * 0.012,
                    ), // Further reduced padding
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width:
                            buttonImage.contains('solar_play')
                                ? screenWidth *
                                    0.03 // Smaller size for play button
                                : screenWidth *
                                    0.05, // Larger size for invite button
                        height:
                            buttonImage.contains('solar_play')
                                ? screenHeight *
                                    0.018 // Smaller size for play button
                                : screenHeight *
                                    0.025, // Larger size for invite button
                        child: _getButtonIcon(screenWidth),
                      ),
                      SizedBox(
                        width:
                            _isTimerActive()
                                ? screenWidth *
                                    0.02 // More gap when timer is active
                                : screenWidth *
                                    0.01, // Original gap for other buttons
                      ), // Gap between icon and text
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _getButtonDisplayText(),
                            style: TextStyle(
                              fontSize: screenHeight * 0.016,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
