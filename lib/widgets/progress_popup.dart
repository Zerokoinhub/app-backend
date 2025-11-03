import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controllers/session_controller.dart';

class ProgressPopup extends StatefulWidget {
  final int sessionIndex;
  const ProgressPopup({super.key, this.sessionIndex = 1});

  @override
  State<ProgressPopup> createState() => _ProgressPopupState();
}

class _ProgressPopupState extends State<ProgressPopup> {
  final SessionController _sessionController = Get.find<SessionController>();
  Timer? _timer;
  int _remainingSeconds = 21600; // 6 hours = 21600 seconds
  bool _isTimerRunning = false;
  bool _isClaimed = false;
  static const int _totalSeconds = 21600; // 6 hours = 21600 seconds

  @override
  void initState() {
    super.initState();
    _loadTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEndTime = prefs.getInt(
      'session_${widget.sessionIndex}_timer_end_time',
    );
    final claimed =
        prefs.getBool('session_${widget.sessionIndex}_claimed') ?? false;

    setState(() {
      _isClaimed = claimed;
    });

    if (savedEndTime != null && !claimed) {
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remaining = savedEndTime - currentTime;

      if (remaining > 0) {
        setState(() {
          _remainingSeconds = remaining;
          _isTimerRunning = true;
        });
        _startTimer();
      } else {
        // Timer has expired, can be claimed
        setState(() {
          _remainingSeconds = 0;
          _isTimerRunning = false;
        });
      }
    } else if (!claimed) {
      // No saved timer and not claimed, start a new timer automatically
      _startTimer();
    }
  }

