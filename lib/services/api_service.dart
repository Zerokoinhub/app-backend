import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zero_koin/models/course_model.dart';

class ApiService {
  // Update this URL to match your backend deployment
  // For local development: 'http://localhost:3000/api'
  // For Android emulator: 'http://10.0.2.2:3000/api'
  // For iOS simulator: 'http://localhost:3000/api'
  // For production: 'https://your-backend-domain.com/api'
  // https://zerokoinapp-production.up.railway.app/api
  static const String baseUrl =
      'https://zerokoinapp-production.up.railway.app/api';
  // Sync Firebase user to MongoDB
  static Future<Map<String, dynamic>?> syncFirebaseUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ No Firebase user found for sync operation',
        );
        return null;
      }

      // Get Firebase ID token
      final idToken = await user.getIdToken();

      print(
        'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Attempting to sync user ${user.uid} to MongoDB...',
      );
      final response = await http.post(
        Uri.parse('$baseUrl/users/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ User synced successfully: ${data['message']}',
        );
        return data;
      } else if (response.statusCode == 401) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Authentication failed for sync: ${response.statusCode} - ${response.body}',
        );
        return null;
      } else if (response.statusCode == 404) {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ API endpoint not found: ${baseUrl}/users/sync',
        );
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Check if the backend server is running and the route is configured correctly',
        );
        return null;
      } else {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Failed to sync user: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print(
        'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ¸ĂÂĂÂÄÂĂÂ Error syncing user: $e',
      );
      if (e is SocketException) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Network error: Check your internet connection or if the server is running',
        );
      } else if (e is TimeoutException) {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ¸ĂÂĂÂÄÂĂÂ Request timed out: Server may be overloaded or unreachable',
        );
      } else if (e is FormatException) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Response format error: Server returned invalid JSON',
        );
      }
      return null;
    }
  }

  // Get user profile from MongoDB
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ No Firebase user found for profile request',
        );
        return null;
      }

      // Get Firebase ID token
      final idToken = await user.getIdToken();

      print(
        'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Fetching profile for user ${user.uid}...',
      );
      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ User profile fetched successfully',
        );
        return data;
      } else if (response.statusCode == 401) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Authentication failed for profile: ${response.statusCode} - ${response.body}',
        );
        return null;
      } else if (response.statusCode == 404) {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Profile endpoint not found: ${baseUrl}/users/profile',
        );
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Check if the endpoint is implemented in the backend or if the server is running',
        );
        return null;
      } else {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Failed to get user profile: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print(
        'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ¸ĂÂĂÂÄÂĂÂ Error getting user profile: $e',
      );
      if (e is SocketException) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Network error: Check your internet connection or if the server is running',
        );
      } else if (e is TimeoutException) {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ¸ĂÂĂÂÄÂĂÂ Request timed out: Server may be overloaded or unreachable',
        );
      } else if (e is FormatException) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Response format error: Server returned invalid JSON',
        );
      }
      return null;
    }
  }

  // Update wallet address
  static Future<Map<String, dynamic>?> updateWalletAddress(
    String walletType,
    String address,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ No Firebase user found for wallet address update',
        );
        return null;
      }

      // Get Firebase ID token
      final idToken = await user.getIdToken();

      print(
        'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ° Updating $walletType wallet address: $address',
      );

      final requestBody = {'walletType': walletType, 'walletAddress': address};
      final encodedBody = jsonEncode(requestBody);

      print('🔍 Request body: $requestBody');
      print('🔍 Encoded body: $encodedBody');
      print('🔍 Request URL: $baseUrl/users/wallet-address');

      final response = await http.put(
        Uri.parse('$baseUrl/users/wallet-address'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: encodedBody,
      );

      print('Wallet address update response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Wallet address updated successfully',
        );
        return data;
      } else {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Failed to update wallet address: ${response.statusCode}',
        );
        print('Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      print(
        'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Error updating wallet address: $e',
      );
      return null;
    }
  }

  // Get total user count (public endpoint)
  static Future<Map<String, dynamic>?> getUserCount() async {
    try {
      print(
        'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Fetching total user count...',
      );
      final response = await http.get(
        Uri.parse('$baseUrl/users/count'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ User count fetched successfully: [1m${data['count']}[0m',
        );
        return data;
      } else if (response.statusCode == 404) {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ User count endpoint not found: ${baseUrl}/users/count',
        );
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Check if the endpoint is implemented in the backend or if the server is running',
        );
        return null;
      } else {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Failed to get user count: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print(
        'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ¸ĂÂĂÂÄÂĂÂ Error getting user count: $e',
      );
      if (e is SocketException) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Network error: Check your internet connection or if the server is running',
        );
      } else if (e is TimeoutException) {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ¸ĂÂĂÂÄÂĂÂ Request timed out: Server may be overloaded or unreachable',
        );
      } else if (e is FormatException) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Response format error: Server returned invalid JSON',
        );
      }
      return null;
    }
  }

  // Increment calculator usage
  static Future<int?> incrementCalculatorUsage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print(
          'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ No Firebase user found for calculator usage increment',
        );
        return null;
      }
      final idToken = await user.getIdToken();
      print(
        'ĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ§ÄÂÄšÄÄÂĂÂ Incrementing calculator usage for user ${user.uid}...',
      );
      final response = await http.put(
        Uri.parse('$baseUrl/users/calculator-usage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Calculator usage incremented: ${data['calculatorUsage']}',
        );
        return data['calculatorUsage'] as int?;
      } else {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Failed to increment calculator usage: Status: \\${response.statusCode}, Body: \\${response.body}',
        );
        return null;
      }
    } catch (e) {
      print(
        'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Error incrementing calculator usage: $e',
      );
      return null;
    }
  }

  // Get all course names from MongoDB
  static Future<List<String>?> fetchCourseNames() async {
    try {
      print(
        'ÄÂĂÂÄÂĂÂ°ÄÂÄšÄÄÂĂÂ¸ĂÂĂÂÄÂĂÂÄÂĂÂĂÂĂÂĂĹĄĂÂ¤ Fetching course names from backend...',
      );
      final response = await http.get(
        Uri.parse('$baseUrl/courses/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['courseNames'] is List) {
          final List<String> courseNames = List<String>.from(
            data['courseNames'],
          );
          print(
            'ÄÂĂÂÄÂĂÂÄÂÄšÄÄÂĂÂĂÂĂÂÄÂĂÂĂĹĄĂÂ Successfully fetched ${courseNames.length} course names.',
          );
          return courseNames;
        } else {
          print(
            'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Invalid response format for course names: ${response.body}',
          );
          return null;
        }
      } else if (response.statusCode == 404) {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Course names endpoint not found: ${baseUrl}/courses/all',
        );
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂÄšĹž Check if the endpoint is implemented in the backend or if the server is running',
        );
        return null;
      } else {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Failed to fetch course names: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print(
        'ÄÂĂÂÄÂĂÂÄÂÄšÄÄÂĂÂĂÂĂÂÄÂĂÂ ÄÂĂÂĂĹĄÄšÄ˝ĂÂĂÂÄÂĂÂ¸ĂÂĂÂÄÂĂÂ Error fetching course names: $e',
      );
      if (e is SocketException) {
        print(
          'ÄÂĂÂÄÂĂÂ°ÄÂÄšÄÄÂĂÂ¸ÄÂÄšÄÄÂĂÂĂÂĂÂÄÂĂÂ Network error: Check your internet connection or if the server is running',
        );
      } else if (e is TimeoutException) {
        print(
          'ÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂÄÂĂÂĂĹĄÄšÄ˝ĂÂĂÂÄÂĂÂ¸ĂÂĂÂÄÂĂÂ Request timed out: Server may be overloaded or unreachable',
        );
      } else if (e is FormatException) {
        print(
          'ÄÂĂÂÄÂĂÂ°ÄÂÄšÄÄÂĂÂ¸ĂÂĂÂÄÂĂÂÄÂĂÂĂÂĂÂÄÂĂÂ Response format error: Server returned invalid JSON',
        );
      }
      return null;
    }
  }

  // Get course details by name from MongoDB
  static Future<Course?> fetchCourseDetails(String courseName) async {
    try {
      print(
        'ĂÂĂÂ°ĂĹĄĂÂ¸ÄËĂÂĂÂÄÂÄšÂ¤ Fetching details for course: $courseName...',
      );
      final response = await http.get(
        Uri.parse('$baseUrl/courses/$courseName'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['course'] != null) {
          final Course course = Course.fromJson(data['course']);
          print(
            'ĂÂĂÂĂĹĄĂÂÄËĂÂÄšÂ Successfully fetched details for course: ${course.courseName}',
          );
          return course;
        } else {
          print(
            'ĂÂĂÂÄÂĂÂÄÂĂÂ Invalid response format for course details: ${response.body}',
          );
          return null;
        }
      } else if (response.statusCode == 404) {
        print(
          'ĂÂĂÂÄÂĂÂÄÂĂÂ Course details endpoint not found for $courseName: ${baseUrl}/courses/$courseName',
        );
        print(
          'ĂÂĂÂÄÂĂÂÄÂĂĹž Check if the endpoint is implemented in the backend or if the server is running',
        );
        return null;
      } else {
        print(
          'ĂÂĂÂÄÂĂÂÄÂĂÂ Failed to fetch course details: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print(
        'ĂÂĂÂĂĹĄĂÂÄÂĂÂ ĂÂÄšĹĽÄÂĂÂ¸ÄÂĂÂ Error fetching course details: $e',
      );
      if (e is SocketException) {
        print(
          'ĂÂĂÂ°ĂĹĄĂÂ¸ÄÂĂÂÄÂĂÂ Network error: Check your internet connection or if the server is running',
        );
      } else if (e is TimeoutException) {
        print(
          'ĂÂĂÂÄÂĂÂÄÂĂÂĂÂÄšĹĽÄÂĂÂ¸ÄÂĂÂ Request timed out: Server may be overloaded or unreachable',
        );
      } else if (e is FormatException) {
        print(
          'ÄÂĂÂĂĹĄĂÂ¸ÄÂĂÂÄÂĂÂ Response format error: Server returned invalid JSON',
        );
      }
      return null;
    }
  }

  // Complete a session with countdown
  static Future<Map<String, dynamic>?> completeSession(
    int sessionNumber,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for session completion');
        return null;
      }

      final idToken = await user.getIdToken();

      print('Completing session $sessionNumber...');
      final response = await http.post(
        Uri.parse('$baseUrl/users/complete-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'sessionNumber': sessionNumber}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Session $sessionNumber completed successfully');
        return data;
      } else {
        print(
          'Failed to complete session: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error completing session: $e');
      return null;
    }
  }

  // Reset user sessions (for testing)
  static Future<Map<String, dynamic>?> resetUserSessions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for reset sessions request');
        return null;
      }

      final idToken = await user.getIdToken();

      print('Resetting user sessions...');
      final response = await http.post(
        Uri.parse('$baseUrl/users/reset-sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('User sessions reset successfully');
        return data;
      } else {
        print(
          'Failed to reset sessions: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error resetting sessions: $e');
      return null;
    }
  }

  // Get user sessions
  static Future<Map<String, dynamic>?> getUserSessions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for sessions request');
        return null;
      }

      final idToken = await user.getIdToken();

      print('Fetching user sessions...');
      final response = await http.get(
        Uri.parse('$baseUrl/users/sessions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('User sessions fetched successfully');
        return data;
      } else {
        print(
          'Failed to fetch sessions: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error fetching sessions: $e');
      return null;
    }
  }

  // Update FCM token
  static Future<Map<String, dynamic>?> updateFCMToken(
    String fcmToken,
    String? platform,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for FCM token update');
        return null;
      }

      final idToken = await user.getIdToken();

      print('Updating FCM token...');
      final response = await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'fcmToken': fcmToken, 'platform': platform}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('FCM token updated successfully');
        return data;
      } else {
        print(
          'Failed to update FCM token: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error updating FCM token: $e');
      return null;
    }
  }

  // Get server time for time validation
  static Future<Map<String, dynamic>?> getServerTime() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for server time request');
        return null;
      }

      final idToken = await user.getIdToken();

      final response = await http
          .get(
            Uri.parse('$baseUrl/time/server-time'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print(
          'Failed to get server time: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getting server time: $e');
      return null;
    }
  }

  // Validate session timing with server
  static Future<Map<String, dynamic>?> validateSessionTiming(
    int sessionNumber,
    String clientTime,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for session timing validation');
        return null;
      }

      final idToken = await user.getIdToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/time/validate-session'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'sessionNumber': sessionNumber,
              'clientTime': clientTime,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print(
          'Failed to validate session timing: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error validating session timing: $e');
      return null;
    }
  }

  // Update user balance
  static Future<Map<String, dynamic>?> updateUserBalance(int amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for balance update');
        return null;
      }

      final idToken = await user.getIdToken();

      print('Attempting to update user balance by $amount...');
      final response = await http.put(
        Uri.parse('$baseUrl/users/update-balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('User balance updated successfully: ${data['newBalance']}');
        return data;
      } else {
        print(
          'Failed to update user balance. Status Code: ${response.statusCode}',
        );
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating user balance: $e');
      if (e is SocketException) {
        print(
          'Network error: Check your internet connection or if the server is running',
        );
      } else if (e is TimeoutException) {
        print('Request timed out: Server may be overloaded or unreachable');
      } else if (e is FormatException) {
        print('Response format error: Server returned invalid JSON');
      }
      return null;
    }
  }

  // Get all notifications from backend
  static Future<Map<String, dynamic>?> getAllNotifications() async {
    try {
      print('🔄 Fetching all notifications from backend...');

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Successfully fetched notifications from backend');
        return data;
      } else {
        print(
          '❌ Failed to fetch notifications: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return null;
    }
  }

  // Withdraw coins
  static Future<Map<String, dynamic>?> withdrawCoins(
    int amount,
    String walletAddress,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for withdrawal');
        return null;
      }

      final idToken = await user.getIdToken();

      print('Attempting to withdraw $amount coins to $walletAddress...');
      final response = await http.post(
        Uri.parse('$baseUrl/withdraw/withdraw-coins'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'amount': amount, 'walletAddress': walletAddress}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Withdrawal requested successfully: ${data['message']}');
        return data;
      } else {
        print('Failed to withdraw coins. Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error withdrawing coins: $e');
      return null;
    }
  }

  // Get withdrawal transactions
  static Future<Map<String, dynamic>?> getWithdrawalTransactions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for withdrawal transactions');
        return null;
      }

      final idToken = await user.getIdToken();

      print('🔄 Fetching withdrawal transactions from backend...');

      final response = await http.get(
        Uri.parse('$baseUrl/withdraw/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Successfully fetched withdrawal transactions from backend');
        return data;
      } else {
        print(
          '❌ Failed to fetch withdrawal transactions: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Error fetching withdrawal transactions: $e');
      return null;
    }
  }

  // Upload screenshots for social media verification
  static Future<Map<String, dynamic>?> uploadScreenshots(
    List<File> files,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for screenshot upload');
        return null;
      }

      final idToken = await user.getIdToken();

      print('Uploading ${files.length} screenshots...');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/upload-screenshots'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $idToken';

      // Add files to request
      for (int i = 0; i < files.length; i++) {
        var file = files[i];

        // Determine MIME type based on file extension
        String? mimeType;
        String extension = file.path.split('.').last.toLowerCase();
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          default:
            mimeType = 'image/jpeg'; // Default fallback
        }

        var multipartFile = await http.MultipartFile.fromPath(
          'screenshots', // This matches the multer field name
          file.path,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Screenshots uploaded successfully');
        return data;
      } else {
        print(
          'Failed to upload screenshots: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error uploading screenshots: $e');
      return null;
    }
  }

  // Get notifications with read status from backend
  static Future<Map<String, dynamic>?> getNotificationsWithReadStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for notifications with read status');
        return null;
      }

      final idToken = await user.getIdToken();

      print('🔄 Fetching notifications with read status from backend...');

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/with-read-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '✅ Successfully fetched notifications with read status from backend',
        );
        return data;
      } else {
        print(
          '❌ Failed to fetch notifications with read status: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Error fetching notifications with read status: $e');
      return null;
    }
  }

  // Get unread notification count from backend
  static Future<int?> getUnreadNotificationCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for unread notification count');
        return null;
      }

      final idToken = await user.getIdToken();

      print('🔄 Fetching unread notification count from backend...');

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Successfully fetched unread notification count from backend');
        return data['unreadCount'] as int;
      } else {
        print(
          '❌ Failed to fetch unread notification count: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Error fetching unread notification count: $e');
      return null;
    }
  }

  // Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for marking notification as read');
        return false;
      }

      final idToken = await user.getIdToken();

      print('🔄 Marking notification as read...');

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/$notificationId/mark-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Successfully marked notification as read');
        return true;
      } else {
        print(
          '❌ Failed to mark notification as read: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No Firebase user found for marking all notifications as read');
        return false;
      }

      final idToken = await user.getIdToken();

      print('🔄 Marking all notifications as read...');

      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Successfully marked all notifications as read');
        return true;
      } else {
        print(
          '❌ Failed to mark all notifications as read: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      return false;
    }
  }
}
