import 'package:get/get.dart';
import 'package:traffic_app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:traffic_app/routes/app_pages.dart';

class HomeController extends GetxController {
  // Bottom Navigation State
  var currentIndex = 0.obs;
  final bool _mapTabVisited = false;

  // Upload Progress State
  var isUploading = false.obs;
  var uploadProgress = 0.0.obs;
  var uploadLabel = 'Đăng bài viết'.obs;

  void changeTab(int index) {
    if (index == 0 && currentIndex.value == 0) {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().scrollToTop();
      }
      return;
    }
    currentIndex.value = index;
    // if (index == 1 && !_mapTabVisited) {
    //   _mapTabVisited = true;
    //   Future.delayed(const Duration(milliseconds: 200), () {
    //     if (Get.isRegistered<MapController>()) {
    //       Get.find<MapController>().toggleMapType();
    //     }
    //   });
    // }
  }

  void goToEditProfile() {
    Get.toNamed(Routes.PROFILE);
  }

  // Upload Progress Methods
  void startUpload({String label = 'Đăng bài viết'}) {
    uploadLabel.value = label;
    isUploading.value = true;
    uploadProgress.value = 0.0;
  }

  void updateUploadProgress(double progress) {
    uploadProgress.value = progress;
  }

  void completeUpload() {
    uploadProgress.value = 1.0;
    // Delay để hiển thị 100% trước khi ẩn
    Future.delayed(const Duration(milliseconds: 500), () {
      isUploading.value = false;
      uploadProgress.value = 0.0;
    });
  }

  void cancelUpload() {
    isUploading.value = false;
    uploadProgress.value = 0.0;
  }
}
