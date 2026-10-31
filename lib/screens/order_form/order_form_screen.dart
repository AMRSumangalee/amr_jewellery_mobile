import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_order_management/services/api_constants.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';
import 'package:jewellery_order_management/utils/app_text_style.dart';
import '../../models/order_form_option.dart';
import 'order_form_controller.dart';

class OrderFormScreen extends GetView<OrderFormController> {
  const OrderFormScreen({super.key});

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
          controller.isEditMode ? 'Edit Order' : 'Create Order',
          style: AppTextStyle.appBarTitle.copyWith(color: AppColors.black),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.loadFailed.value) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 8),
                const Text('Unable to load form data'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.loadOptions,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _section(
                'Order Type',
                Icons.receipt_long,
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _typeChoice(
                          'NEW',
                          'New Order',
                          Icons.auto_awesome,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _typeChoice(
                          'REPAIR',
                          'Repair Order',
                          Icons.build_circle_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _section(
                'Branch Details',
                Icons.store,
                _dropdown(
                  label: 'Branch *',
                  selected: controller.selectedBranchId,
                  items: controller.branches,
                ),
              ),

              _section(
                'Customer Details',
                Icons.person_outline,
                Column(
                  children: [
                    _textField(
                      controller.customerName,
                      'Customer Name *',
                      required: true,
                      capitalization: TextCapitalization.words,
                    ),
                    _textField(
                      controller.customerPhone,
                      'Phone Number *',
                      keyboard: TextInputType.phone,
                      validator: controller.phoneValidator,
                    ),
                    _textField(
                      controller.customerArea,
                      'Area *',
                      required: true,
                      capitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),

              Obx(
                () => controller.orderType.value == 'NEW'
                    ? _newOrderFields()
                    : _repairOrderFields(),
              ),

              _section(
                'Delivery & Assignment',
                Icons.event_available,
                Column(
                  children: [
                    Obx(
                      () => _tapField(
                        'Expected Delivery Date *',
                        controller.expectedDate.value == null
                            ? 'Select date'
                            : _displayDate(controller.expectedDate.value!),
                        Icons.calendar_month,
                        () => controller.selectExpectedDate(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        key: ValueKey('priority-${controller.priority.value}'),
                        // ignore: deprecated_member_use
                        value: controller.priority.value,
                        isExpanded: true,
                        decoration: _decoration('Priority *'),
                        items: const [
                          DropdownMenuItem(value: 'LOW', child: Text('Low')),
                          DropdownMenuItem(
                            value: 'NORMAL',
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(
                            value: 'URGENT',
                            child: Text('Urgent'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            controller.priority.value = value;
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _dropdown(
                      label: 'Assigned Maker (Optional)',
                      selected: controller.selectedMakerId,
                      items: controller.makers,
                      optional: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _textField(
                            controller.estimate,
                            'Estimate (Optional)',
                            keyboard: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _textField(
                            controller.advance,
                            'Advance (Optional)',
                            keyboard: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _section(
                'Photos, Video & Audio',
                Icons.perm_media_outlined,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.isEditMode
                          ? 'Existing media will be kept. You can add more images, videos or audio.'
                          : 'Images, videos and audio are optional. You can save the order without media.',
                      style: AppTextStyle.bodySecondary,
                    ),
                    if (controller.isEditMode) _existingMedia(),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _chooseImageSource,
                          icon: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.black,
                          ),
                          label: Obx(
                            () => Text(
                              'Images (${controller.selectedImages.length})',
                              style: AppTextStyle.bodySecondary.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                        Obx(
                          () => OutlinedButton.icon(
                            // Disabled while the video is compressing.
                            onPressed: controller.isCompressing.value
                                ? null
                                : _chooseVideoSource,
                            icon: const Icon(
                              Icons.video_library_outlined,
                              color: AppColors.black,
                            ),
                            label: Text(
                              controller.selectedVideo.value == null
                                  ? 'Add Video'
                                  : 'Change Video',
                              style: AppTextStyle.bodySecondary.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _chooseAudioSource,
                          icon: const Icon(
                            Icons.audio_file_outlined,
                            color: AppColors.black,
                          ),
                          label: Obx(
                            () => Text(
                              controller.selectedAudio.value == null
                                  ? 'Add Audio'
                                  : 'Change Audio',
                              style: AppTextStyle.bodySecondary.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Live audio recording bar
                    Obx(
                      () => controller.isRecording.value
                          ? _recordingBar()
                          : const SizedBox.shrink(),
                    ),

                    Obx(
                      () => controller.selectedImages.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: SizedBox(
                                height: 80,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: controller.selectedImages.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, index) => _imageThumb(
                                    controller.selectedImages[index].path,
                                    index,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Video compressing indicator
                    Obx(
                      () => controller.isCompressing.value
                          ? _compressingBar()
                          : const SizedBox.shrink(),
                    ),

                    Obx(
                      () => controller.selectedVideo.value == null
                          ? const SizedBox.shrink()
                          : _fileChip(
                              Icons.videocam_outlined,
                              controller.selectedVideo.value!.name,
                              controller.clearVideo,
                            ),
                    ),

                    Obx(
                      () => controller.selectedAudio.value == null
                          ? const SizedBox.shrink()
                          : _fileChip(
                              Icons.audiotrack_outlined,
                              controller.selectedAudio.value!.name,
                              controller.clearAudio,
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Obx(
                () => SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        (controller.isSubmitting.value ||
                            controller.isCompressing.value)
                        ? null
                        : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            controller.submitOrder();
                          },
                    icon: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.save_outlined, color: AppColors.black),
                    label: Text(
                      controller.isSubmitting.value
                          ? (controller.isEditMode
                                ? 'Updating Order...'
                                : 'Saving Order...')
                          : controller.isCompressing.value
                          ? 'Compressing Video...'
                          : controller.isEditMode
                          ? 'Update ${controller.orderType.value == 'NEW' ? 'New' : 'Repair'} Order'
                          : 'Create ${controller.orderType.value == 'NEW' ? 'New' : 'Repair'} Order',
                      style: AppTextStyle.button.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        );
      }),
    );
  }

  // ============================================================
  // MEDIA SOURCE CHOOSERS (camera / record / gallery)
  // ============================================================

  void _showSourceSheet({
    required String title,
    required List<_SourceOption> options,
  }) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyle.title.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 8),
              ...options.map(
                (o) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(o.icon, color: AppColors.black),
                  title: Text(
                    o.label,
                    style: AppTextStyle.body.copyWith(color: AppColors.black),
                  ),
                  onTap: () {
                    Get.back(); // close the sheet first
                    o.onTap();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _chooseImageSource() {
    _showSourceSheet(
      title: 'Add Photo',
      options: [
        _SourceOption(
          Icons.photo_camera_outlined,
          'Take Photo',
          controller.captureImage,
        ),
        _SourceOption(
          Icons.photo_library_outlined,
          'Choose from Gallery',
          controller.pickImages,
        ),
      ],
    );
  }

  void _chooseVideoSource() {
    _showSourceSheet(
      title: 'Add Video',
      options: [
        _SourceOption(
          Icons.videocam_outlined,
          'Record Video',
          controller.recordVideo,
        ),
        _SourceOption(
          Icons.video_library_outlined,
          'Choose from Gallery',
          controller.pickVideo,
        ),
      ],
    );
  }

  void _chooseAudioSource() {
    if (controller.isRecording.value) return;
    _showSourceSheet(
      title: 'Add Audio',
      options: [
        _SourceOption(
          Icons.mic_none_rounded,
          'Record Audio',
          controller.startAudioRecording,
        ),
        _SourceOption(
          Icons.audio_file_outlined,
          'Choose Audio File',
          controller.pickAudio,
        ),
      ],
    );
  }

  // ============================================================
  // COMPRESSING BAR
  // ============================================================

  Widget _compressingBar() => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withOpacity(0.5)),
    ),
    child: Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Compressing video, please wait...',
            style: AppTextStyle.body.copyWith(color: AppColors.black),
          ),
        ),
      ],
    ),
  );

  // ============================================================
  // RECORDING BAR
  // ============================================================

  String _formatSeconds(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _recordingBar() => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.error.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.error.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.fiber_manual_record, color: AppColors.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Obx(
            () => Text(
              'Recording...  ${_formatSeconds(controller.recordSeconds.value)}',
              style: AppTextStyle.body.copyWith(color: AppColors.black),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Discard',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: controller.cancelAudioRecording,
        ),
        IconButton(
          tooltip: 'Stop & save',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.stop_circle, color: AppColors.black, size: 30),
          onPressed: controller.stopAudioRecording,
        ),
      ],
    ),
  );

  // ============================================================
  // EXISTING MEDIA (EDIT MODE)
  // ============================================================

  String _mediaUrl(String fileUrl) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base/${fileUrl.replaceFirst(RegExp(r'^/+'), '')}';
  }

  Widget _existingMedia() {
    final items = controller.existingMedia;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Already uploaded (${items.length})', style: AppTextStyle.label),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final media = items[index];
                final type = '${media['mediaType'] ?? ''}'.toUpperCase();
                final url = _mediaUrl('${media['fileUrl'] ?? ''}');

                if (type == 'IMAGE') {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.border,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  );
                }

                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type == 'VIDEO'
                            ? Icons.videocam_outlined
                            : Icons.audiotrack_outlined,
                        color: AppColors.black,
                      ),
                      const SizedBox(height: 4),
                      Text(type, style: AppTextStyle.caption),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NEW ORDER FIELDS
  // ============================================================

  Widget _newOrderFields() => _section(
    'New Jewellery Details',
    Icons.diamond_outlined,
    Column(
      children: [
        _dropdown(
          label: 'Metal *',
          selected: controller.selectedMetalId,
          items: controller.metals,
        ),
        const SizedBox(height: 12),

        _dropdown(
          label: 'Category *',
          selected: controller.selectedCategoryId,
          items: controller.categories,
        ),
        const SizedBox(height: 12),

        _lengthFields('new'),

        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _textField(controller.size, 'Size')),
            const SizedBox(width: 10),
            Expanded(
              child: _textField(
                controller.weight,
                'Weight (g)',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _purityDropdown(),
        const SizedBox(height: 12),
        _textField(controller.description, 'Order Description', maxLines: 3),
      ],
    ),
  );

  Widget _purityDropdown() {
    final current = controller.purity.text.trim().toUpperCase();
    final options = <String>['24K', '22K', '18K'];
    // Keep an existing value (edit mode) even if it is not in the default list.
    if (current.isNotEmpty && !options.contains(current)) {
      options.add(current);
    }

    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: options.contains(current) ? current : null,
      decoration: const InputDecoration(
        labelText: 'Purity',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.diamond_outlined),
      ),
      hint: const Text('Select Purity'),
      items: options
          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          controller.purity.text = value;
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select purity';
        }
        return null;
      },
    );
  }

  // ============================================================
  // REPAIR ORDER FIELDS
  // ============================================================

  Widget _repairOrderFields() => Column(
    children: [
      _section(
        'Existing Jewellery Details',
        Icons.diamond_outlined,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the details of the jewellery received '
              'from the customer.',
              style: AppTextStyle.bodySecondary,
            ),
            const SizedBox(height: 12),

            _dropdown(
              label: 'Metal (Optional)',
              selected: controller.selectedMetalId,
              items: controller.metals,
              optional: true,
            ),
            const SizedBox(height: 12),

            _dropdown(
              label: 'Category (Optional)',
              selected: controller.selectedCategoryId,
              items: controller.categories,
              optional: true,
            ),
            const SizedBox(height: 12),

            _lengthFields('repair'),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _textField(controller.size, 'Size')),
                const SizedBox(width: 10),
                Expanded(
                  child: _textField(
                    controller.weight,
                    'Weight (g)',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _textField(controller.purity, 'Purity (e.g. 22K)'),

            _textField(
              controller.existingJewelleryDescription,
              'Existing Jewellery Description *',
              required: true,
              maxLines: 2,
            ),
          ],
        ),
      ),

      _section(
        'Repair Work Details',
        Icons.handyman_outlined,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repair Type * (select all that apply)',
              style: AppTextStyle.label,
            ),
            const SizedBox(height: 8),

            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 4,
                children: controller.repairTypes.map((type) {
                  return FilterChip(
                    label: Text(type.name),
                    selected: controller.selectedRepairTypeIds.contains(
                      type.id,
                    ),
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primary,
                    onSelected: (value) =>
                        controller.toggleRepairType(type.id, value),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            _textField(
              controller.problemDescription,
              'Problem / Repair Description *',
              required: true,
              maxLines: 3,
            ),

            _textField(
              controller.receivedItemDescription,
              'Received Item / Condition *',
              required: true,
              maxLines: 2,
            ),
          ],
        ),
      ),
    ],
  );

  // ============================================================
  // LENGTH AND UNIT
  // ============================================================

  Widget _lengthFields(String prefix) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _textField(
          controller.length,
          'Length',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 100,
        child: Obx(
          () => DropdownButtonFormField<String>(
            key: ValueKey('$prefix-unit-${controller.lengthUnit.value}'),
            // ignore: deprecated_member_use
            value: controller.lengthUnit.value,
            isExpanded: true,
            decoration: _decoration('Unit'),
            items: const [
              DropdownMenuItem(value: 'cm', child: Text('cm')),
              DropdownMenuItem(value: 'inch', child: Text('inch')),
            ],
            onChanged: (value) {
              if (value != null) {
                controller.lengthUnit.value = value;
              }
            },
          ),
        ),
      ),
    ],
  );

  // ============================================================
  // ORDER TYPE SELECTOR
  // ============================================================

  Widget _typeChoice(String value, String label, IconData icon) {
    final selected = controller.orderType.value == value;
    final locked = controller.isEditMode; // type cannot change in edit mode

    return Opacity(
      opacity: locked && !selected ? 0.4 : 1,
      child: InkWell(
        onTap: locked ? null : () => controller.setOrderType(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.black : AppColors.grey,
                size: 20,
              ),
              const SizedBox(width: 7),
              Icon(
                icon,
                color: selected ? AppColors.black : AppColors.textSecondary,
                size: 19,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyle.label.copyWith(
                    color: selected ? AppColors.black : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CONTAINER
  // ============================================================

  Widget _section(String title, IconData icon, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.black),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: AppTextStyle.title.copyWith(color: AppColors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _textField(
    TextEditingController textController,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: textController,
      keyboardType: keyboard,
      maxLines: maxLines,
      textCapitalization: capitalization,
      style: AppTextStyle.body,
      validator:
          validator ??
          (required
              ? (value) =>
                    controller.requiredText(value, label.replaceAll(' *', ''))
              : null),
      decoration: _decoration(label),
    ),
  );

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdown({
    required String label,
    required RxnInt selected,
    required RxList<OrderFormOption> items,
    bool optional = false,
  }) => Obx(() {
    final unique = <int, OrderFormOption>{};

    for (final item in items) {
      unique.putIfAbsent(item.id, () => item);
    }

    final list = unique.values.toList();
    final current = unique.containsKey(selected.value) ? selected.value : null;

    return DropdownButtonFormField<int>(
      key: ValueKey('$label-$current-${list.length}'),
      // ignore: deprecated_member_use
      value: current,
      isExpanded: true,
      decoration: _decoration(label),
      items: list
          .map(
            (item) => DropdownMenuItem<int>(
              value: item.id,
              child: Text(item.name, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        selected.value = value;
      },
      validator: optional
          ? null
          : (value) => value == null
                ? '${label.replaceAll(' *', '')} is required'
                : null,
    );
  });

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _tapField(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: _decoration(
        label,
      ).copyWith(suffixIcon: Icon(icon, color: AppColors.black)),
      child: Text(
        value,
        style: AppTextStyle.body.copyWith(
          color: value == 'Select date'
              ? AppColors.black
              : AppColors.textPrimary,
        ),
      ),
    ),
  );

  // ============================================================
  // IMAGE THUMBNAIL
  // ============================================================

  Widget _imageThumb(String path, int index) => Stack(
    clipBehavior: Clip.none,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 80,
            height: 80,
            color: AppColors.border,
            child: const Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
      Positioned(
        top: -6,
        right: -6,
        child: InkWell(
          onTap: () => controller.removeImage(index),
          child: const CircleAvatar(
            radius: 11,
            backgroundColor: Colors.black87,
            child: Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ),
      ),
    ],
  );

  // ============================================================
  // VIDEO / AUDIO CHIP
  // ============================================================

  Widget _fileChip(IconData icon, String name, VoidCallback onRemove) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
                style: AppTextStyle.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
            ),
          ],
        ),
      );

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: AppTextStyle.label,
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );

  String _displayDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.year}';
}

// Small helper model for the bottom sheet options.
class _SourceOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption(this.icon, this.label, this.onTap);
}
