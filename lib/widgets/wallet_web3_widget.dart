import 'package:flutter/material.dart';

class WalletWeb3Widget extends StatelessWidget {
  const WalletWeb3Widget({
    super.key,
    required this.containerColor,
    required this.imageUrl,
    required this.text,
    this.fontSize = 15,
  });

  final Color containerColor;
  final String imageUrl;
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity, // Use full available width
      height: screenHeight * 0.07, // Responsive height (7% of screen height)
      padding: EdgeInsets.all(screenWidth * 0.03), // Responsive padding
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: containerColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            imageUrl,
            height:
                imageUrl.contains('zero_koin_logo')
                    ? screenHeight *
                        0.02 // Smaller for zero koin logo
                    : screenHeight * 0.04, // Responsive image height
            fit: BoxFit.contain,
          ),
          SizedBox(width: screenWidth * 0.03), // Responsive spacing
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
