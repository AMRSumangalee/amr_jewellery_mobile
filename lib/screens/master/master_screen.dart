import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_order_management/models/master_data_model.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';
import 'package:jewellery_order_management/utils/app_text_style.dart';
import 'master_controller.dart';

class MasterScreen extends GetView<MasterController> {
  const MasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back, color: AppColors.black),
        ),
        title: Text(
          'Master Data',
          style: AppTextStyle.appBarTitle.copyWith(color: AppColors.black),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.loadAll,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.black),
          ),
          const SizedBox(width: 6),
        ],
      ),
      // Obx added so the label ("Add Metal" / "Add Category" ...) updates on tab change.
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: () => _showItemDialog(),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text('Add $_tabSingular', style: AppTextStyle.buttonSmall),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _tabButton('Metals', 0),
                    _tabButton('Categories', 1),
                    _tabButton('Repair Types', 2),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final items = controller.currentItems;
              if (items.isEmpty) return _emptyState();

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: controller.loadAll,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MasterDataCard(
                      item: item,
                      isBusy: controller.togglingIds.contains(item.id),
                      onEdit: () => _showItemDialog(item: item),
                      onStatusChanged: () => controller.toggleStatus(item),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String get _tabSingular {
    switch (controller.selectedTab.value) {
      case 1:
        return 'Category';
      case 2:
        return 'Repair Type';
      default:
        return 'Metal';
    }
  }

  String get currentTitle => controller.currentTitle;

  Widget _tabButton(String label, int index) {
    final selected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.chip.copyWith(
              fontSize: 11,
              color: selected ? AppColors.black : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text('No $currentTitle Found', style: AppTextStyle.h3),
            const SizedBox(height: 8),
            Text(
              'Add your first ${_tabSingular.toLowerCase()} to manage your jewellery orders.',
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySecondary,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _showItemDialog(),
              icon: const Icon(Icons.add_rounded),
              label: Text('Add $_tabSingular', style: AppTextStyle.button.copyWith(color: AppColors.black),),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog is now a separate StatefulWidget, so controllers are disposed safely.
  void _showItemDialog({MasterDataModel? item}) {
    Get.dialog(
      _MasterItemDialog(
        item: item,
        tabSingular: _tabSingular,
        controller: controller,
      ),
      barrierDismissible: false,
    );
  }
}

// ============================================================
// ADD / EDIT DIALOG
// ============================================================

class _MasterItemDialog extends StatefulWidget {
  final MasterDataModel? item;
  final String tabSingular;
  final MasterController controller;

  const _MasterItemDialog({
    required this.item,
    required this.tabSingular,
    required this.controller,
  });

  @override
  State<_MasterItemDialog> createState() => _MasterItemDialogState();
}

class _MasterItemDialogState extends State<_MasterItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late bool _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _codeController = TextEditingController(text: widget.item?.code ?? '');
    _status = widget.item?.status ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        isEdit ? 'Edit ${widget.tabSingular}' : 'Add ${widget.tabSingular}',
        style: AppTextStyle.button.copyWith(color: AppColors.black,fontSize: 20),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Enter name',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Code *',
                hintText: 'Enter unique code',
                prefixIcon: Icon(Icons.qr_code_rounded),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _status,
              activeColor: AppColors.success,
              title: Text('Active', style: AppTextStyle.subtitle),
              subtitle: Text(
                _status ? 'Available for use' : 'Not available for use',
                style: AppTextStyle.caption,
              ),
              onChanged: (value) => setState(() => _status = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Cancel', style: AppTextStyle.button.copyWith(color: AppColors.black),),
        ),
        Obx(
          () => ElevatedButton(
            onPressed: widget.controller.isSaving.value
                ? null
                : () => widget.controller.saveItem(
                      id: widget.item?.id,
                      name: _nameController.text,
                      code: _codeController.text,
                      status: _status,
                    ),
            child: widget.controller.isSaving.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text('Save', style: AppTextStyle.button.copyWith(color: AppColors.black),),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// LIST CARD
// ============================================================

class _MasterDataCard extends StatelessWidget {
  final MasterDataModel item;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onStatusChanged;

  const _MasterDataCard({
    required this.item,
    required this.isBusy,
    required this.onEdit,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = item.status ? AppColors.success : AppColors.error;

    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.category_rounded, color: AppColors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.title,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.code,
                    style: AppTextStyle.code.copyWith(color: AppColors.black),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status ? 'ACTIVE' : 'INACTIVE',
                      style: AppTextStyle.chip.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              children: [
                Switch(
                  value: item.status,
                  activeColor: AppColors.success,
                  inactiveThumbColor: AppColors.error,
                  onChanged: isBusy ? null : (_) => onStatusChanged(),
                ),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}