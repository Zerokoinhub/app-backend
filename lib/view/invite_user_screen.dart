import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/controllers/user_controller.dart';
import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/wallet_widget.dart';
import 'package:zero_koin/widgets/my_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InviteUserScreen extends StatelessWidget {
  const InviteUserScreen({super.key});

  Future<void> _refreshUserData(BuildContext context) async {
    final UserController userController = Get.find<UserController>();
    try {
      await userController.fetchUserProfile();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Invite code refreshed"),
            backgroundColor: const Color(0xFF0682A2),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to refresh: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

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
            'assets/Backgroundhalf.jpg',
            fit: BoxFit.cover,
            height: screenHeight * 0.5,
            width: screenWidth,
          ),
          RefreshIndicator(
            onRefresh: () => _refreshUserData(context),
            color: const Color(0xFF0682A2),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  AppBarContainer(
                    color: Colors.black.withValues(alpha: 0.6),
                    showTotalPosition: false,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.back();
                              },
                              child: const Image(
                                image: AssetImage("assets/arrow_back.png"),
                              ),
                            ),
                            const SizedBox(width: 40),
                            const Text(
                              "Invite Code",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Obx(
                          () => Container(
                            height: 48,
                            width: screenWidth * 0.9,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: themeController.borderColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(15.8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: Obx(
                                      () =>
                                          userController.isLoading.value &&
                                                  userController
                                                      .inviteCode
                                                      .value
                                                      .isEmpty
                                              ? Center(
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                      ),
                                                ),
                                              )
                                              : Text(
                                                userController
                                                        .inviteCode
                                                        .value
                                                        .isEmpty
                                                    ? "No invite code available"
                                                    : userController
                                                        .inviteCode
                                                        .value,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: double.infinity,
                                  width: 100,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15.8),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(15.8),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (userController
                                            .inviteCode
                                            .value
                                            .isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "No invite code available to copy",
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        Clipboard.setData(
                                          ClipboardData(
                                            text:
                                                userController.inviteCode.value,
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Code copied to clipboard",
                                            ),
                                            backgroundColor: Color(0xFF0682A2),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0682A2,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(15.8),
                                          ),
                                          side: BorderSide.none,
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text(
                                        "Copy",
                                        style: TextStyle(
                                          fontSize: 14.58,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        SizedBox(
                          width: screenWidth,
                          height: screenHeight * 0.05,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  color: Color(0xFF0682A2),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              foregroundColor: const Color(0xFF0682A2),
                              backgroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              if (userController.inviteCode.value.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "No invite code available to share",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final String inviteCode =
                                  userController.inviteCode.value;
                              final String message =
                                  "Hey! I'm using Zero Koin app. Join me with my invite code: $inviteCode";

                              try {
                                await SharePlus.instance.share(
                                  ShareParams(text: message),
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Could not open share sheet",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  "assets/Vector (1).svg",
                                  width: 19,
                                  height: 11,
                                ),
                                const SizedBox(width: 8),
                                const Text("Invite Friends"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Obx(
                    () => Container(
                      height: screenHeight * 0.5,
                      width: screenWidth,
                      decoration: BoxDecoration(
                        color: themeController.contentBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Invite your friends and Earn 50 ZRK",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: themeController.textColor,
                                    ),
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            Column(
                              children: [
                                const WalletWidget(
                                  title: "References Amount",
                                  hintText: "50",
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                Obx(
                                  () => WalletWidget(
                                    title: "Recent Amount",
                                    hintText:
                                        userController.recentAmount.toString(),
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
          ),
        ],
      ),
    );
  }
}
