import 'package:get/get.dart';
import 'package:zero_koin/services/api_service.dart';
import 'package:zero_koin/models/course_model.dart'; // Import the Course model

class CourseController extends GetxController {
  var courseNames = <String>[].obs;
  var isLoading = true.obs;
  var selectedCategory = ''.obs;
  var currentCourse =
      Rxn<Course>(); // Observable for the current selected course

  @override
  void onInit() {
    super.onInit();
    fetchCourseNames().then((_) {
      if (courseNames.isNotEmpty) {
        // Fetch details for the initially selected category
        fetchCourseDetails(courseNames.first);
      }
    });
  }

  Future<void> fetchCourseNames() async {
    try {
      isLoading(true);
      var fetchedNames = await ApiService.fetchCourseNames();
      if (fetchedNames != null) {
        courseNames.assignAll(fetchedNames);
        if (courseNames.isNotEmpty) {
          selectedCategory.value =
              courseNames.first; // Select the first category by default
        }
      }
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchCourseDetails(String name) async {
    try {
      isLoading(true); // Indicate loading for course details
      var course = await ApiService.fetchCourseDetails(name);
      if (course != null) {
        currentCourse.value = course;
      } else {
        currentCourse.value = null;
      }
    } finally {
      isLoading(false);
    }
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    fetchCourseDetails(category); // Fetch details when category changes
  }

  bool isCategorySelected(String category) {
    return selectedCategory.value == category;
  }
}
