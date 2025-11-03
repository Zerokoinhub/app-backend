import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';

class LearnAndEarnWidget extends StatelessWidget {
  const LearnAndEarnWidget({
    super.key,
    required this.title,
    required this.originalTitle, // New parameter for the original title
    required this.onPressed,
    this.isSelected = false,
  });

  final String title;
  final String originalTitle; // Store the original title
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final ThemeController themeController = Get.find<ThemeController>();
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0682A2), width: 2),
          color: isSelected ? const Color(0xFF0682A2) : Colors.transparent,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 4.0,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenwidth < 360 ? 11 : 13,
                  color: isSelected ? Colors.white : themeController.textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
