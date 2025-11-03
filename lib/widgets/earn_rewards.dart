import 'package:flutter/material.dart';
import 'package:zero_koin/constant/app_colors.dart';
import 'package:get/get.dart';
import 'package:zero_koin/view/rewards_screen.dart';

class EarnRewards extends StatelessWidget {
  final int zerokoins;

  const EarnRewards({super.key, this.zerokoins = 30});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive calculations
    final isSmallDevice =
        screenHeight <
        700; // Define small device based on height (changed threshold)
    final containerWidth =
        screenWidth * 0.85; // Slightly wider container on small devices
    final containerPadding =
        isSmallDevice
            ? screenWidth * 0.03
            : screenWidth * 0.05; // Smaller padding on small devices
    final innerPadding =
        isSmallDevice
            ? screenWidth * 0.03
            : screenWidth * 0.04; // Smaller inner padding
    final imageSize =
        isSmallDevice
            ? screenWidth * 0.25
            : screenWidth * 0.3; // Smaller image on small devices
    final titleFontSize =
        isSmallDevice
            ? screenWidth * 0.04
            : screenWidth * 0.045; // Smaller title font on small devices
    final buttonTextFontSize =
        isSmallDevice
            ? screenWidth * 0.03
            : screenWidth * 0.035; // Smaller button font on small devices
    final verticalSpacing1 =
        isSmallDevice
            ? screenHeight * 0.01
            : screenHeight * 0.015; // Smaller spacing
    final verticalSpacing2 =
        isSmallDevice
            ? screenHeight * 0.015
            : screenHeight * 0.02; // Smaller spacing
    final buttonVerticalPadding =
        isSmallDevice
            ? screenHeight * 0.01
            : screenHeight * 0.015; // Smaller button padding
    final buttonHorizontalPadding =
        isSmallDevice
            ? screenWidth * 0.05
            : screenWidth * 0.06; // Smaller button padding
    final closeIconSize =
        isSmallDevice
            ? screenWidth * 0.05
            : screenWidth * 0.06; // Smaller close icon

    // Calculate minimum required height (simplified)
    final estimatedTitleHeight = titleFontSize * 3; // Estimate for 2-3 lines
    final buttonHeight = screenHeight * 0.06; // Responsive button height
    final totalSpacing =
        verticalSpacing1 + verticalSpacing2; // Spacing elements
    final totalPadding =
        (containerPadding + innerPadding); // Vertical padding sum
    final closeButtonSpace =
        closeIconSize * 1.2; // Estimate space for close button
    final minRequiredHeight =
        imageSize +
        estimatedTitleHeight +
        buttonHeight +
        totalSpacing +
        totalPadding +
        closeButtonSpace;

    // Use calculated height but ensure it doesn't exceed screen bounds and has a minimum
    final maxContainerHeight =
        isSmallDevice
            ? screenHeight * 0.9
            : screenHeight * 0.8; // Allow larger height on small devices

    final containerHeight =
        (minRequiredHeight > maxContainerHeight)
            ? maxContainerHeight
            : (minRequiredHeight < screenHeight * 0.4
                ? screenHeight * 0.4
                : minRequiredHeight);

    return Container(
      width: containerWidth,
      height: containerHeight,
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          screenWidth * 0.05,
        ), // Responsive border radius
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: innerPadding,
              vertical: innerPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: verticalSpacing1), // Adjusted spacing
                Image(
                  image: AssetImage('assets/earn_rewards.png'),
                  height: imageSize,
                  width: imageSize,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: verticalSpacing1), // Adjusted spacing
                Text(
                  'You Earned $zerokoins\nZRK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleFontSize, // Responsive font size
                    fontWeight: FontWeight.w900,
                    color: AppColors.blue,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: verticalSpacing2), // Adjusted spacing
                SizedBox(
                  width: screenWidth * 0.6, // Responsive button width
                  height: buttonHeight, // Responsive button height
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0682A2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: buttonHorizontalPadding,
                        vertical: buttonVerticalPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.02,
                        ), // Responsive border radius
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the popup
                      Get.to(
                        () => const RewardsScreen(),
                      ); // Navigate to rewards screen
                    },
                    child: Text(
                      "View more Rewards",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: buttonTextFontSize, // Responsive font size
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: screenWidth * 0.02, // Responsive positioning
            top: screenHeight * 0.01, // Responsive positioning
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                padding: EdgeInsets.all(
                  screenWidth * 0.015,
                ), // Responsive padding
                child: Icon(
                  Icons.close,
                  color: Colors.grey,
                  size: closeIconSize, // Responsive icon size
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
