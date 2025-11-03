import 'package:flutter/material.dart';

class PopUpButton extends StatelessWidget {
  const PopUpButton({
    super.key,
    required this.buttonText,
    required this.buttonColor,
    required this.onPressed,
    required this.textColor,
    required this.borderColor,
    this.fontSize,
  });

  final String buttonText;
  final Color buttonColor;
  final Color textColor;
  final void Function() onPressed;
  final Color borderColor;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive calculations for small devices
    final isSmallDevice = screenHeight < 700;
    final horizontalPadding =
        isSmallDevice ? screenWidth * 0.06 : screenWidth * 0.1;
    final verticalPadding =
        isSmallDevice ? screenHeight * 0.012 : screenHeight * 0.015;
    final defaultFontSize = isSmallDevice ? screenWidth * 0.035 : screenWidth * 0.04;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        side: BorderSide(color: borderColor, width: 2),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: fontSize ?? defaultFontSize,
          fontWeight: FontWeight.w900,
          color: textColor,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
