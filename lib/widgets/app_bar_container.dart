import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/user_stats_controller.dart';
import 'package:zero_koin/controllers/notification_controller.dart';
import 'package:zero_koin/view/notification_page.dart';
import 'package:zero_koin/widgets/notification_badge.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBarContainer extends StatelessWidget {
  const AppBarContainer({
    super.key,
    required this.color,
    this.showTotalPosition = true,
  });

  final Color color;
  final bool showTotalPosition;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final UserStatsController userStatsController =
        Get.find<UserStatsController>();

    // Get or create NotificationController
    final NotificationController notificationController = Get.put(
      NotificationController(),
    );

    // Ensure status bar content is white when app bar is visible
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return SafeArea(
      top: false,
      child: Container(
        height: screenHeight * 0.15,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          border: Border(
            bottom: BorderSide(color: Color(0xFF505050), width: 2),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder:
                          (context) => GestureDetector(
                            onTap: () {
                              Scaffold.of(context).openDrawer();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0682A2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(8),
                              width: 50,
                              height: 40,
                              child: SvgPicture.asset(
                                "assets/menu.svg",
                                width: 29,
                                height: 28,
                              ),
                            ),
                          ),
                    ),
                    Image.asset(
                      "assets/zero_koin_logo.png",
                      height: screenHeight * 0.05,
                      width: screenWidth * 0.16,
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => NotificationPage());
                      },
                      child: Obx(
                        () => NotificationBadge(
                          count: notificationController.unreadCount.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0682A2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(8),
                            width: 50,
                            height: 40,
                            child: SvgPicture.asset(
                              "assets/not.svg",
                              width: 29,
                              height: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (showTotalPosition) ...[
                  SizedBox(height: 6),
                  Obx(
                    () => Text(
                      "Total Positions ${userStatsController.formattedUserCount}",
                      style: TextStyle(
                        fontSize: screenWidth * 0.022,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
