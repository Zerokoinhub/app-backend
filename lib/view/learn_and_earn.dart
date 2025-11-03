import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zero_koin/controller/language_controller.dart';
import 'package:zero_koin/controllers/theme_controller.dart';
import 'package:zero_koin/controllers/course_controller.dart'; // Import CourseController
import 'package:zero_koin/view/bottom_bar.dart';

import 'package:zero_koin/widgets/app_bar_container.dart';
import 'package:zero_koin/widgets/learn_and_earn_widget.dart';
import 'package:zero_koin/widgets/my_drawer.dart';
import 'package:zero_koin/widgets/earn_rewards.dart';
import 'package:translator_plus/translator_plus.dart';
import 'package:zero_koin/services/api_service.dart'; // Import ApiService
import 'package:zero_koin/controllers/admob_controller.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class LearnAndEarn extends StatefulWidget {
  const LearnAndEarn({super.key});

  @override
  State<LearnAndEarn> createState() => _LearnAndEarnState();
}

class CourseCategoryData {
  final String originalName;
  final String translatedName;

  CourseCategoryData(this.originalName, this.translatedName);
}

class _LearnAndEarnState extends State<LearnAndEarn> {
  late ScrollController _scrollController;
  double _scrollPosition = 0.0;
  int _currentPageIndex = 0; // New state variable for current page index
  final CourseController _courseController =
      Get.find<CourseController>(); // Get instance of CourseController
  final AdMobController _adMobController = Get.find<AdMobController>();

  final GoogleTranslator _translator = GoogleTranslator();
  String _translatedTitle = '';
  String _translatedContent = '';
  List<CourseCategoryData> _translatedCourseCategories =
      []; // New state variable

  // Timer variables
  Timer? _timer;
  int _remainingSeconds = 120; // Default 2 minutes = 120 seconds
  bool _isTimerRunning = false;
  bool _isTimerPaused = false;

