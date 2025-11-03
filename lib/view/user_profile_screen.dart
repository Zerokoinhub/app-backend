import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/view/bottom_bar.dart';
import 'package:zero_koin/services/auth_service.dart';
import 'package:zero_koin/view/user_registeration_screen.dart';

import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/my_drawer.dart';
import 'package:zero_koin/widgets/wallet_page_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String deviceName = 'Loading...';
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    _getDeviceName();
  }

  Future<void> _getDeviceName() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        setState(() {
          deviceName = iosInfo.name;
        });
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        setState(() {
          deviceName = androidInfo.model;
        });
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        setState(() {
          deviceName = macInfo.computerName;
        });
      }
    } catch (e) {
      setState(() {
        deviceName = 'Unknown Device';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final ThemeController themeController = Get.find<ThemeController>();
    final AuthService authService = AuthService.instance;
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
          Column(
            children: [
              AppBarContainer(color: Colors.black.withValues(alpha: 0.6), showTotalPosition: false),
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
                            if (Navigator.canPop(context)) {
                              Get.back();
                            } else {
                              Get.offAll(() => const BottomBar());
                            }
                          },
                          child: Image(
                            image: AssetImage("assets/arrow_back.png"),
                          ),
                        ),
                        SizedBox(width: 30),
                        Text(
                          "Profile",
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(
                  () => Container(
                    width: screenWidth,
                    decoration: BoxDecoration(
                      color: themeController.contentBackgroundColor,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                        children: [
                          Container(
                            width: screenWidth,
                            decoration: BoxDecoration(
                              color: Color(0xFF000000),
                              border: Border.all(
                                color: themeController.borderColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF0682A2),
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                        ),
                                        child: Obx(() => authService.userPhotoURL != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(50),
                                                child: Image.network(
                                                  authService.userPhotoURL!,
                                                  height: 50,
                                                  width: 50,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Center(
                                                      child: Text(
                                                        _getInitials(authService.userDisplayName ?? 'User'),
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  _getInitials(authService.userDisplayName ?? 'User'),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Obx(() => Text(
                                              authService.userDisplayName ?? 'User',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            )),
                                            Obx(() => Text(
                                              authService.userEmail ?? 'No email',
                                              style: TextStyle(
                                                color: Color(0xFFC4C9D5),
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            )),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () async {
                                          final ThemeController themeController = Get.find<ThemeController>();
                                          // Show confirmation dialog
                                          final shouldLogout = await Get.dialog<bool>(
                                            AlertDialog(
                                              backgroundColor: themeController.cardColor,
                                              title: Text(
                                                'Sign Out',
                                                style: TextStyle(color: themeController.textColor),
                                              ),
                                              content: Text(
                                                'Are you sure you want to sign out?',
                                                style: TextStyle(color: themeController.subtitleColor),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Get.back(result: false),
                                                  child: Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Get.back(result: true),
                                                  child: Text('Sign Out'),
                                                ),
                                              ],
                                            ),
                                          );
                                          
                                          if (shouldLogout == true) {
                                            await authService.signOut();
                                            // Navigate to registration screen
                                            Get.offAll(() => const UserRegisterationScreen());
                                          }
                                        },
                                        child: Container(
                                          height: 50,
                                          width: 80,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF0882A2),
                                            borderRadius: BorderRadius.circular(25.12),
                                          ),
                                          child: Center(
                                            child: SvgPicture.asset(
                                              "assets/logout.svg",
                                              width: 34,
                                              height: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  SizedBox(
                                    width: screenWidth,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF0682A2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {},
                                      child: Text(
                                        "ACTIVE",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Divider(
                            color: Colors.grey,
                            thickness: 1,
                            indent: 20,
                            endIndent: 20,
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FutureBuilder<String?>(
                                future: authService.userCreationDate,
                                builder: (context, snapshot) {
                                  return WalletPageWidget(
                                    title: "Created On",
                                    subtitle: snapshot.data ?? 'Loading...',
                                  );
                                },
                              ),
                              WalletPageWidget(
                                title: "Last Sign In",
                                subtitle: authService.userLastSignInTime ?? 'Unknown',
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Container(
                            width: screenWidth,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: themeController.borderColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 15,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "1. Mining access is permitted on only one device per account.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeController.textColor,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "2. Using multiple devices simultaneously is a breach of policy.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeController.textColor,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "3. Accounts found in violation may be restricted or denied withdrawals.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeController.textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            width: screenWidth,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: themeController.borderColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                children: [
                                  Image(image: AssetImage("assets/mobile.png")),
                                  SizedBox(width: 20),
                                  Text(
                                    deviceName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: themeController.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Spacer(),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF0682A2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      "ONLINE",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    List<String> nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return nameParts[0][0].toUpperCase();
    }
  }
}
