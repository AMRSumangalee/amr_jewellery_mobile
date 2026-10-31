import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_order_management/models/branch_model.dart';
import 'package:jewellery_order_management/repositories/branch_repository.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';
import 'package:jewellery_order_management/utils/app_text_style.dart';

class BranchController extends GetxController {
  final BranchRepository _repository = BranchRepository();

  // ============================================================
  // TEXT CONTROLLERS
  // ============================================================

  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  final branches = <BranchModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final selectedStatus = true.obs;

  /// ids of branches whose status is being toggled right now
  final togglingIds = <int>{}.obs;

  // ============================================================
  // EDIT MODE
  // ============================================================

  BranchModel? editingBranch;

  bool get isEditMode => editingBranch != null;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();
    loadBranches();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> loadBranches() async {
    try {
      isLoading.value = true;

      final result = await _repository.getBranches();
      branches.assignAll(result);
    } catch (e) {
      debugPrint('LOAD BRANCHES ERROR => $e');

      Get.snackbar(
        'Error',
        'Unable to load branches',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // OPEN ADD
  // ============================================================

  void openAddBranch() {
    editingBranch = null;
    clearForm();
    selectedStatus.value = true;
    _showBranchDialog();
  }

  // ============================================================
  // OPEN EDIT
  // ============================================================

  void openEditBranch(BranchModel branch) {
    editingBranch = branch;

    nameController.text = branch.name;
    codeController.text = branch.code;
    addressController.text = branch.address ?? '';
    phoneController.text = branch.phone ?? '';

    selectedStatus.value = branch.status;

    _showBranchDialog();
  }

  // ============================================================
  // DIALOG
  // ============================================================

  void _showBranchDialog() {
    Get.dialog(
      _BranchFormDialog(controller: this),
      barrierDismissible: false,
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> saveBranch() async {
    final name = nameController.text.trim();
    final code = codeController.text.trim();
    final address = addressController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      Get.snackbar(
        'Validation',
        'Please enter branch name',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (code.isEmpty) {
      Get.snackbar(
        'Validation',
        'Please enter branch code',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final wasEdit = isEditMode;

    try {
      isSaving.value = true;

      if (wasEdit) {
        await _repository.updateBranch(
          id: editingBranch!.id,
          name: name,
          code: code,
          address: address.isEmpty ? null : address,
          phone: phone.isEmpty ? null : phone,
          status: selectedStatus.value,
        );
      } else {
        await _repository.createBranch(
          name: name,
          code: code,
          address: address.isEmpty ? null : address,
          phone: phone.isEmpty ? null : phone,
          status: selectedStatus.value,
        );
      }

      Get.back();

      clearForm();
      editingBranch = null;

      await loadBranches();

      Get.snackbar(
        'Success',
        wasEdit
            ? 'Branch updated successfully'
            : 'Branch created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('SAVE BRANCH ERROR => $e');

      Get.snackbar(
        'Error',
        'Unable to save branch',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // TOGGLE BRANCH STATUS (ACTIVE / INACTIVE)
  // ============================================================

  Future<void> toggleBranchStatus(BranchModel branch) async {
    if (togglingIds.contains(branch.id)) return; // prevent double tap

    final newStatus = !branch.status;

    int indexOf() => branches.indexWhere((b) => b.id == branch.id);

    final index = indexOf();
    if (index == -1) return;

    togglingIds.add(branch.id);

    // 1) Update UI immediately
    branches[index] = branch.copyWith(status: newStatus);

    try {
      // 2) Save to server
      final updated = await _repository.updateBranchStatus(
        branch: branch,
        status: newStatus,
      );

      debugPrint(
        'TOGGLE => requested: $newStatus, server returned: ${updated.status}',
      );

      // 3) Reload from server to confirm
      final result = await _repository.getBranches();
      branches.assignAll(result);

      final confirmed = result.firstWhereOrNull((b) => b.id == branch.id);

      if (confirmed != null && confirmed.status != newStatus) {
        Get.snackbar(
          'Not saved',
          'Server did not save the status change',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      Get.snackbar(
        'Success',
        newStatus
            ? '${branch.name} activated successfully'
            : '${branch.name} deactivated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('UPDATE BRANCH STATUS ERROR => $e');

      // revert UI
      final i = indexOf();
      if (i != -1) {
        branches[i] = branch;
      }

      Get.snackbar(
        'Error',
        'Unable to update branch status',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      togglingIds.remove(branch.id);
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clearForm() {
    nameController.clear();
    codeController.clear();
    addressController.clear();
    phoneController.clear();

    selectedStatus.value = true;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void onClose() {
    nameController.dispose();
    codeController.dispose();
    addressController.dispose();
    phoneController.dispose();

    super.onClose();
  }
}

// ==================================================================
// BRANCH FORM DIALOG
// ==================================================================

class _BranchFormDialog extends StatelessWidget {
  final BranchController controller;

  const _BranchFormDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isEdit = controller.isEditMode;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Branch' : 'Add Branch'),

      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller.nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Branch Name *',
                  hintText: 'Enter branch name',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: controller.codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Branch Code *',
                  hintText: 'Example: SALEM',
                  prefixIcon: Icon(Icons.qr_code_rounded),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: controller.addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter branch address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 14),

              // STATUS
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Branch'),
                  subtitle: Text(
                    controller.selectedStatus.value
                        ? 'Branch is active'
                        : 'Branch is inactive',
                  ),
                  value: controller.selectedStatus.value,
                  activeColor: AppColors.success,
                  onChanged: (value) {
                    controller.selectedStatus.value = value;
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      actions: [
        Obx(
          () => TextButton(
            onPressed: controller.isSaving.value
                ? null
                : () {
                    Get.back();
                    controller.clearForm();
                    controller.editingBranch = null;
                  },
            child:  Text('Cancel',style: AppTextStyle.button.copyWith(color: AppColors.black),),
          ),
        ),

        Obx(
          () => ElevatedButton(
            onPressed:
                controller.isSaving.value ? null : controller.saveBranch,
            child: controller.isSaving.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Update' : 'Save',style: AppTextStyle.button.copyWith(color: AppColors.black),),
          ),
        ),
      ],
    );
  }
}