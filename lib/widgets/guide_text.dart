import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';

class GuideText extends StatelessWidget {
  const GuideText({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022',
            style: TextStyle(
              color: themeController.subtitleColor,
              fontSize: 18,
              height: 1.4,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: themeController.subtitleColor,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
