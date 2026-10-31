import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jewellery_order_management/models/branch_model.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';
import 'package:jewellery_order_management/utils/app_text_style.dart';

import 'branch_controller.dart';

class BranchScreen extends GetView<BranchController> {
  const BranchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Get.back();
        }, icon: Icon(Icons.arrow_back,color: AppColors.black,)),
        title: Text(
          'Branches',
          style: AppTextStyle.appBarTitle.copyWith(color: AppColors.black),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh branches',
            onPressed: controller.loadBranches,
            icon: const Icon(Icons.refresh_rounded,color: AppColors.black,),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.black,
        onPressed: controller.openAddBranch,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Branch',
          style: AppTextStyle.buttonSmall.copyWith(color: AppColors.black),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.branches.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (controller.branches.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadBranches,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: controller.branches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final branch = controller.branches[index];

              return Obx(
                () => _BranchCard(
                  branch: branch,
                  isBusy: controller.togglingIds.contains(branch.id),
                  onEdit: () => controller.openEditBranch(branch),
                  onStatusToggle: () =>
                      controller.toggleBranchStatus(branch),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.store_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Branches Found',
              style: AppTextStyle.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first branch to start managing orders.',
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySecondary,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.openAddBranch,
              icon: const Icon(Icons.add),
              label: Text(
                'Add Branch',
                style: AppTextStyle.button,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// BRANCH CARD
// ==================================================================

class _BranchCard extends StatelessWidget {
  final BranchModel branch;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onStatusToggle;

  const _BranchCard({
    required this.branch,
    required this.isBusy,
    required this.onEdit,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.store_rounded,
                color: AppColors.black,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          branch.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.title,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(isActive: branch.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    branch.code,
                    style: AppTextStyle.code.copyWith(color: AppColors.black),
                  ),
                  if (branch.address != null &&
                      branch.address!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            branch.address!,
                            style: AppTextStyle.bodySecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (branch.phone != null && branch.phone!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            branch.phone!,
                            style: AppTextStyle.bodySecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              children: [
                Switch(
                  value: branch.status,
                  activeColor: AppColors.success,
                  inactiveThumbColor: AppColors.error,
                  onChanged: isBusy ? null : (_) => onStatusToggle(),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.textSecondary,
                  tooltip: 'Edit branch',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// STATUS CHIP
// ==================================================================

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: AppTextStyle.chip.copyWith(color: color),
      ),
    );
  }
}
