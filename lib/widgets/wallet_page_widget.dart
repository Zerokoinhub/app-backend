import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';

class WalletPageWidget extends StatelessWidget {
  const WalletPageWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final ThemeController themeController = Get.find<ThemeController>();
    return Obx(
      () => Container(
        height: screenHeight * 0.07,
        width: screenWidth * 0.42,
        decoration: BoxDecoration(
          border: Border.all(color: themeController.borderColor, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: Image(image: AssetImage("assets/wallet_page.png")),
            ),
            SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenHeight * 0.02,
                    color: themeController.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: screenHeight * 0.018,
                    color: themeController.subtitleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
