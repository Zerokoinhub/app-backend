import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RewardsWidget extends StatelessWidget {
  const RewardsWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.onPressed,
  });

  final String imageUrl;
  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final ThemeController themeController = Get.find<ThemeController>();
    return Obx(
      () => GestureDetector(
        onTap: onPressed,
        child: Container(
          height: screenHeight * 0.08,
          width: screenWidth,
          decoration: BoxDecoration(
            border: Border.all(color: themeController.borderColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 24, // Fixed width for the icon container
                  height: 24, // Fixed height for the icon container
                  child: Center(
                    child: imageUrl.toLowerCase().endsWith('.svg')
                        ? SvgPicture.asset(
                            imageUrl,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          )
                        : Image(image: AssetImage(imageUrl)),
                  ),
                ),
                SizedBox(width: screenWidth * 0.05),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeController.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
