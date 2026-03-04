import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/login_request.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_pages.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/custom_dialog.dart';

class LoginController extends GetxController {
  var rememberMe = false.obs;
  var isLoading = false.obs;
  var isPasswordHidden = true.obs;

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final StorageService _storageService = Get.find<StorageService>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final usernameFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    // Clear focus and keyboard state on init to prevent keyboard event issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      usernameFocusNode.unfocus();
      passwordFocusNode.unfocus();
    });
  }

  @override
  void onClose() {
    // Unfocus before disposing to clear keyboard state
    usernameFocusNode.unfocus();
    passwordFocusNode.unfocus();

    usernameController.dispose();
    passwordController.dispose();
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    super.onClose();
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login() async {
    // Unfocus all text fields to hide keyboard and clear keyboard state
    usernameFocusNode.unfocus();
    passwordFocusNode.unfocus();

    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      CustomDialog.show(
        title: 'notice_title'.tr,
        message: 'login_fill_info'.tr,
        type: DialogType.warning,
      );
      return;
    }

    isLoading.value = true;

    try {
      final loginResponse = await _authRepository.login(
        LoginRequest(
          username: usernameController.text.trim(),
          password: passwordController.text,
        ),
      );

      // Save user information
      await _storageService.saveUserInfo(
        userId: loginResponse.id,
        username: loginResponse.username,
        fullName: loginResponse.fullName,
        province: loginResponse.province,
        relativePhone: loginResponse.relativePhone,
      );

      // Save credentials for auto-login if rememberMe is checked
      if (rememberMe.value) {
        await _storageService.saveCredentials(
          usernameController.text.trim(),
          passwordController.text,
        );
      } else {
        await _storageService.clearCredentials();
      }

      // Navigate to home page on successful login
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      CustomDialog.show(
        title: 'login_failed_title'.tr,
        message: e.toString(),
        type: DialogType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
