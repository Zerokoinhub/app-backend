import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/controllers/notification_controller.dart';
import 'package:zero_koin/controllers/admob_controller.dart';
import 'package:zero_koin/view/bottom_bar.dart';

import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/my_drawer.dart';
import 'package:zero_koin/widgets/notifcation_popup.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final ThemeController themeController = Get.find<ThemeController>();

    // Initialize NotificationController
    final NotificationController notificationController = Get.put(
      NotificationController(),
    );

    // Mark all notifications as read when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notificationController.onNotificationPageOpened();
    });

    // Initialize AdMobController
    final AdMobController adMobController = Get.find<AdMobController>();

    return Scaffold(
      drawer: MyDrawer(),
      body: Stack(
        children: [
          Image.asset(
            "assets/Background.jpg",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Column(
            children: [
              AppBarContainer(
                color: Colors.black.withValues(alpha: 0.6),
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
                            // Navigate to home screen (BottomBar with index 0)
                            Get.offAll(() => const BottomBar(initialIndex: 0));
                          },
                          child: Image(
                            image: AssetImage("assets/arrow_back.png"),
                          ),
                        ),
                        SizedBox(width: 20),
                        Text(
                          "Notification",
                          style: TextStyle(
                            fontSize: screenHeight * 0.03,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // AdMob Banner Ad for Notification Page
                    Obx(() {
                      final ad = adMobController.notificationBannerAd;
                      final isReady =
                          adMobController.isNotificationBannerAdReady.value;

                      if (isReady && ad != null) {
                        // ✅ Ad is loaded, show AdWidget
                        return Container(
                          width: ad.size.width.toDouble(),
                          height: ad.size.height.toDouble(),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: AdWidget(ad: ad),
                        );
                      } else {
                        // ❌ Ad not loaded yet, show placeholder
                        return Container(
                          width: 320,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.withAlpha(
                                77,
                              ), // 0.3.toInt() ≈ 77
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          ),
                        );
                      }
                    }),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: themeController.contentBackgroundColor,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Obx(() {
                            if (notificationController.isLoading.value) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: themeController.textColor,
                                ),
                              );
                            }

                            if (notificationController.error.value.isNotEmpty) {
                              return Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Error loading notifications',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: screenHeight * 0.018,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        notificationController
                                            .fetchNotifications();
                                      },
                                      child: Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (!notificationController.hasNotifications) {
                              return Center(
                                child: Text(
                                  'No notifications available',
                                  style: TextStyle(
                                    color: themeController.textColor,
                                    fontSize: screenHeight * 0.018,
                                  ),
                                ),
                              );
                            }

                            return RefreshIndicator(
                              onRefresh:
                                  notificationController.refreshNotifications,
                              child: ListView.builder(
                                itemCount:
                                    notificationController
                                        .recentNotifications
                                        .length,
                                itemBuilder: (context, index) {
                                  final notification =
                                      notificationController
                                          .recentNotifications[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: screenHeight * 0.02,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        notificationController
                                            .onNotificationTap(notification);

                                        // If a link is provided by API, open it
                                        if (notification.link
                                            .trim()
                                            .isNotEmpty) {
                                          final Uri uri = Uri.parse(
                                            notification.link.trim(),
                                          );
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(
                                              uri,
                                              mode:
                                                  LaunchMode
                                                      .externalApplication,
                                            );
                                          }
                                        } else {
                                          // Fallback: show existing popup if no link
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
                                                  child: NotifcationPopup(),
                                                ),
                                              );
                                            },
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: themeController.borderColor,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              // Notification image
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    notification.fullImageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Image.asset(
                                                        "assets/zerokoingold.png",
                                                        fit: BoxFit.contain,
                                                      );
                                                    },
                                                    loadingBuilder: (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          value:
                                                              loadingProgress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? loadingProgress
                                                                          .cumulativeBytesLoaded /
                                                                      loadingProgress
                                                                          .expectedTotalBytes!
                                                                  : null,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      notification.title,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            themeController
                                                                .textColor,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Builder(
                                                      builder: (context) {
                                                        print(
                                                          '🎯 Displaying notification: ${notification.title}',
                                                        );
                                                        print(
                                                          '   Content: "${notification.content}"',
                                                        );
                                                        print(
                                                          '   DisplayText: "${notification.displayText}"',
                                                        );
                                                        return Text(
                                                          notification
                                                              .displayText,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                themeController
                                                                    .textColor,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      notification.timeAgo,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: themeController
                                                            .textColor
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.chevron_right,
                                                size: 22,
                                                color: themeController.textColor
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
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
    );
  }
}
