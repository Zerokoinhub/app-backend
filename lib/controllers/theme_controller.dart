import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';
  
  final RxBool _isDarkMode = false.obs;
  
  bool get isDarkMode => _isDarkMode.value;

  // Theme data
  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: const Color(0xFF0682A2),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
      titleSmall: TextStyle(color: Colors.black87),
    ),
    iconTheme: const IconThemeData(color: Colors.black87),
    dividerColor: Colors.grey.shade300,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0682A2),
      brightness: Brightness.light,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: const Color(0xFF0682A2),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[900],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerColor: Colors.grey[700],
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0682A2),
      brightness: Brightness.dark,
    ),
  );

  // Custom colors for the app
  Color get backgroundColor => isDarkMode ? Colors.black : Colors.white;
  Color get contentBackgroundColor =>
      isDarkMode ? Colors.grey[900]! : Colors.white;
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color get subtitleColor => isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
  Color get borderColor =>
      isDarkMode ? Colors.grey[700]! : Colors.grey.shade300;
  Color get cardColor => isDarkMode ? Colors.grey[900]! : Colors.white;

  // Gradient colors (these remain the same for both themes)
  List<Color> get gradientColors => [
    const Color(0xFF08647C),
    const Color(0xFF08627A),
    const Color(0xFF8B880D),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }

  // Toggle theme
  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeTheme(isDarkMode ? darkTheme : lightTheme);
    _saveThemeToPrefs();
  }

  // Set theme directly
  void setTheme(bool isDark) {
    _isDarkMode.value = isDark;
    Get.changeTheme(isDarkMode ? darkTheme : lightTheme);
    _saveThemeToPrefs();
  }

  // Load theme preference from SharedPreferences
  void _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getBool(_themeKey) ?? false;
      _isDarkMode.value = savedTheme;
      Get.changeTheme(isDarkMode ? darkTheme : lightTheme);
    } catch (e) {
      // Silently fail and use default theme
      _isDarkMode.value = false;
    }
  }

  // Save theme preference to SharedPreferences
  void _saveThemeToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode.value);
    } catch (e) {
      // Silently fail - theme will still work for current session
    }
  }
}