  void _startTimer() {
    if (!_isTimerRunning && _remainingSeconds > 0 && !_isClaimed) {
      setState(() {
        _isTimerRunning = true;
      });
      _saveTimerState();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _stopTimer();
          }
        });
      });
    }
  }

  void _stopTimer() {
    setState(() {
      _isTimerRunning = false;
    });
    _timer?.cancel();
    _saveTimerState();
  }

  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isTimerRunning && _remainingSeconds > 0) {
      final endTime =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) + _remainingSeconds;
      await prefs.setInt(
        'session_${widget.sessionIndex}_timer_end_time',
        endTime,
      );
    }
    await prefs.setBool('session_${widget.sessionIndex}_claimed', _isClaimed);
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Helper methods for session data
  String _getSessionStatus(int sessionIndex) {
    if (_sessionController.isSessionCompleted(sessionIndex)) {
      return 'Claimed';
    } else if (_sessionController.isSessionEnabled(sessionIndex)) {
      // Check if there's an active countdown timer for this session
      if (_sessionController.countdownTimers.containsKey(sessionIndex)) {
        return 'In Progress';
      } else {
        return 'Active';
      }
    } else {
      return 'Locked';
    }
  }

  String _getSessionTime(int sessionIndex) {
    if (_sessionController.isSessionCompleted(sessionIndex)) {
      return 'Completed';
    } else if (_sessionController.isSessionEnabled(sessionIndex)) {
      // Check if there's an active countdown timer for this session
      if (_sessionController.countdownTimers.containsKey(sessionIndex)) {
        final remaining = _sessionController.countdownTimers[sessionIndex]!;
        return _sessionController.formatCountdown(remaining);
      } else {
        return 'Ready';
      }
    } else {
      // Check if there's an active countdown timer for locked sessions
      if (_sessionController.countdownTimers.containsKey(sessionIndex)) {
        final remaining = _sessionController.countdownTimers[sessionIndex]!;
        return _sessionController.formatCountdown(remaining);
      } else {
        return 'Locked';
      }
    }
  }

  bool _isSessionUnlocked(int sessionIndex) {
    return _sessionController.isSessionEnabled(sessionIndex) ||
        _sessionController.isSessionCompleted(sessionIndex);
  }

  String get _statusText {
    if (_isClaimed) {
      return 'Claimed';
    } else if (_remainingSeconds == 0) {
      return 'Ready to Claim';
    } else {
      return 'Progress';
    }
  }

  String get _timeText {
    // Always show the timer countdown, regardless of claimed status
    if (_remainingSeconds == 0) {
      return 'Timer Complete';
    } else {
      return _formatTime(_remainingSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive calculations
    final containerWidth = screenWidth * 0.9;
    final containerPadding = screenWidth * 0.04; // Responsive padding
    final titleFontSize = screenWidth * 0.045; // Responsive title font size
    final headerFontSize = screenWidth * 0.035; // Responsive header font size
    final bodyFontSize = screenWidth * 0.03; // Responsive body font size
    final innerPadding = screenWidth * 0.04; // Responsive inner padding
    final verticalPadding = screenHeight * 0.01; // Responsive vertical padding
    final spacing1 = screenHeight * 0.015; // Responsive spacing
    final spacing2 = screenHeight * 0.01; // Responsive spacing
    final spacing3 = screenHeight * 0.008; // Responsive spacing
    final lockIconSize = screenWidth * 0.05; // Responsive lock icon size
    final closeIconSize = screenWidth * 0.06; // Responsive close icon size

    return Container(
      width: containerWidth,
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
                  ), // Responsive padding
                  child: Center(
                    child: Text(
                      "Track Your ZRK\nProgress",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize, // Responsive font size
                        fontWeight: FontWeight.w900,
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
          SizedBox(height: spacing1), // Responsive spacing
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xff5D5454),
              borderRadius: BorderRadius.circular(
                screenWidth * 0.04,
              ), // Responsive border radius
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: innerPadding, // Responsive padding
                vertical: verticalPadding, // Responsive padding
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column Headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: lockIconSize), // Space for icon
                      SizedBox(width: screenWidth * 0.02), // Spacing
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Session",
                          style: TextStyle(
                            fontSize: headerFontSize, // Responsive font size
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Status",
                          style: TextStyle(
                            fontSize: headerFontSize, // Responsive font size
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Time",
                          style: TextStyle(
                            fontSize: headerFontSize, // Responsive font size
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing3), // Responsive spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(
                        () =>
                            _isSessionUnlocked(1)
                                ? Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: lockIconSize,
                                )
                                : Image(
                                  image: AssetImage("assets/lock.png"),
                                  height: lockIconSize, // Responsive icon size
                                  width: lockIconSize, // Responsive icon size
                                ),
                      ),
                      SizedBox(width: screenWidth * 0.02), // Responsive spacing
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Session 1",
                          style: TextStyle(
                            fontSize: headerFontSize, // Responsive font size
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Obx(
                          () => Text(
                            _getSessionStatus(1),
                            style: TextStyle(
                              fontSize: bodyFontSize, // Responsive font size
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Obx(
                          () => Text(
                            _getSessionTime(1),
                            style: TextStyle(
                              fontSize: bodyFontSize, // Responsive font size
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing2), // Responsive spacing
                  Obx(
                    () => Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ...List.generate(3, (index) {
                          final sessionIndex = index + 2; // Sessions 2, 3, 4
                          final isUnlocked = _isSessionUnlocked(sessionIndex);
                          final status = _getSessionStatus(sessionIndex);
                          final time = _getSessionTime(sessionIndex);

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: spacing3,
                            ), // Responsive vertical padding
                            child: Row(
                              children: [
                                isUnlocked
                                    ? Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: lockIconSize,
                                    )
                                    : Image(
                                      image: AssetImage("assets/lock.png"),
                                      height:
                                          lockIconSize, // Responsive icon size
                                      width:
                                          lockIconSize, // Responsive icon size
                                    ),
                                SizedBox(
                                  width: screenWidth * 0.02,
                                ), // Responsive spacing
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Session $sessionIndex",
                                    style: TextStyle(
                                      fontSize:
                                          headerFontSize, // Responsive font size
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize:
                                          bodyFontSize, // Responsive font size
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    time,
                                    style: TextStyle(
                                      fontSize:
                                          bodyFontSize, // Responsive font size
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
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
