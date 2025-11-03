import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/constant/app_colors.dart';
import 'package:zero_koin/view/bottom_bar.dart';
import 'package:zero_koin/services/auth_service.dart';

class SignInSuccessful extends StatefulWidget {
  const SignInSuccessful({super.key});

  @override
  State<SignInSuccessful> createState() => _SignInSuccessfulState();
}

class _SignInSuccessfulState extends State<SignInSuccessful>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Navigate to BottomBar screen after 5 seconds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToHomeScreen();
    });
  }

  void _goToHomeScreen() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Get.offAll(() => const BottomBar());
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final AuthService authService = AuthService.instance;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/Background.jpg', fit: BoxFit.cover),
          // Logo positioned above center
          Positioned(
            top: screenHeight * 0.15,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/bluelogo.png',
                height: 100,
                width: 100,
              ),
            ),
          ),
          // Container centered independently
          Center(
            child: Container(
              width: screenWidth * 0.85,
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.55,
                minHeight: screenHeight * 0.35,
              ),
              margin: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image(
                          image: AssetImage('assets/success_icon.png'),
                          height: screenWidth * 0.2,
                          width: screenWidth * 0.2,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Obx(() => Text(
                          'Welcome Back,\n${authService.userDisplayName?.split(' ').first ?? 'User'}!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blue,
                          ),
                        )),
                        SizedBox(height: screenHeight * 0.015),
                        Obx(() => Text(
                          'Successfully signed in as ${authService.userEmail ?? 'user'}\nYou will be directed to the homepage soon.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.028,
                            color: Colors.black54,
                          ),
                        )),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  SizedBox(
                    width: screenWidth * 0.08,
                    height: screenWidth * 0.08,
                    child: RotationTransition(
                      turns: _animationController,
                      child: Image.asset(
                        'assets/loader.png',
                        fit: BoxFit.contain,
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
