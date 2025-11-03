import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';

class WhitePaperScreen extends StatefulWidget {
  const WhitePaperScreen({super.key});
  @override
  State<WhitePaperScreen> createState() => _WhitePaperScreenState();
}

class _WhitePaperScreenState extends State<WhitePaperScreen> {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final ThemeController themeController = Get.find<ThemeController>();
    return Scaffold(
      backgroundColor: themeController.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: screenHeight * 0.2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: themeController.gradientColors,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "White Paper",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: themeController.contentBackgroundColor,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: screenHeight * 0.225,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: themeController.cardColor,
                        border: Border.all(color: themeController.borderColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
