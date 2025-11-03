import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.onPressed,
  });

  final String imageUrl;
  final String title;
  final VoidCallback onPressed;

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final ThemeController themeController = Get.find<ThemeController>();
    return Obx(
      () => SizedBox(
        height: screenHeight * 0.055,
        width: screenWidth,
        child: GestureDetector(
          onTapDown: (_) {
            setState(() {
              _isPressed = true;
            });
          },
          onTapUp: (_) {
            setState(() {
              _isPressed = false;
            });
            widget.onPressed();
          },
          onTapCancel: () {
            setState(() {
              _isPressed = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient:
                  _isPressed
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF055165), Color(0xFF68660D)],
                      )
                      : null,
              color: _isPressed ? null : themeController.contentBackgroundColor,
              borderRadius: BorderRadius.circular(0),
            ),
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    widget.imageUrl == "assets/whitepaper.png"
                        ? ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 0.7,
                            sigmaY: 0.7,
                          ),
                          child: Image.asset(
                            widget.imageUrl,
                            width: 28,
                            height: 28,
                          ),
                        )
                        : Image.asset(widget.imageUrl, width: 28, height: 28),
                    SizedBox(width: 12),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color:
                            _isPressed
                                ? Colors.white
                                : themeController.textColor,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color:
                          _isPressed ? Colors.white : themeController.textColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