  // Workers for reactive listeners
  Worker? _courseWorker;
  Worker? _languageWorker;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollPosition);

    // Wait for the widget to be built before setting up listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initial load of translated course names
      _loadTranslatedCourseNames();

      // Listen to changes in the selected course and reset timer
      _courseWorker = ever(_courseController.currentCourse, (callback) {
        if (mounted) {
          _resetTimerForNewCourse(); // This will reset to first page with correct time
          _translateCourseContent();
        }
      });

      // Listen to language changes and translate content
      _languageWorker = ever(Get.find<LanguageController>().selectedLanguage, (
        callback,
      ) {
        if (mounted) {
          _translateCourseContent();
          _loadTranslatedCourseNames(); // Re-load course names on language change
        }
      });

      // Initial translation and timer setup
      _translateCourseContent();
      _resetTimerForNewCourse(); // Set initial timer based on current course
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollPosition);
    _scrollController.dispose();
    _timer?.cancel();
    _courseWorker?.dispose();
    _languageWorker?.dispose();
    super.dispose();
  }

  void _updateScrollPosition() {
    setState(() {
      _scrollPosition = _scrollController.offset;
    });
  }

  // Timer methods
  void _startTimer() {
    if (!_isTimerRunning && !_isTimerPaused) {
      setState(() {
        _isTimerRunning = true;
        _isTimerPaused = false;
      });

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

  void _pauseTimer() {
    if (_isTimerRunning) {
      setState(() {
        _isTimerRunning = false;
        _isTimerPaused = true;
      });
      _timer?.cancel();
    }
  }

  void _resumeTimer() {
    if (_isTimerPaused) {
      setState(() {
        _isTimerRunning = true;
        _isTimerPaused = false;
      });

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

  void _stopTimer() async {
    setState(() {
      _isTimerRunning = false;
      _isTimerPaused = false;
      // Don't reset timer - keep it at 0 when countdown completes
    });
    _timer?.cancel();

    // Show loading dialog while updating balance
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0682A2)),
          ),
        );
      },
    );

    try {
      // Increase user balance by 2
      await ApiService.updateUserBalance(2);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();

        // Show EarnRewards popup
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Dialog(
                backgroundColor: Colors.transparent,
                child: EarnRewards(zerokoins: 2),
              ),
            );
          },
        );
      }
    } catch (e) {
      // Handle error - close loading dialog and show error message
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update balance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Parse time string (e.g., "6:35" or "1") to seconds
  int _parseTimeToSeconds(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return 120; // Default 2 minutes
    }

    try {
      // Check if it contains a colon (MM:SS format)
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        if (parts.length == 2) {
          final minutes = int.parse(parts[0]);
          final seconds = int.parse(parts[1]);
          return (minutes * 60) + seconds;
        }
      } else {
        // Single number - treat as minutes
        final minutes = int.parse(timeString);
        return minutes * 60;
      }
    } catch (e) {
      print('Error parsing time string "$timeString": $e');
    }

    return 120; // Default 2 minutes if parsing fails
  }

  // New method to reset the timer state
  void _resetTimer() {
    // Get the time from the current page of the current course
    final course = _courseController.currentCourse.value;
    int timerSeconds = 120; // Default 2 minutes

    if (course != null &&
        course.pages.isNotEmpty &&
        _currentPageIndex < course.pages.length &&
        course.pages[_currentPageIndex].time != null) {
      timerSeconds = _parseTimeToSeconds(course.pages[_currentPageIndex].time);
    }

    setState(() {
      _remainingSeconds = timerSeconds;
      _isTimerRunning = false;
      _isTimerPaused = false;
      _timer?.cancel();
      // Don't reset page index here when just resetting timer for current page
    });
    _translateCourseContent();
  }

  // Method to reset timer when course changes (resets to first page)
  void _resetTimerForNewCourse() {
    setState(() {
      _currentPageIndex = 0; // Reset page index when course changes
    });
    _resetTimer();
  }

  Future<void> _loadTranslatedCourseNames() async {
    final LanguageController languageController =
        Get.find<LanguageController>();
    final String targetLanguageCode = languageController.getLanguageCode(
      languageController.selectedLanguage.value,
    );
    final List<String> originalCourseNames = _courseController.courseNames;
    List<CourseCategoryData> categories = [];

    for (String name in originalCourseNames) {
      try {
        final Translation translation = await _translator.translate(
          name,
          to: targetLanguageCode,
        );
        categories.add(CourseCategoryData(name, translation.text));
      } catch (e) {
        print('Translation error for course name "$name": $e');
        categories.add(
          CourseCategoryData(name, name),
        ); // Fallback to original name on error
      }
    }
    setState(() {
      _translatedCourseCategories = categories;
    });
  }

  Future<void> _translateCourseContent() async {
    final LanguageController languageController =
        Get.find<LanguageController>();
    final String targetLanguageCode = languageController.getLanguageCode(
      languageController.selectedLanguage.value,
    );
    final course = _courseController.currentCourse.value;

    if (course != null && course.pages.isNotEmpty) {
      final String originalTitle = course.pages[_currentPageIndex].title ?? '';
      final String originalContent =
          course.pages[_currentPageIndex].content ?? '';

      try {
        final Translation titleTranslation = await _translator.translate(
          originalTitle,
          to: targetLanguageCode,
        );
        final Translation contentTranslation = await _translator.translate(
          originalContent,
          to: targetLanguageCode,
        );

        setState(() {
          _translatedTitle = titleTranslation.text;
          _translatedContent = contentTranslation.text;
        });
      } catch (e) {
        print('Translation error: $e');
        setState(() {
          _translatedTitle = originalTitle;
          _translatedContent = originalContent;
        });
      }
    } else {
      setState(() {
        _translatedTitle = '';
        _translatedContent = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final ThemeController themeController = Get.find<ThemeController>();
    final LanguageController languageController =
        Get.find<LanguageController>(); // Get instance instead of putting

    return Scaffold(
      drawer: const MyDrawer(),
      body: Stack(
        children: [
          Image.asset(
            'assets/Background.jpg',
            fit: BoxFit.cover,
            height: screenHeight,
            width: screenWidth,
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
                            if (Navigator.canPop(context)) {
                              Get.back();
                            } else {
                              Get.offAll(() => const BottomBar());
                            }
                          },
                          child: const Image(
                            image: AssetImage("assets/arrow_back.png"),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Obx(
                          () => Text(
                            languageController.getTranslation("back"),
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // AdMob Banner Ad for Learn and Earn
                    Obx(() {
                      final ad = _adMobController.learnAndEarnBannerAd;
                      final isReady =
                          _adMobController.isLearnAndEarnBannerAdReady.value;

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
                              ), // same as 0.3.toInt()
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
              const SizedBox(height: 10),
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
                            // Horizontal scrollable row for language and categories
                            SizedBox(
                              height: 35,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    // Language selector
                                    Container(
                                      width: 150,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF0682A2),
                                          width: 2,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Image.asset(
                                              "assets/language.png",
                                              width: 18,
                                              height: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Obx(
                                                () => DropdownButton<String>(
                                                  value:
                                                      languageController
                                                                  .selectedLanguage
                                                                  .value ==
                                                              "Language"
                                                          ? null
                                                          : languageController
                                                              .selectedLanguage
                                                              .value,
                                                  hint: Obx(
                                                    () => Text(
                                                      languageController
                                                          .getTranslation(
                                                            "language",
                                                          ),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize:
                                                            screenWidth < 360
                                                                ? 11
                                                                : 13,
                                                        color:
                                                            themeController
                                                                .textColor,
                                                      ),
                                                      textDirection:
                                                          languageController
                                                                          .selectedLanguage
                                                                          .value ==
                                                                      "Urdu" ||
                                                                  languageController
                                                                          .selectedLanguage
                                                                          .value ==
                                                                      "Arabic"
                                                              ? TextDirection
                                                                  .rtl
                                                              : TextDirection
                                                                  .ltr,
                                                    ),
                                                  ),
                                                  isExpanded: true,
                                                  underline: const SizedBox(),
                                                  icon: Icon(
                                                    Icons.arrow_drop_down,
                                                    color:
                                                        themeController
                                                            .textColor,
                                                    size: 20,
                                                  ),
                                                  selectedItemBuilder: (
                                                    BuildContext context,
                                                  ) {
                                                    return languageController.languages.map<
                                                      Widget
                                                    >((String language) {
                                                      bool isRTL =
                                                          language == "Urdu" ||
                                                          language == "Arabic";
                                                      return Container(
                                                        alignment:
                                                            Alignment
                                                                .centerLeft,
                                                        child: Text(
                                                          language,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize:
                                                                screenWidth <
                                                                        360
                                                                    ? 11
                                                                    : 13,
                                                            color:
                                                                themeController
                                                                    .textColor,
                                                          ),
                                                          textDirection:
                                                              isRTL
                                                                  ? TextDirection
                                                                      .rtl
                                                                  : TextDirection
                                                                      .ltr,
                                                        ),
                                                      );
                                                    }).toList();
                                                  },
                                                  dropdownColor:
                                                      themeController
                                                          .contentBackgroundColor,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        screenWidth < 360
                                                            ? 11
                                                            : 13,
                                                    color:
                                                        themeController
                                                            .textColor,
                                                  ),
                                                  items:
                                                      languageController.languages.asMap().entries.map((
                                                        entry,
                                                      ) {
                                                        // int index = entry.key;
                                                        String language =
                                                            entry.value;
                                                        // bool isLastItem =
                                                        //     index ==
                                                        //     controller
                                                        //             .languages
                                                        //             .length -
                                                        //         1;

                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: language,
                                                          child: Container(
                                                            width:
                                                                double.infinity,
                                                            margin:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 4.0,
                                                                  horizontal:
                                                                      8.0,
                                                                ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical:
                                                                      12.0,
                                                                  horizontal:
                                                                      16.0,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              border: Border.all(
                                                                color:
                                                                    const Color(
                                                                      0xFFC4B0B0,
                                                                    ),
                                                                width: 1.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8.0,
                                                                  ),
                                                            ),
                                                            child: Align(
                                                              alignment:
                                                                  Alignment
                                                                      .centerLeft,
                                                              child: Text(
                                                                language,
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      screenWidth <
                                                                              360
                                                                          ? 11
                                                                          : 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      themeController
                                                                          .textColor,
                                                                ),
                                                                textDirection:
                                                                    language ==
                                                                                "Urdu" ||
                                                                            language ==
                                                                                "Arabic"
                                                                        ? TextDirection
                                                                            .rtl
                                                                        : TextDirection
                                                                            .ltr,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                  onChanged: (
                                                    String? newValue,
                                                  ) {
                                                    if (newValue != null) {
                                                      languageController
                                                          .selectLanguage(
                                                            newValue,
                                                          );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Dynamic Course Categories
                                    Row(
                                      children:
                                          _translatedCourseCategories
                                              .map(
                                                (categoryData) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 12.0,
                                                      ),
                                                  child: SizedBox(
                                                    width: 150,
                                                    child: LearnAndEarnWidget(
                                                      title:
                                                          categoryData
                                                              .translatedName,
                                                      originalTitle:
                                                          categoryData
                                                              .originalName,
                                                      isSelected: _courseController
                                                          .isCategorySelected(
                                                            categoryData
                                                                .originalName,
                                                          ),
                                                      onPressed: () async {
                                                        showDialog(
                                                          context: context,
                                                          barrierDismissible:
                                                              false,
                                                          builder: (
                                                            BuildContext
                                                            context,
                                                          ) {
                                                            return const Center(
                                                              child: CircularProgressIndicator(
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                      Color
                                                                    >(
                                                                      Color(
                                                                        0xFF0682A2,
                                                                      ),
                                                                    ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                        _courseController
                                                            .selectCategory(
                                                              categoryData
                                                                  .originalName,
                                                            );
                                                        await _translateCourseContent();
                                                        if (mounted) {
                                                          Navigator.of(
                                                            context,
                                                            rootNavigator: true,
                                                          ).pop();
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                  child: Obx(
                                    () => Text(
                                      languageController.getTranslation(
                                        "earn_koins_daily",
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth < 360 ? 16 : 18,
                                        color: themeController.textColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Container(
                              height: screenHeight * 0.39,
                              width: screenWidth,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.black,
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Obx(() {
                                          final course =
                                              _courseController
                                                  .currentCourse
                                                  .value;
                                          if (course == null ||
                                              course.pages.isEmpty) {
                                            return Text(
                                              languageController.getTranslation(
                                                "no_content_available",
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            );
                                          }
                                          return Text(
                                            'Page ${_currentPageIndex + 1}/${course.pages.length}',
                                            style: const TextStyle(
                                              color: Color(0xFFF3E9E9),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          );
                                        }),
                                        Obx(() {
                                          final course =
                                              _courseController
                                                  .currentCourse
                                                  .value;
                                          if (course == null ||
                                              course.pages.isEmpty ||
                                              _currentPageIndex >=
                                                  course.pages.length) {
                                            return Text(
                                              languageController.getTranslation(
                                                "block_number",
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            );
                                          }
                                          return Text(
                                            _translatedTitle.isNotEmpty
                                                ? _translatedTitle
                                                : (course
                                                        .pages[_currentPageIndex]
                                                        .title ??
                                                    ''),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          );
                                        }),
                                        SizedBox(height: 20),
                                        Expanded(
                                          child: Container(
                                            width: screenWidth * 0.8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: const Color.fromARGB(
                                                255,
                                                48,
                                                48,
                                                48,
                                              ),
                                            ),
                                            child: SingleChildScrollView(
                                              controller: _scrollController,
                                              padding: const EdgeInsets.all(15),
                                              child: Obx(() {
                                                final course =
                                                    _courseController
                                                        .currentCourse
                                                        .value;
                                                if (course == null ||
                                                    course.pages.isEmpty ||
                                                    _currentPageIndex >=
                                                        course.pages.length) {
                                                  return Text(
                                                    languageController
                                                        .getTranslation(
                                                          "select_a_course",
                                                        ),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      height: 1.5,
                                                    ),
                                                  );
                                                }
                                                return Text(
                                                  _translatedContent.isNotEmpty
                                                      ? _translatedContent
                                                      : (course
                                                              .pages[_currentPageIndex]
                                                              .content ??
                                                          ''),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    height: 1.5,
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Custom Functional Scrollbar
                                  Positioned(
                                    right: 10,
                                    top: 80,
                                    bottom: 20,
                                    child: _buildCustomScrollbar(screenHeight),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(
                                  0xFF0C091E,
                                ), // Changed to const Color
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Obx(
                                          () => Text(
                                            languageController.getTranslation(
                                              "timer",
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTime(_remainingSeconds),
                                          style: const TextStyle(
                                            // Added const
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(), // Added const
                                    GestureDetector(
                                      onTap:
                                          _remainingSeconds == 0
                                              ? null
                                              : () {
                                                if (!_isTimerRunning &&
                                                    !_isTimerPaused) {
                                                  _startTimer();
                                                } else if (_isTimerRunning) {
                                                  _pauseTimer();
                                                } else if (_isTimerPaused) {
                                                  _resumeTimer();
                                                }
                                              },
                                      child: Container(
                                        height: 45,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          color:
                                              _remainingSeconds == 0
                                                  ? Colors.grey.withOpacity(0.5)
                                                  : const Color(0xFF393746),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _remainingSeconds == 0
                                                ? Icons.check_circle_outline
                                                : (_isTimerRunning
                                                    ? Icons.pause_circle_outline
                                                    : Icons
                                                        .play_circle_outline),
                                            color:
                                                _remainingSeconds == 0
                                                    ? Colors.grey
                                                    : Colors.white,
                                            size: 25,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.4,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF0682A2),
                                      ), // Added const
                                      backgroundColor:
                                          themeController
                                              .contentBackgroundColor,
                                      foregroundColor: const Color(
                                        0xFF0682A2,
                                      ), // Added const
                                    ),
                                    onPressed: () {
                                      if (_currentPageIndex > 0) {
                                        setState(() {
                                          _currentPageIndex--;
                                        });
                                        _resetTimer(); // Reset timer with correct page duration
                                      }
                                    },
                                    child: Obx(
                                      () => Text(
                                        languageController.getTranslation(
                                          "previous",
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: screenWidth * 0.4,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: BorderSide(
                                        color:
                                            themeController
                                                .contentBackgroundColor,
                                      ),
                                      backgroundColor:
                                          _remainingSeconds == 0
                                              ? const Color(
                                                0xFF0682A2,
                                              ) // Added const
                                              : Colors.grey,
                                      foregroundColor:
                                          _remainingSeconds == 0
                                              ? Colors.white
                                              : Colors.white70,
                                    ),
                                    onPressed:
                                        _remainingSeconds == 0
                                            ? () {
                                              // Add your next button functionality here
                                              print(
                                                "Next button pressed - Timer completed!",
                                              );
                                              final course =
                                                  _courseController
                                                      .currentCourse
                                                      .value;
                                              if (course != null &&
                                                  _currentPageIndex <
                                                      course.pages.length - 1) {
                                                setState(() {
                                                  _currentPageIndex++;
                                                });
                                                _resetTimer(); // Reset timer with correct page duration
                                              }
                                            }
                                            : null,
                                    child: Obx(
                                      () => Text(
                                        languageController.getTranslation(
                                          "next",
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildCustomScrollbar(double screenHeight) {
    // Calculate available height for scrollbar (container height minus padding)
    double availableHeight =
        screenHeight * 0.39 -
        100; // Updated container height minus top/bottom padding

    if (!_scrollController.hasClients) {
      return Container(
        width: 8,
        height: availableHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      );
    }

    // Get scroll metrics
    double maxScrollExtent = _scrollController.position.maxScrollExtent;
    double viewportDimension = _scrollController.position.viewportDimension;
    double totalContentHeight = maxScrollExtent + viewportDimension;

    // Calculate scrollbar thumb height based on content ratio
    double thumbHeight =
        (viewportDimension / totalContentHeight) * availableHeight;
    thumbHeight = thumbHeight.clamp(
      20.0,
      availableHeight * 0.8,
    ); // Min 20px, max 80% of track

    // Calculate thumb position
    double thumbPosition = 0.0;
    if (maxScrollExtent > 0) {
      double scrollRatio = _scrollPosition / maxScrollExtent;
      thumbPosition = scrollRatio * (availableHeight - thumbHeight);
      thumbPosition = thumbPosition.clamp(0.0, availableHeight - thumbHeight);
    }

    return Container(
      width: 8,
      height: availableHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.withValues(alpha: 0.3),
      ),
      child: Stack(
        children: [
          Positioned(
            top: thumbPosition,
            child: Container(
              width: 8,
              height: thumbHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF0682A2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
