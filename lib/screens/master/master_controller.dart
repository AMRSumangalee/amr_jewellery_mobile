import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_order_management/models/master_data_model.dart';
import 'package:jewellery_order_management/repositories/master_data_repository.dart';

class MasterController extends GetxController {
  final MasterDataRepository _repository = MasterDataRepository();

  final selectedTab = 0.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final togglingIds = <int>{}.obs;

  final metals = <MasterDataModel>[].obs;
  final categories = <MasterDataModel>[].obs;
  final repairTypes = <MasterDataModel>[].obs;

  MasterDataType get currentType {
    switch (selectedTab.value) {
      case 1:
        return MasterDataType.categories;
      case 2:
        return MasterDataType.repairTypes;
      default:
        return MasterDataType.metals;
    }
  }

  String get currentTitle {
    switch (currentType) {
      case MasterDataType.metals:
        return 'Metals';
      case MasterDataType.categories:
        return 'Categories';
      case MasterDataType.repairTypes:
        return 'Repair Types';
    }
  }

  RxList<MasterDataModel> get currentItems {
    switch (currentType) {
      case MasterDataType.metals:
        return metals;
      case MasterDataType.categories:
        return categories;
      case MasterDataType.repairTypes:
        return repairTypes;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _repository.getItems(MasterDataType.metals),
        _repository.getItems(MasterDataType.categories),
        _repository.getItems(MasterDataType.repairTypes),
      ]);
      metals.assignAll(results[0]);
      categories.assignAll(results[1]);
      repairTypes.assignAll(results[2]);
    } catch (e) {
      debugPrint('LOAD MASTER DATA ERROR => $e');
      Get.snackbar(
        'Error',
        'Unable to load master data. Please check the API.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveItem({
    int? id,
    required String name,
    required String code,
    required bool status,
  }) async {
    final cleanName = name.trim();
    final cleanCode = code.trim();

    if (cleanName.isEmpty || cleanCode.isEmpty) {
      Get.snackbar(
        'Validation',
        'Name and code are required.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isSaving.value) return;
    isSaving.value = true;

    // Capture the title now, in case the tab changes while saving.
    final title = currentTitle;
    final type = currentType;

    try {
      if (id == null) {
        await _repository.createItem(
          type: type,
          name: cleanName,
          code: cleanCode,
          status: status,
        );
      } else {
        await _repository.updateItem(
          type: type,
          id: id,
          name: cleanName,
          code: cleanCode,
          status: status,
        );
      }

      // Close the dialog first, then refresh the list.
      if (Get.isDialogOpen ?? false) Get.back();

      await _loadByType(type);

      Get.snackbar(
        'Success',
        id == null
            ? '$title item created successfully.'
            : '$title item updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('SAVE MASTER DATA ERROR => $e');
      Get.snackbar(
        'Error',
        'Unable to save item. Check name/code and backend response.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleStatus(MasterDataModel item) async {
    if (togglingIds.contains(item.id)) return;
    togglingIds.add(item.id);

    final type = currentType;
    final newStatus = !item.status;

    try {
      await _repository.updateStatus(
        type: type,
        id: item.id,
        status: newStatus,
      );

      await _loadByType(type); // only once now

      Get.snackbar(
        'Success',
        '${item.name} ${newStatus ? 'activated' : 'deactivated'} successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('TOGGLE MASTER STATUS ERROR => $e');
      Get.snackbar(
        'Error',
        'Unable to update status. Please check the backend API.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      togglingIds.remove(item.id);
    }
  }

  Future<void> _loadByType(MasterDataType type) async {
    final items = await _repository.getItems(type);
    switch (type) {
      case MasterDataType.metals:
        metals.assignAll(items);
        break;
      case MasterDataType.categories:
        categories.assignAll(items);
        break;
      case MasterDataType.repairTypes:
        repairTypes.assignAll(items);
        break;
    }
  }
}