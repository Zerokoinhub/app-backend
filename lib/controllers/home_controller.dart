import 'package:get/get.dart';
import 'package:zero_koin/controllers/user_controller.dart';

class HomeController extends GetxController {
  final UserController userController = Get.find<UserController>();

  // Add any other observable variables or initial data loading specific to HomeScreen here
  // For now, we primarily rely on UserController's observables.

  @override
  void onInit() {
    super.onInit();
    // Initial data loading for HomeScreen, if any
  }

  void refreshData() {
    // This method will be called to refresh data on HomeScreen
    // For now, it will refresh user data which includes balance
    userController.refreshUserData();
    // You can add other refresh logic here if HomeScreen displays other dynamic data
    print('HomeScreen data refreshed!');
  }
}
