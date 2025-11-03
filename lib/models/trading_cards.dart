import 'package:flutter/material.dart';

class TradingCard {
  final String platformName;
  final String platformIcon;
  final String tradingPair;
  final String listingDate;
  final bool isLaunchingSoon;
  final Color iconColor;
  final String? url;

  TradingCard({
    required this.platformName,
    required this.platformIcon,
    required this.tradingPair,
    required this.listingDate,
    this.isLaunchingSoon = false,
    this.iconColor = Colors.orange,
    this.url,
  });
}
