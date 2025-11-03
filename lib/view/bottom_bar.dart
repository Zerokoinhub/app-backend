import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zero_koin/controllers/admob_controller.dart';
import 'package:zero_koin/view/calculator_screen.dart';
import 'package:zero_koin/view/home_screen.dart';
import 'package:zero_koin/view/learn_and_earn.dart';
import 'package:zero_koin/view/user_profile_screen.dart';
import 'package:zero_koin/view/wallet_screen.dart';
import 'package:zero_koin/controllers/home_controller.dart'; // Import HomeController
import 'package:get/get.dart'; // Import GetX

class BottomBar extends StatefulWidget {
  final int initialIndex;
  const BottomBar({super.key, this.initialIndex = 0});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    HomeScreen(),
    WalletScreen(),
    LearnAndEarn(),
    CalculatorScreen(),
    UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          _currentIndex == 0 &&
          !Navigator.canPop(
            context,
          ), // Only allow app to close when on home screen and no previous routes
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (Navigator.canPop(context)) {
            // If there are previous routes in the stack, go back normally
            Navigator.pop(context);
          } else if (_currentIndex != 0) {
            // If no previous routes and not on home screen, navigate to home screen
            setState(() {
              _currentIndex = 0;
            });
          }
        }
      },
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: CurvedNavigationBar(
          index: _currentIndex,
          backgroundColor: Color.fromARGB(255, 29, 28, 28),
          buttonBackgroundColor: Color(0xFF0682A2),
          color: Colors.black,
          height: 60,
          items: <Widget>[
            SvgPicture.asset(
              'assets/Home Button Icon.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            Image(
              image: AssetImage('assets/wallet.png'),
              color: Colors.white,
              width: 24,
              height: 24,
              colorBlendMode: BlendMode.srcIn,
            ),
            Image(
              image: AssetImage('assets/education.png'),
              color: Colors.white,
              width: 24,
              height: 24,
              colorBlendMode: BlendMode.srcIn,
            ),
            Image(
              image: AssetImage('assets/calculator.png'),
              color: Colors.white,
              width: 24,
              height: 24,
              colorBlendMode: BlendMode.srcIn,
            ),
            Image(
              image: AssetImage('assets/user_profile.png'),
              color: Colors.white,
              width: 24,
              height: 24,
              colorBlendMode: BlendMode.srcIn,
            ),
          ],
          onTap: (index) {
            setState(() {
              // If the tapped index is the home button
              if (index == 0) {
                // Trigger refresh data on HomeController
                final HomeController homeController =
                    Get.find<HomeController>();

                homeController.refreshData();
              }
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
