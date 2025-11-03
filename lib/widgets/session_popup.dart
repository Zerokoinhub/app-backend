import 'package:flutter/material.dart';
import 'package:zero_koin/widgets/gift_popup.dart';
import 'dart:ui';
import 'package:get/get.dart';

import 'package:zero_koin/widgets/progress_popup.dart';

import 'package:zero_koin/controllers/session_controller.dart';

class SessionPopup extends StatefulWidget {
  const SessionPopup({super.key});

  @override
  State<SessionPopup> createState() => _SessionPopupState();
}

class _SessionPopupState extends State<SessionPopup> {
  int? _activeSessionIndex;
  late SessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _sessionController = Get.put(SessionController());
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isSessionEnabled(int sessionIndex) {
    return _sessionController.isSessionEnabled(sessionIndex);
  }

  bool _isSessionCompleted(int sessionIndex) {
    return _sessionController.isSessionCompleted(sessionIndex);
  }

  String _getSessionDisplayText(int sessionIndex) {
    return _sessionController.getSessionDisplayText(sessionIndex);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive calculations
    final containerWidth = screenWidth * 0.8;
    final containerPadding = screenWidth * 0.05;
    final titleFontSize = screenWidth * 0.04;
    final sessionButtonHeight = screenHeight * 0.07;
    final sessionFontSize = screenWidth * 0.045;
    final verticalSpacing = screenHeight * 0.015;
    final closeIconSize = screenWidth * 0.06;

    // Calculate minimum required height (simplified)
    final headerHeight = screenHeight * 0.05; // Estimate header height
    final totalSessionsHeight = sessionButtonHeight * 4; // 4 session buttons
    final totalSpacing = verticalSpacing * 5; // 5 spacing elements
    final totalPadding = containerPadding * 2; // Top and bottom padding
    final minRequiredHeight =
        headerHeight + totalSessionsHeight + totalSpacing + totalPadding;

    // Use calculated height but ensure it doesn't exceed screen bounds and has a minimum
    final containerHeight =
        (minRequiredHeight > screenHeight * 0.8)
            ? screenHeight * 0.8
            : (minRequiredHeight < screenHeight * 0.4
                ? screenHeight * 0.4
                : minRequiredHeight);

    return Container(
      width: containerWidth,
      height: containerHeight,
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 5, 14, 22),
        borderRadius: BorderRadius.circular(
          screenWidth * 0.05,
        ), // Responsive border radius
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.01,
                  ), // Adjust padding
                  child: Center(
                    child: Text(
                      "Complete your session\nevery 6 hours",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: Colors.white,
                iconSize: closeIconSize, // Responsive icon size
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          SizedBox(height: verticalSpacing),
          Obx(
            () => GestureDetector(
              onTap: () async {
                // If session is enabled and not completed, show normal flow (GiftPopup -> TimerPopup)
                if (_isSessionEnabled(1) && !_isSessionCompleted(1)) {
                  setState(() {
                    _activeSessionIndex = 1;
                  });
                  Navigator.of(context).pop(); // Dismiss SessionPopup

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    showDialog(
                      context: Get.context!,
                      builder: (BuildContext context) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Dialog(
                            backgroundColor: Colors.transparent,
                            child: GiftPopup(sessionNumber: 1),
                          ),
                        );
                      },
                    );
                  });
                } else {
                  // If session is locked or completed, show ProgressPopup
                  Navigator.of(context).pop(); // Dismiss SessionPopup
                  showDialog(
                    context: Get.context!,
                    builder: (BuildContext context) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Dialog(
                          backgroundColor: Colors.transparent,
                          child: ProgressPopup(sessionIndex: 1),
                        ),
                      );
                    },
                  );
                }
              },
              child: Container(
                width: double.infinity,
                height: sessionButtonHeight,
                decoration: BoxDecoration(
                  color:
                      _isSessionCompleted(1)
                          ? Colors
                              .grey[400]! // Completed sessions are dark grey
                          : _isSessionEnabled(1)
                          ? const Color(
                            0xFF0682A2,
                          ) // Unlocked sessions are teal
                          : Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(
                    screenWidth * 0.04,
                  ), // Responsive border radius
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getSessionDisplayText(1),
                        style: TextStyle(
                          fontSize: sessionFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Image.asset(
                        "assets/session_clock.png",
                        height:
                            sessionFontSize, // Responsive image size based on text
                        width:
                            sessionFontSize, // Responsive image size based on text
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: verticalSpacing),
          Obx(
            () => GestureDetector(
              onTap: () async {
                // If session is enabled and not completed, show normal flow (GiftPopup -> TimerPopup)
                if (_isSessionEnabled(2) && !_isSessionCompleted(2)) {
                  setState(() {
                    _activeSessionIndex = 2;
                  });
                  Navigator.of(context).pop(); // Dismiss SessionPopup

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    showDialog(
                      context: Get.context!,
                      builder: (BuildContext context) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Dialog(
                            backgroundColor: Colors.transparent,
                            child: GiftPopup(sessionNumber: 2),
                          ),
                        );
                      },
                    );
                  });
                } else {
                  // If session is locked or completed, show ProgressPopup
                  Navigator.of(context).pop(); // Dismiss SessionPopup
                  showDialog(
                    context: Get.context!,
                    builder: (BuildContext context) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Dialog(
                          backgroundColor: Colors.transparent,
                          child: ProgressPopup(sessionIndex: 2),
                        ),
                      );
                    },
                  );
                }
              },
              child: Container(
                width: double.infinity,
                height: sessionButtonHeight,
                decoration: BoxDecoration(
                  color:
                      _isSessionCompleted(2)
                          ? Colors
                              .grey[400]! // Completed sessions are dark grey
                          : _isSessionEnabled(2)
                          ? const Color(
                            0xFF0682A2,
                          ) // Unlocked sessions are teal
                          : Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(
                    screenWidth * 0.04,
                  ), // Responsive border radius
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getSessionDisplayText(2),
                        style: TextStyle(
                          fontSize: sessionFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Image.asset(
                        "assets/session_clock.png",
                        height:
                            sessionFontSize, // Responsive image size based on text
                        width:
                            sessionFontSize, // Responsive image size based on text
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: verticalSpacing),
          Obx(
            () => GestureDetector(
              onTap: () async {
                // If session is enabled and not completed, show normal flow (GiftPopup -> TimerPopup)
                if (_isSessionEnabled(3) && !_isSessionCompleted(3)) {
                  setState(() {
                    _activeSessionIndex = 3;
                  });
                  Navigator.of(context).pop(); // Dismiss SessionPopup

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    showDialog(
                      context: Get.context!,
                      builder: (BuildContext context) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Dialog(
                            backgroundColor: Colors.transparent,
                            child: GiftPopup(sessionNumber: 3),
                          ),
                        );
                      },
                    );
                  });
                } else {
                  // If session is locked or completed, show ProgressPopup
                  Navigator.of(context).pop(); // Dismiss SessionPopup
                  showDialog(
                    context: Get.context!,
                    builder: (BuildContext context) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Dialog(
                          backgroundColor: Colors.transparent,
                          child: ProgressPopup(sessionIndex: 3),
                        ),
                      );
                    },
                  );
                }
              },
              child: Container(
                width: double.infinity,
                height: sessionButtonHeight,
                decoration: BoxDecoration(
                  color:
                      _isSessionCompleted(3)
                          ? Colors
                              .grey[300]! // Completed sessions are dark grey
                          : _isSessionEnabled(3)
                          ? const Color(
                            0xFF0682A2,
                          ) // Unlocked sessions are teal
                          : Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(
                    screenWidth * 0.04,
                  ), // Responsive border radius
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getSessionDisplayText(3),
                        style: TextStyle(
                          fontSize: sessionFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Image.asset(
                        "assets/session_clock.png",
                        height:
                            sessionFontSize, // Responsive image size based on text
                        width:
                            sessionFontSize, // Responsive image size based on text
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: verticalSpacing),
          Obx(
            () => GestureDetector(
              onTap: () async {
                // If session is enabled and not completed, show normal flow (GiftPopup -> TimerPopup)
                if (_isSessionEnabled(4) && !_isSessionCompleted(4)) {
                  setState(() {
                    _activeSessionIndex = 4;
                  });
                  Navigator.of(context).pop(); // Dismiss SessionPopup

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    showDialog(
                      context: Get.context!,
                      builder: (BuildContext context) {
                        return BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Dialog(
                            backgroundColor: Colors.transparent,
                            child: GiftPopup(sessionNumber: 4),
                          ),
                        );
                      },
                    );
                  });
                } else {
                  // If session is locked or completed, show ProgressPopup
                  Navigator.of(context).pop(); // Dismiss SessionPopup
                  showDialog(
                    context: Get.context!,
                    builder: (BuildContext context) {
                      return BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Dialog(
                          backgroundColor: Colors.transparent,
                          child: ProgressPopup(sessionIndex: 4),
                        ),
                      );
                    },
                  );
                }
              },
              child: Container(
                width: double.infinity,
                height: sessionButtonHeight,
                decoration: BoxDecoration(
                  color:
                      _isSessionCompleted(4)
                          ? Colors
                              .grey[300]! // Completed sessions are dark grey
                          : _isSessionEnabled(4)
                          ? const Color(
                            0xFF0682A2,
                          ) // Unlocked sessions are teal
                          : Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(
                    screenWidth * 0.04,
                  ), // Responsive border radius
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getSessionDisplayText(4),
                        style: TextStyle(
                          fontSize: sessionFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Image.asset(
                        "assets/session_clock.png",
                        height:
                            sessionFontSize, // Responsive image size based on text
                        width:
                            sessionFontSize, // Responsive image size based on text
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
