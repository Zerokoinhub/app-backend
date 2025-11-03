import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/controllers/user_controller.dart';
import 'package:zero_koin/services/admob_service.dart';
import 'package:zero_koin/view/invite_user_screen.dart';
import 'package:zero_koin/view/rewards_screen.dart';

import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/earn_rewards.dart';

import 'package:zero_koin/widgets/home_page_widgets.dart';
import 'package:zero_koin/widgets/home_screen_widget.dart';
import 'package:zero_koin/widgets/my_drawer.dart';

import 'package:zero_koin/widgets/session_popup.dart';
import 'package:zero_koin/widgets/progress_popup.dart';
import 'package:zero_koin/controllers/home_controller.dart'; // Import HomeController
import 'package:zero_koin/controllers/session_controller.dart';
import 'package:zero_koin/controllers/admob_controller.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:developer' as developer;

import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final AdMobController adMobController = Get.find<AdMobController>();
    final ThemeController themeController = Get.find<ThemeController>();
    final HomeController homeController = Get.put(
      HomeController(),
    ); // Initialize HomeController
    final UserController userController =
        homeController
            .userController; // Access UserController via HomeController

    // Ensure status bar content is white
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      drawer: MyDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/homebackground.png',
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AppBarContainer(color: Colors.black.withValues(alpha: 0.6)),
                  SizedBox(height: 12),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {},
                                child: Obx(
                                  () => HomeScreenWidget(
                                    title: "Mining",
                                    subTitle:
                                        userController.balance.value.toString(),
                                    imageURl: "assets/zerokoingold.png",
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20.0),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {},
                                child: HomeScreenWidget(
                                  title: "References",
                                  subTitle: "0",
                                  imageURl: "assets/Vector (7).svg",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {},
                                child: HomeScreenWidget(
                                  title: "Referrals",
                                  subTitle: "0",
                                  imageURl: "assets/Group (1).svg",
                                ),
                              ),
                            ),
                            SizedBox(width: 20.0),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {},
                                child: HomeScreenWidget(
                                  title: "Power",
                                  subTitle: "1/4",
                                  imageURl:
                                      "assets/tabler_battery-2-filled.svg",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Obx(
                        () => Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: themeController.contentBackgroundColor,
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Column(
                                  children: [
                                    // AdMob Banner Ad
                                    Obx(() {
                                      final ad = adMobController.bannerAd.value;
                                      final isReady =
                                          adMobController.isBannerAdReady.value;

                                      if (ad != null && isReady) {
                                        return Container(
                                          width: ad.size.width.toDouble(),
                                          height: ad.size.height.toDouble(),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: AdWidget(ad: ad),
                                        );
                                      } else {
                                        return Container(
                                          width: 320,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.withAlpha(80),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    }),
                                    SizedBox(height: 14),
                                    Obx(
                                      () => HomePageWidgets(
                                        onPressed: () {
                                          // Check if timer is active to show appropriate popup
                                          bool isTimerActive = false;
                                          try {
                                            final sessionController =
                                                Get.find<SessionController>();
                                            isTimerActive =
                                                sessionController
                                                    .countdownTimers
                                                    .isNotEmpty;
                                          } catch (e) {
                                            // If SessionController is not found, default to false
                                            isTimerActive = false;
                                          }

                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return BackdropFilter(
                                                filter: ImageFilter.blur(
                                                  sigmaX: 5.0,
                                                  sigmaY: 5.0,
                                                ),
                                                child: Dialog(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  child:
                                                      isTimerActive
                                                          ? ProgressPopup(
                                                            sessionIndex: 1,
                                                          ) // Show progress popup when timer is active
                                                          : SessionPopup(), // Show session popup when no timer
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        title: "Total ZRK",
                                        subtitle:
                                            homeController
                                                .userController
                                                .balance
                                                .value
                                                .toString(),
                                        imageURL: "assets/zerokoingold.png",
                                        buttonImage:
                                            "assets/solar_play-bold.svg",
                                        buttonText: "Start",
                                        color: const Color(0xFF007B1F),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    HomePageWidgets(
                                      onPressed: () {
                                        Get.to(() => const InviteUserScreen());
                                      },
                                      title: "Invite to Friend",
                                      subtitle:
                                          "Get 50 ZRK when your friend joins through your invite",
                                      imageURL: "assets/Invite Icon.svg",
                                      buttonImage: "assets/Vector (1).svg",
                                      buttonText: "Invite",
                                      color: const Color(0xFF0682A2),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: SizedBox(
                                  width: Get.width,
                                  height: screenHeight * 0.07,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF0682A2),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Get.to(() => const RewardsScreen());
                                    },
                                    child: Text("Get More Rewards"),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/Info Icon.svg",
                                          width: 25,
                                          height: 25,
                                          colorFilter: ColorFilter.mode(
                                            themeController.isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Text(
                                          "Mining Information",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: themeController.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SvgPicture.asset(
                                              "assets/Gift box Icon.svg",
                                              width: 16.67,
                                              height: 15,
                                            ),
                                            SizedBox(width: screenWidth * 0.03),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        themeController
                                                            .subtitleColor,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          "Invite Friends & Earn ",
                                                    ),
                                                    TextSpan(
                                                      text: "50 ZRK",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                    TextSpan(text: "!"),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            "For every successful referral...",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  themeController.subtitleColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SvgPicture.asset(
                                              "assets/Watch Icon.svg",
                                              width: 16.67,
                                              height: 15,
                                            ),
                                            SizedBox(width: screenWidth * 0.03),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        themeController
                                                            .subtitleColor,
                                                  ),
                                                  children: [
                                                    TextSpan(text: "Earn "),
                                                    TextSpan(
                                                      text: "30",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          " ZRK every 6 hours!",
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            "Stay active and keep collecting rewards regularly",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  themeController.subtitleColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SvgPicture.asset(
                                              "assets/blue Rocket.svg",
                                              width: 16.67,
                                              height: 15,
                                            ),
                                            SizedBox(width: screenWidth * 0.03),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        themeController
                                                            .subtitleColor,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: "Follow",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: " us & get ",
                                                    ),
                                                    TextSpan(
                                                      text: "30",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                    TextSpan(text: " ZRK!"),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SvgPicture.asset(
                                              "assets/Book open.svg",
                                              width: 16.67,
                                              height: 15,
                                            ),
                                            SizedBox(width: screenWidth * 0.03),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        themeController
                                                            .subtitleColor,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          "Learn daily, earn daily – Get ",
                                                    ),
                                                    TextSpan(
                                                      text: "10",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                    TextSpan(text: " ZRK!"),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            "for reading 5 pages!",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  themeController.subtitleColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SvgPicture.asset(
                                              "assets/No KYC Icon.svg",
                                              width: 16.67,
                                              height: 15,
                                            ),
                                            SizedBox(width: screenWidth * 0.03),
                                            Expanded(
                                              child: RichText(
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        themeController
                                                            .subtitleColor,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          "Completely Free - ",
                                                    ),
                                                    TextSpan(
                                                      text: "No KYC Required",
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF0682A2,
                                                        ),
                                                      ),
                                                    ),
                                                    TextSpan(text: "."),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            "Invite more friends and support the growth of the ecosystem",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  themeController.subtitleColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF08647C),
                                            Color(0xFF08627A),
                                            Color(0xFF8B880D),
                                          ],
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          16.0,
                                          12.0,
                                          16.0,
                                          16.0,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: screenWidth * 0.03,
                                                ),

                                                Flexible(
                                                  // child: Icon(
                                                  //   Icons.rocket,
                                                  //   color: Colors.white,
                                                  //   size:
                                                  //       screenHeight < 700
                                                  //           ? screenHeight *
                                                  //               0.04
                                                  //           : screenHeight *
                                                  //               0.05,
                                                  // ),
                                                  child: Image.asset(
                                                    "assets/Rocket.png",
                                                    width:
                                                        screenHeight < 700
                                                            ? screenHeight *
                                                                0.04
                                                            : screenHeight *
                                                                0.05,
                                                    height:
                                                        screenHeight < 700
                                                            ? screenHeight *
                                                                0.04
                                                            : screenHeight *
                                                                0.05,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: screenWidth * 0.03,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Launching Soon",
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              screenHeight < 700
                                                                  ? screenHeight *
                                                                      0.022
                                                                  : screenHeight *
                                                                      0.025,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                      SizedBox(height: 2),
                                                      Text(
                                                        "Don't miss the opportunity",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              screenHeight < 700
                                                                  ? screenHeight *
                                                                      0.014
                                                                  : screenHeight *
                                                                      0.016,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily: 'Poppins',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: screenHeight * 0.008,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                // Tier 3
                                                Column(
                                                  children: [
                                                    Stack(
                                                      clipBehavior: Clip.none,
                                                      children: [
                                                        Container(
                                                          width:
                                                              screenWidth *
                                                              0.15,
                                                          height:
                                                              screenWidth *
                                                              0.15,
                                                          decoration:
                                                              BoxDecoration(
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                          child: Align(
                                                            alignment:
                                                                Alignment(
                                                                  0.5,
                                                                  0,
                                                                ),
                                                            child: Image.asset(
                                                              "assets/Tier 3 Icon.png",
                                                              width:
                                                                  screenWidth *
                                                                  0.10,
                                                              height:
                                                                  screenWidth *
                                                                  0.10,
                                                              fit:
                                                                  BoxFit
                                                                      .contain,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: -5,
                                                          right: -5,
                                                          child: Container(
                                                            width:
                                                                screenWidth *
                                                                0.05,
                                                            height:
                                                                screenWidth *
                                                                0.05,
                                                            decoration:
                                                                BoxDecoration(
                                                                  shape:
                                                                      BoxShape
                                                                          .circle,
                                                                  color: Color(
                                                                    0xFFFDA200,
                                                                  ),
                                                                ),
                                                            child: Center(
                                                              child: CustomPaint(
                                                                painter: TickPainter(
                                                                  color: Color(
                                                                    0xFF03C9C7,
                                                                  ),
                                                                ),
                                                                size: Size(
                                                                  screenWidth *
                                                                      0.03,
                                                                  screenWidth *
                                                                      0.03,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      "Tier 3",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            screenHeight *
                                                            0.018,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Dotted line
                                                Expanded(
                                                  child: Transform.translate(
                                                    offset: Offset(0, -10.0),
                                                    child: Center(
                                                      child: CustomPaint(
                                                        painter:
                                                            DottedLinePainter(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2.0,
                                                              dashLength: 5.0,
                                                              dashSpace: 3.0,
                                                            ),
                                                        size: Size(
                                                          double.infinity,
                                                          2.0,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Tier 2
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: screenWidth * 0.15,
                                                      height:
                                                          screenWidth * 0.15,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.white,
                                                      ),
                                                      child: Center(
                                                        child: CustomPaint(
                                                          painter:
                                                              ClockPainter(),
                                                          size: Size(
                                                            screenWidth * 0.1,
                                                            screenWidth * 0.1,
                                                          ), // Reduced Size of the clock face
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      "Tier 2",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            screenHeight *
                                                            0.018,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Dotted line
                                                Expanded(
                                                  child: Transform.translate(
                                                    offset: Offset(0, -10.0),
                                                    child: Center(
                                                      child: CustomPaint(
                                                        painter:
                                                            DottedLinePainter(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2.0,
                                                              dashLength: 5.0,
                                                              dashSpace: 3.0,
                                                            ),
                                                        size: Size(
                                                          double.infinity,
                                                          2.0,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Tier 1
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: screenWidth * 0.15,
                                                      height:
                                                          screenWidth * 0.15,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.white,
                                                      ),
                                                      child: Center(
                                                        child: Image.asset(
                                                          "assets/Tier 1 Icon.png",
                                                          width:
                                                              screenWidth * 0.1,
                                                          height:
                                                              screenWidth * 0.1,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      "Tier 1",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            screenHeight *
                                                            0.018,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TickPainter extends CustomPainter {
  final Color color;

  TickPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(
      size.width * 0.2,
      size.height * 0.5,
    ); // Start point (adjust as needed)
    path.lineTo(size.width * 0.5, size.height * 0.8); // Corner point
    path.lineTo(
      size.width * 0.8,
      size.height * 0.2,
    ); // End point (adjust as needed)

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer arcs
    final outerRingPaint =
        Paint()
          ..color = Color(0xFFFDA200)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6.0; // Reduced thickness

    final outerRadius = radius + 6.0; // Increased radius to create a gap

    // Angles for the cuts (adjust epsilon for gap size)
    const double epsilon = 0.2; // Small angle for the gap size in radians

    // Draw top arc (from right gap to left gap, going through 12 o'clock)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      epsilon, // Start angle (slightly after right cut, going counter-clockwise)
      math.pi - 2 * epsilon, // Sweep angle (covers the top half minus gaps)
      false, // Use center
      outerRingPaint,
    );

    // Draw bottom arc (from left gap to right gap, going through 6 o'clock)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      math.pi +
          epsilon, // Start angle (slightly after left cut, going counter-clockwise)
      math.pi - 2 * epsilon, // Sweep angle (covers the bottom half minus gaps)
      false, // Use center
      outerRingPaint,
    );

    // Draw clock face
    final facePaint = Paint()..color = Color(0xFFFDA200);
    canvas.drawCircle(center, radius, facePaint);

    // Draw hour hand (pointing to 6)
    final hourHandPaint =
        Paint()
          ..color = Color(0xFF03C9C7)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.0;

    // Angle for slightly more than 6 o'clock
    // Hour hand length is shorter, e.g., 60% of radius
    final hourHandLength = radius * 0.6;
    final hourHandX =
        center.dx +
        hourHandLength * math.cos(math.pi + 0.1); // Added 0.1 radians to angle
    final hourHandY =
        center.dy +
        hourHandLength * math.sin(math.pi + -0.4); // Added 0.1 radians to angle
    canvas.drawLine(center, Offset(hourHandX, hourHandY), hourHandPaint);

    // Draw minute hand (pointing to 12)
    final minuteHandPaint =
        Paint()
          ..color = Color(0xFF03C9C7)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 3.0;

    // Angle for 12 o'clock (or 0 minutes): 0 degrees or 360 degrees
    // In radians: -math.pi / 2 (pointing upwards, 12 o'clock)
    final minuteHandLength = radius * 0.8;
    final minuteHandX = center.dx + minuteHandLength * math.cos(-math.pi / 2);
    final minuteHandY = center.dy + minuteHandLength * math.sin(-math.pi / 2);
    canvas.drawLine(center, Offset(minuteHandX, minuteHandY), minuteHandPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  DottedLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashLength, size.height / 2),
        paint,
      );
      startX += dashLength + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
