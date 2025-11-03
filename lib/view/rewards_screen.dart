import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/controllers/user_controller.dart';
import 'package:zero_koin/view/socail_media_pages.dart';
import 'package:zero_koin/view/invite_user_screen.dart';
import 'package:zero_koin/view/bottom_bar.dart';
import 'package:zero_koin/view/wallet_screen.dart';
import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/rewards_widget.dart';
import 'package:zero_koin/widgets/my_drawer.dart';
import 'package:zero_koin/widgets/gradient_circular_progress_painter.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final ThemeController themeController = Get.find<ThemeController>();
    final UserController userController = Get.find<UserController>();
    return Scaffold(
      drawer: MyDrawer(),
      body: Stack(
        children: [
          Image.asset(
            'assets/Background.jpg',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                AppBarContainer(
                  color: Colors.black.withOpacity(0.6),
                  showTotalPosition: false,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.back();
                            },
                            child: Image(
                              image: AssetImage("assets/arrow_back.png"),
                            ),
                          ),
                          SizedBox(width: 20),
                          Text(
                            "Earn Rewards",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Obx(
                        () => Container(
                          width: screenWidth,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(
                              color: themeController.borderColor,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    bottomRight: Radius.circular(20),
                                  ),
                                  child: Image.asset(
                                    'assets/stroke.png',
                                    width: screenWidth * 0.25,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Your Total ZRK",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.055,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Obx(() {
                                          final userBalance =
                                              userController.balance.value;
                                          final maxBalance = 4000;
                                          final percentage =
                                              userBalance >= maxBalance
                                                  ? 100
                                                  : (userBalance /
                                                          maxBalance *
                                                          100)
                                                      .round();
                                          final progress =
                                              userBalance >= maxBalance
                                                  ? 1.0
                                                  : userBalance / maxBalance;
                                          return SizedBox(
                                            width: screenWidth * 0.2,
                                            height: screenWidth * 0.2,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                // Background circle
                                                SizedBox(
                                                  width: screenWidth * 0.2,
                                                  height: screenWidth * 0.2,
                                                  child: CircularProgressIndicator(
                                                    value: 1.0,
                                                    strokeWidth: 8,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(
                                                          Colors.grey
                                                              .withOpacity(0.3),
                                                        ),
                                                  ),
                                                ),
                                                // Progress circle with gradient effect
                                                SizedBox(
                                                  width: screenWidth * 0.2,
                                                  height: screenWidth * 0.2,
                                                  child: CustomPaint(
                                                    painter:
                                                        GradientCircularProgressPainter(
                                                          progress: progress,
                                                          strokeWidth: 8,
                                                          startColor: Color(
                                                            0xFF0682A2,
                                                          ), // Cyan/Teal
                                                          endColor: Color(
                                                            0xFFC5C113,
                                                          ), // Yellow-Green
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                        ),
                                                  ),
                                                ),
                                                Image(
                                                  image: AssetImage(
                                                    "assets/trophyy.png",
                                                  ),
                                                  width:
                                                      screenWidth *
                                                      0.12, // Adjust trophy size relative to circle
                                                  height:
                                                      screenWidth *
                                                      0.12, // Adjust trophy size relative to circle
                                                  fit: BoxFit.contain,
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${userController.balance.value} ZRK",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.055,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Once you reach 4000 ZRK, you'll be eligible to make a withdrawal.",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: screenWidth * 0.03,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Obx(
                  () => Container(
                    height: screenHeight * 0.55,
                    width: screenWidth,
                    decoration: BoxDecoration(
                      color: themeController.contentBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "More Reward",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: themeController.textColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Column(
                            children: [
                              RewardsWidget(
                                onPressed: () {
                                  Get.to(() => const SocailMediaPages());
                                },
                                imageUrl: "assets/Vector (2).svg",
                                title: "Follow Social Media Earn",
                              ),
                              SizedBox(height: 20),
                              RewardsWidget(
                                onPressed: () {
                                  Get.to(
                                    () => const BottomBar(initialIndex: 2),
                                  );
                                },
                                imageUrl: "assets/Group.svg",
                                title: "Learn and Earn Daily",
                              ),
                              SizedBox(height: 20),
                              RewardsWidget(
                                onPressed: () {
                                  Get.to(() => const InviteUserScreen());
                                },
                                imageUrl: "assets/Vector (3).svg",
                                title: "Invite Friends",
                              ),
                              SizedBox(height: 30),
                              SizedBox(
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
                                    Get.to(() => const WalletScreen());
                                  },
                                  child: Text("Withdraw"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
