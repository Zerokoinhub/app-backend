import 'package:flutter/material.dart';
import 'package:zero_koin/models/trading_cards.dart';
import 'package:zero_koin/widgets/trading_card.dart';
import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/my_drawer.dart';

class ZerokoinBuy extends StatefulWidget {
  const ZerokoinBuy({super.key});

  @override
  State<ZerokoinBuy> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<ZerokoinBuy> {
  // List of trading cards data
  final List tradingCards = [
    TradingCard(
      platformName: 'PancakeSwap',
      platformIcon: 'assets/pan.png',
      tradingPair: 'ZRK/USDT',
      listingDate: '15.09.2025',
      iconColor: const Color(0xFF1FC7D4),
      url:
          'https://pancakeswap.finance/swap?outputCurrency=0x220c0A61747832Bf6F61cB181d4Adf72Daf05014&inputCurrency=0x55d398326f99059fF775485246999027B3197955',
    ),
    TradingCard(
      platformName: 'DEXTOOLS.io',
      platformIcon: 'assets/dex.png',
      tradingPair: 'ZRK/USDT',
      listingDate: '15.09.2025',
      iconColor: const Color(0xFF05A3C9),
      url:
          'https://www.dextools.io/app/en/bnb/pair-explorer/0x0ab16fc754a3dee499daf7514e94d4f0a277f46f?t=1759835302279',
    ),
    TradingCard(
      platformName: 'CoinGecko',
      platformIcon: 'assets/coingecko_icon.png',
      tradingPair: 'ZRK/USDT',
      listingDate: 'Soon',
      isLaunchingSoon: true,
      iconColor: const Color(0xFF1FC7D4),
    ),
    TradingCard(
      platformName: 'Coinmarketcap',
      platformIcon: 'assets/coinmarketcap.png',
      tradingPair: 'ZRK/USDT',
      listingDate: 'Soon',
      isLaunchingSoon: true,
      iconColor: const Color(0xFF1FC7D4),
    ),
    Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Text(
        "TOP 10 EXCHANGE SOON",
        style: TextStyle().copyWith(
          color: Colors.white.withOpacity(0.8),
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Image.asset(
            'assets/Background.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          Container(
            color: Colors.black.withOpacity(0.35),
            height: double.infinity,
            width: double.infinity,
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                AppBarContainer(
                  color: Colors.black.withOpacity(0.6),
                  showTotalPosition: false,
                ),
                SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      children: [
                        Row(
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
                              "Buy Zero Koin",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 16),
                            itemCount: tradingCards.length,
                            itemBuilder: (context, index) {
                              if (tradingCards[index] is Container) {
                                return tradingCards[index];
                              }
                              return TradingCardWidget(
                                card: tradingCards[index],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
