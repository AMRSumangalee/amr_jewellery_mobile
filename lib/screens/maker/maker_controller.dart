import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_order_management/models/maker_model.dart';
import 'package:jewellery_order_management/repositories/maker_repository.dart';

class MakerController extends GetxController {
  final MakerRepository _repository = MakerRepository();

  final makers = <MakerModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final togglingIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadMakers();
  }

  Future<void> loadMakers() async {
    isLoading.value = true;
    try {
      final result = await _repository.getMakers();
      makers.assignAll(result);
    } catch (e) {
      debugPrint('LOAD MAKERS ERROR => $e');
      Get.snackbar(
        'Error',
        'Unable to load makers. Please check the API connection.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveMaker({
    int? id,
    required String name,
    String? phone,
    String? whatsappNumber,
    String? specialization,
  }) async {
    if (name.trim().isEmpty) {
      Get.snackbar(
        'Validation',
        'Maker name is required.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSaving.value = true;
    try {
      if (id == null) {
        await _repository.createMaker(
          name: name,
          phone: phone,
          whatsappNumber: whatsappNumber,
          specialization: specialization,
        );
      } else {
        await _repository.updateMaker(
          id: id,
          name: name,
          phone: phone,
          whatsappNumber: whatsappNumber,
          specialization: specialization,
        );
      }

      await loadMakers();
      Get.back();
      Get.snackbar(
        'Success',
        id == null
            ? 'Maker created successfully.'
            : 'Maker updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('SAVE MAKER ERROR => $e');
      Get.snackbar(
        'Error',
        'Unable to save maker. Check duplicate WhatsApp number and API response.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleStatus(MakerModel maker) async {
    if (togglingIds.contains(maker.id)) return;
    togglingIds.add(maker.id);

    try {
      await _repository.updateMakerStatus(
        id: maker.id,
        status: !maker.status,
      );
      final updated = await _repository.getMakers();
      makers.assignAll(updated);

      Get.snackbar(
        'Success',
        '${maker.name} ${!maker.status ? 'activated' : 'deactivated'} successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('TOGGLE MAKER STATUS ERROR => $e');
      Get.snackbar(
        'Error',
        'Unable to update maker status.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      togglingIds.remove(maker.id);
    }
  }
}
