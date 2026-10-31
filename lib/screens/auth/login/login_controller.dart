import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jewellery_order_management/repositories/auth_repository.dart';
import 'package:jewellery_order_management/routes/app_routes.dart';
import 'package:jewellery_order_management/services/storage_service.dart';

class LoginController extends GetxController {
  final AuthRepository _repository = AuthRepository();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  final isLoading = false.obs;
  final obscurePassword = true.obs;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty) {
      Get.snackbar(
        'Validation',
        'Please enter username',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (password.isEmpty) {
      Get.snackbar(
        'Validation',
        'Please enter password',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      final result = await _repository.login(
        username: username,
        password: password,
      );

      print(result.message);

      if (!result.success || result.token.isEmpty) {
        Get.snackbar(
          'Login Failed',
          result.message.isNotEmpty
              ? result.message
              : 'Invalid username or password',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // ========================================================
      // SAVE SESSION
      // ========================================================

      await StorageService.saveToken(result.token);
      await StorageService.saveUser(result.user);
      Get.offAllNamed(AppRoutes.dashboard);
      Get.snackbar(
        'Success',
        result.message.isNotEmpty ? result.message : 'Login successful',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Dashboard will be added next.
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to login. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // PASSWORD VISIBILITY
  // ============================================================

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
