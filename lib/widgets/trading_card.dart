import 'package:flutter/material.dart';
import 'package:zero_koin/models/trading_cards.dart';
import 'package:url_launcher/url_launcher.dart';

class TradingCardWidget extends StatelessWidget {
  final TradingCard card;

  const TradingCardWidget({super.key, required this.card});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallBox =
        card.platformName == 'CoinGecko' ||
        card.platformName == 'Coinmarketcap';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Stack(
        children: [
          // Main card content
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallBox ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Header with platform info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Platform icon
                    card.platformIcon.contains('assets/')
                        ? Image.asset(
                          card.platformIcon,
                          width: isSmallBox ? 28 : 32,
                          height: isSmallBox ? 28 : 32,
                          fit: BoxFit.contain,
                        )
                        : Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: card.iconColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              card.platformIcon,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(width: 6),
                    // Platform name
                    card.platformName == 'DEXTOOLS.io'
                        ? RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'DEXTOOLS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: '.io',
                                style: const TextStyle(
                                  color: Color(0xFF0682A2),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                        : Text(
                          card.platformName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallBox ? 22 : 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 8),
                // Trading pair button
                SizedBox(
                  width: 240,
                  child: GestureDetector(
                    onTap:
                        card.url != null ? () => _launchUrl(card.url!) : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0682A2),
                        borderRadius: BorderRadius.circular(12.8),
                      ),
                      child: Center(
                        child: Text(
                          card.tradingPair,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Listing date
                Text(
                  'Listing date: ${card.listingDate}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isSmallBox ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
          // Launching Soon badge positioned in top-right
          // if (card.isLaunchingSoon)
          //   Positioned(
          //     top: 4,
          //     right: 4,
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          //       decoration: BoxDecoration(
          //         color: const Color(0xFF0682A2),
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       child: const Text(
          //         'Launching Soon',
          //         style: TextStyle(
          //           color: Colors.white,
          //           fontSize: 12,
          //           fontWeight: FontWeight.w500,
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}
