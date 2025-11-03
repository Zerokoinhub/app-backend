import 'package:flutter/material.dart';

class ZerokoinBuyWidget extends StatelessWidget {
  const ZerokoinBuyWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.buttonText,
  });

  final String imageUrl;
  final String title;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.2,
      width: screenWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/zerokoin_buy_icon_01.png"),
              SizedBox(width: 10),
              Text(
                "PancakeSwap",
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ],
          ),
          SizedBox(height: 10),
          SizedBox(
            width: screenWidth * 0.55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {},
              child: Text(
                "ZEROKOIN/USDT",
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
          Text(
            "Listing date: 22.09.2024",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
