import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_order_management/models/maker_model.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';
import 'package:jewellery_order_management/utils/app_text_style.dart';
import 'maker_controller.dart';

class MakerScreen extends GetView<MakerController> {
  const MakerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
         leading: IconButton(onPressed: (){
          Get.back();
        }, icon: Icon(Icons.arrow_back,color: AppColors.black,)),
        title: Text('Makers', style: AppTextStyle.appBarTitle.copyWith(color: AppColors.black)),
        actions: [
          IconButton(
            tooltip: 'Refresh makers',
            onPressed: controller.loadMakers, 
            icon:  Icon(Icons.refresh_rounded,color: AppColors.black,),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMakerDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded,color: AppColors.black,),
        label: Text('Add Maker', style: AppTextStyle.buttonSmall.copyWith(color: AppColors.black)),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.makers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.makers.isEmpty) {
          return _emptyState(context);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadMakers,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: controller.makers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final maker = controller.makers[index];
              return Obx(
                () => _MakerCard(
                  maker: maker,
                  isBusy: controller.togglingIds.contains(maker.id),
                  onEdit: () => _showMakerDialog(context, maker: maker),
                  onStatusToggle: () => controller.toggleStatus(maker),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.engineering_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text('No Makers Found', style: AppTextStyle.h3),
            const SizedBox(height: 8),
            Text(
              'Add a maker to assign jewellery orders for production or repair.',
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySecondary,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _showMakerDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: Text('Add Maker', style: AppTextStyle.button),
            ),
          ],
        ),
      ),
    );
  }

  void _showMakerDialog(BuildContext context, {MakerModel? maker}) {
    final nameController = TextEditingController(text: maker?.name ?? '');
    final phoneController = TextEditingController(text: maker?.phone ?? '');
    final whatsappController =
        TextEditingController(text: maker?.whatsappNumber ?? '');
    final specializationController =
        TextEditingController(text: maker?.specialization ?? '');

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          maker == null ? 'Add Maker' : 'Edit Maker',
         style: AppTextStyle.button.copyWith(color: AppColors.black,fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input(
                controller: nameController,
                label: 'Maker Name *',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _input(
                controller: phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _input(
                controller: whatsappController,
                label: 'WhatsApp Number',
                icon: Icons.chat_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _input(
                controller: specializationController,
                label: 'Specialization',
                hint: 'e.g. Gold, Stone Setting, Polish',
                icon: Icons.build_outlined,
                textCapitalization: TextCapitalization.words,
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
              onPressed: controller.isSaving.value
                  ? null
                  : () => controller.saveMaker(
                        id: maker?.id,
                        name: nameController.text,
                        phone: phoneController.text,
                        whatsappNumber: whatsappController.text,
                        specialization: specializationController.text,
                      ),
              child: controller.isSaving.value
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
      ),
      barrierDismissible: false,
    ).then((_) {
      nameController.dispose();
      phoneController.dispose();
      whatsappController.dispose();
      specializationController.dispose();
    });
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: AppTextStyle.body,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _MakerCard extends StatelessWidget {
  final MakerModel maker;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onStatusToggle;

  const _MakerCard({
    required this.maker,
    required this.isBusy,
    required this.onEdit,
    required this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = maker.status ? AppColors.success : AppColors.error;

    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.engineering_rounded,
                color: AppColors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    maker.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.title,
                  ),
                  const SizedBox(height: 5),
                  if ((maker.specialization ?? '').isNotEmpty)
                    Text(
                      maker.specialization!,
                      style: AppTextStyle.bodySecondary,
                    ),
                  if ((maker.phone ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _detail(Icons.phone_outlined, maker.phone!),
                  ],
                  if ((maker.whatsappNumber ?? '').isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _detail(Icons.chat_outlined, maker.whatsappNumber!),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      maker.status ? 'ACTIVE' : 'INACTIVE',
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
                  value: maker.status,
                  activeColor: AppColors.success,
                  inactiveThumbColor: AppColors.error,
                  onChanged: isBusy ? null : (_) => onStatusToggle(),
                ),
                IconButton(
                  tooltip: 'Edit maker',
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

  Widget _detail(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.grey),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: AppTextStyle.bodySecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
