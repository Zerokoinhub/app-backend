import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zero_koin/constant/app_colors.dart';
import 'package:zero_koin/widgets/pop_up_button.dart';

class WalletPopup extends StatelessWidget {
  const WalletPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive dimensions
    final popupWidth = screenWidth * 0.85;
    final popupHeight = screenHeight * 0.45;
    final padding = screenWidth * 0.04;
    final iconSize = screenWidth * 0.20;
    final titleFontSize = screenWidth * 0.045;
    final messageFontSize = screenWidth * 0.035;
    final spacing = screenHeight * 0.015;

    return Container(
      width: popupWidth,
      height: popupHeight,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.015,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  "assets/Withdraw Successfull ICON.svg",
                  height: iconSize,
                  width: iconSize,
                ),
                SizedBox(height: spacing),
                Text(
                  'Withdrawn Successful',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue,
                  ),
                ),
                SizedBox(height: spacing),
                Text(
                  'You\'ve successfully \n withdrawn 4000 coins to the \n selected address',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: messageFontSize,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: spacing * 1.5),
                SizedBox(
                  width: popupWidth * 0.7,
                  child: PopUpButton(
                    buttonText: "Done",
                    buttonColor: Colors.blue,
                    onPressed: () {},
                    textColor: Colors.white,
                    borderColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: screenWidth * 0.02,
            top: screenHeight * 0.01,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Icon(
                Icons.close,
                color: Colors.grey,
                size: screenWidth * 0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
