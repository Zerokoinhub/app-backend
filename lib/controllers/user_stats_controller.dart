import 'package:get/get.dart';
import 'package:zero_koin/services/api_service.dart';

class UserStatsController extends GetxController {
  static UserStatsController get instance => Get.find();
  
  // Observable user count
  final RxInt totalUsers = 0.obs;
  
  // Loading state
  final RxBool isLoading = false.obs;
  
  // Error state
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Load user count when controller is initialized
    fetchUserCount();
  }
  
  // Fetch total user count from the backend
  Future<void> fetchUserCount() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final data = await ApiService.getUserCount();
      
      if (data != null && data['count'] != null) {
        totalUsers.value = data['count'];
        print('User count loaded: ${totalUsers.value}');
      } else {
        error.value = 'Failed to load user count';
        print('Failed to load user count from API');
      }
    } catch (e) {
      error.value = 'Error: ${e.toString()}';
      print('Error fetching user count: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Refresh user count (can be called manually)
  Future<void> refreshUserCount() async {
    await fetchUserCount();
  }
  
  // Get formatted user count as string
  String get formattedUserCount {
    if (isLoading.value) {
      return 'Loading...';
    } else if (error.value.isNotEmpty || totalUsers.value == 0) {
      // Fallback to original hardcoded value if API fails or returns 0
      return '77853';
    } else {
      return totalUsers.value.toString();
    }
  }
}
