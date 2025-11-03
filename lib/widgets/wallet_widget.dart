import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';

class WalletWidget extends StatelessWidget {
  const WalletWidget({super.key, required this.title, required this.hintText});

  final String title;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ThemeController themeController = Get.find<ThemeController>();
    return Obx(
      () => Container(
        width: screenWidth,
        decoration: BoxDecoration(
          border: Border.all(color: themeController.borderColor, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: themeController.textColor,
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: TextFormField(
                  style: TextStyle(color: themeController.textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor:
                        themeController.isDarkMode
                            ? Colors.grey[800]
                            : Color(0xFFEFE5E5),
                    hintText: hintText,
                    hintStyle: TextStyle(color: themeController.subtitleColor),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/mining.png',
                        height: 20,
                        width: 20,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: themeController.borderColor,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: themeController.borderColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
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
