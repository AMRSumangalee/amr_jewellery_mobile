import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_order_management/routes/app_routes.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';
import 'package:jewellery_order_management/utils/app_text_style.dart';
import 'package:jewellery_order_management/utils/order_print_service.dart';
import 'package:print_bluetooth_thermal_plus/print_bluetooth_thermal.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jewellery_order_management/services/api_constants.dart';
import 'order_details_controller.dart';

class OrderDetailsScreen extends GetView<OrderDetailsController> {
  const OrderDetailsScreen({super.key});

  // ============================================================
  // HELPERS
  // ============================================================

  String _value(dynamic value) {
    if (value == null || '$value'.trim().isEmpty) return '-';
    return '$value';
  }

  String _date(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return '$value';
    final date = parsed.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _dateTime(dynamic value) {
    if (value == null) return '-';
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return '$value';
    final date = parsed.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = (date.hour % 12 == 0 ? 12 : date.hour % 12).toString().padLeft(
      2,
      '0',
    );
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year • $hour:$minute $period';
  }

  String _relatedName(dynamic value, List<String> keys) {
    if (value is! Map) return '-';
    for (final key in keys) {
      final result = value[key];
      if (result != null && '$result'.trim().isNotEmpty) {
        return '$result';
      }
    }
    return '-';
  }

  String _mediaUrl(String fileUrl) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    return '$base/${fileUrl.replaceFirst(RegExp(r'^/+'), '')}';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase().replaceAll(' ', '_')) {
      case 'COMPLETED':
      case 'FINAL_CONFIRMED':
      case 'DELIVERED':
        return AppColors.success;
      case 'IN_PROGRESS':
      case 'ASSIGNED':
        return AppColors.info;
      case 'ON_HOLD':
        return AppColors.warning;
      case 'CANCELLED':
        return AppColors.error;
      // case 'CLEANUP':
      //   return AppColors.accentGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppTextStyle.label,
      hintStyle: AppTextStyle.bodySecondary,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.white,
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary, 1.5),
      disabledBorder: border(AppColors.border),
    );
  }

  // ============================================================
  // EDIT / DELETE ACTIONS
  // ============================================================

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Order?',
          style: AppTextStyle.h3.copyWith(color: AppColors.black),
        ),
        content: Text(
          'This will permanently delete this order and its media. '
          'This cannot be undone.',
          style: AppTextStyle.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyle.buttonSecondary.copyWith(
                color: AppColors.black,
              ),
            ),
          ),
          Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              onPressed: controller.isDeleting.value
                  ? null
                  : () async {
                      Get.back(); // close the confirm dialog first
                      await controller.deleteOrder();
                    },
              child: Text(
                'Delete',
                style: AppTextStyle.button.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Opens the order form screen in edit mode (route depends on order type).
  Future<void> _openEditScreen() async {
    final data = controller.order.value;
    if (data == null) return;

    final result = await Get.toNamed(
      AppRoutes.newOrder,
      arguments: {'order': data},
    );

    if (result == true) {
      await controller.fetchOrderDetails();
      await controller.fetchStatusHistory();
    }
  }

  // ============================================================
  // REUSABLE WIDGETS
  // ============================================================

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      color: AppColors.white,
      surfaceTintColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: AppTextStyle.title)),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: AppTextStyle.bodySecondary.copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              _value(value),
              style: AppTextStyle.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, {double fontSize = 11}) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: AppTextStyle.chip.copyWith(color: color, fontSize: fontSize),
      ),
    );
  }

  Widget _loader({Color color = AppColors.primary}) =>
      CircularProgressIndicator(color: color);

  Widget _buttonSpinner() => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
  );

  // ============================================================
  // MEDIA
  // ============================================================

  Widget _mediaSection(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _section('Order Media', Icons.perm_media_outlined, [
        Text('No media uploaded', style: AppTextStyle.emptyDescription),
      ]);
    }

    return _section(
      'Order Media (${items.length})',
      Icons.perm_media_outlined,
      [
        ...items.map((media) {
          final type = _value(media['mediaType']).toUpperCase();
          final mediaContext = _value(media['mediaContext']);
          final fileName = _value(media['fileName']);
          final fileUrl = _value(media['fileUrl']);
          final url = _mediaUrl(fileUrl);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTextStyle.title.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text('$type • $mediaContext', style: AppTextStyle.caption),
                const SizedBox(height: 10),
                if (type == 'IMAGE')
                  GestureDetector(
                    onTap: () => Get.to(
                      () => _ImagePreviewScreen(url: url, title: fileName),
                      fullscreenDialog: true,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Image.network(
                            url,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => SizedBox(
                              height: 100,
                              child: Center(
                                child: Text(
                                  'Unable to load image',
                                  style: AppTextStyle.error,
                                ),
                              ),
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return SizedBox(
                                height: 120,
                                child: Center(child: _loader()),
                              );
                            },
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.black.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.zoom_out_map,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (type == 'VIDEO')
                  _VideoMediaPlayer(key: ValueKey(url), url: url)
                else if (type == 'AUDIO')
                  _AudioMediaPlayer(key: ValueKey(url), url: url)
                else
                  Text('Unsupported media type', style: AppTextStyle.warning),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // STATUS UPDATE
  // ============================================================

  Widget _statusUpdateSection(Map<String, dynamic> data) {
    return Obx(() {
      final statuses = controller.availableStatuses;
      final currentStatus = _value(data['status']).toUpperCase();
      final selected = controller.selectedStatus.value;
      final selectedValue = statuses.contains(selected) ? selected : null;
      final updating = controller.isUpdatingStatus.value;

      return _section('Update Order Status', Icons.sync_alt, [
        Row(
          children: [
            Text('Current status', style: AppTextStyle.bodySecondary),
            const Spacer(),
            _statusChip(currentStatus, fontSize: 12),
          ],
        ),
        const SizedBox(height: 14),
        if (statuses.isEmpty)
          Text(
            'No further status changes are available for this order.',
            style: AppTextStyle.emptyDescription,
          )
        else ...[
          DropdownButtonFormField<String>(
            value: selectedValue,
            isExpanded: true,
            style: AppTextStyle.body,
            dropdownColor: AppColors.white,
            decoration: _inputDecoration(
              label: 'New status',
              icon: Icons.flag_outlined,
            ),
            items: statuses.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  status.replaceAll('_', ' '),
                  style: AppTextStyle.body,
                ),
              );
            }).toList(),
            onChanged: updating
                ? null
                : (value) {
                    if (value != null) controller.selectedStatus.value = value;
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.remarksController,
            enabled: !updating,
            minLines: 2,
            maxLines: 4,
            style: AppTextStyle.body,
            cursorColor: AppColors.primary,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(
              label: 'Remarks (optional)',
              hint: 'Enter a note about this status change',
              icon: Icons.notes,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: updating || selectedValue == null
                  ? null
                  : controller.updateOrderStatus,
              icon: updating
                  ? _buttonSpinner()
                  : Icon(Icons.save_outlined, color: AppColors.black),
              label: Text(
                updating ? 'Updating status...' : 'Update Status',
                style: AppTextStyle.title,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.grey,
                disabledForegroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ]);
    });
  }

  // ============================================================
  // STATUS HISTORY
  // ============================================================

  Widget _statusHistorySection() {
    return Obx(() {
      final history = controller.statusHistory;
      final loading = controller.isHistoryLoading.value;
      final error = controller.historyError.value;

      return _section('Status History', Icons.history, [
        if (loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(child: _loader()),
          )
        else if (error.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error, style: AppTextStyle.error),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.fetchStatusHistory,
                  icon: const Icon(Icons.refresh),
                  label: Text('Retry', style: AppTextStyle.buttonSecondary),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          )
        else if (history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No status history available yet.',
              style: AppTextStyle.emptyDescription,
            ),
          )
        else
          ...List.generate(history.length, (index) {
            final item = Map<String, dynamic>.from(history[index]);
            final fromStatus = item['fromStatus'] == null
                ? 'ORDER CREATED'
                : _value(item['fromStatus']).replaceAll('_', ' ');
            final toStatus = _value(item['toStatus']).replaceAll('_', ' ');
            final changedBy = item['changedBy'];
            final changedByName = _relatedName(changedBy, ['name', 'username']);
            final changedByRole = _relatedName(changedBy, ['role']);
            final remarks = _value(item['remarks']);
            final toColor = _statusColor(toStatus);

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == history.length - 1 ? 0 : 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: toColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: toColor,
                        ),
                      ),
                      if (index != history.length - 1)
                        Container(
                          width: 2,
                          height: 58,
                          color: AppColors.border,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (item['fromStatus'] != null) ...[
                                Text(
                                  fromStatus,
                                  style: AppTextStyle.bodySecondary,
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                              _statusChip(toStatus),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _dateTime(item['createdAt']),
                            style: AppTextStyle.bodySecondary,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Updated by: $changedByName'
                            '${changedByRole == '-' ? '' : ' ($changedByRole)'}',
                            style: AppTextStyle.label.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (remarks != '-') ...[
                            const SizedBox(height: 8),
                            Text('Remarks: $remarks', style: AppTextStyle.body),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        if (!loading)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: controller.fetchStatusHistory,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Refresh history',
                style: AppTextStyle.buttonSecondary,
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
      ]);
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order Details', style: AppTextStyle.appBarTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.darkGrey,
        iconTheme: const IconThemeData(color: AppColors.darkGrey),
        actions: [
          IconButton(
            tooltip: 'Print Order',
            icon: const Icon(Icons.print_outlined),
            onPressed: () async {
              final data = controller.order.value;

              if (data == null) {
                Get.snackbar(
                  'Order Error',
                  'Order details are not available.',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              try {
                final connected = await PrintBluetoothThermal.connectionStatus;

                debugPrint('ORDER PRINT: Bluetooth connected = $connected');
                debugPrint('ORDER PRINT: Order data = $data');

                if (!connected) {
                  Get.snackbar(
                    'Printer Disconnected',
                    'Open Printer Settings and connect MPT-III again.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                await OrderPrintService.printOrder(data);

                debugPrint('ORDER PRINT: printOrder completed');

                Get.snackbar(
                  'Print',
                  'Print request sent. Check the printer.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e, stackTrace) {
                debugPrint('ORDER PRINT ERROR: $e');
                debugPrintStack(stackTrace: stackTrace);

                Get.snackbar(
                  'Print Failed',
                  e.toString(),
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 5),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.fetchOrderDetails,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            color: AppColors.white,
            onSelected: (value) {
              if (value == 'edit') _openEditScreen();
              if (value == 'delete') _confirmDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 20),
                    const SizedBox(width: 10),
                    Text('Edit Order', style: AppTextStyle.body),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Delete Order',
                      style: AppTextStyle.body.copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: _loader());
        }

        if (controller.order.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    controller.errorMessage.value.isEmpty
                        ? 'Order details not found'
                        : controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.emptyTitle,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: controller.fetchOrderDetails,
                    icon: const Icon(Icons.refresh),
                    label: Text('Retry', style: AppTextStyle.button),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = controller.order.value!;
        final orderType = _value(data['orderType']).toUpperCase();
        final branch = data['branch'];
        final maker = data['maker'];
        final metal = data['metal'];
        final category = data['category'];

        final repairWidgets = <Widget>[];
        for (final item in controller.repairItems) {
          repairWidgets.add(
            _detail(
              'Repair type',
              _relatedName(item['repairType'], [
                'name',
                'repairTypeName',
                'title',
              ]),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.white,
          onRefresh: controller.fetchOrderDetails,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _section('Order Summary', Icons.receipt_long_outlined, [
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Order number',
                          style: AppTextStyle.bodySecondary.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: Text(
                          _value(data['orderNumber']),
                          style: AppTextStyle.orderNumber.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _detail('Order type', orderType),
                _detail('Status', data['status']),
                _detail('Priority', data['priority']),
                _detail(
                  'Expected delivery',
                  _date(data['expectedDeliveryDate']),
                ),
                _detail('Branch', _relatedName(branch, ['name', 'branchName'])),
                _detail('Maker', _relatedName(maker, ['name', 'makerName'])),
                _detail('Created on', _dateTime(data['createdAt'])),
                _detail(
                  'Created by',
                  controller.isHistoryLoading.value &&
                          controller.createdByUser == null
                      ? 'Loading...'
                      : _createdByText(controller.createdByUser),
                ),
              ]),

              _statusUpdateSection(data),
              _statusHistorySection(),

              if (orderType == 'NEW' || orderType == 'REPAIR')
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Obx(() {
                    final hasMaker =
                        data['makerId'] != null && data['maker'] != null;
                    final isSharing = controller.isSharingWhatsApp.value;

                    bool hasMediaType(String expected) {
                      return controller.mediaItems.any((m) {
                        final mediaType = '${m['mediaType'] ?? m['type'] ?? ''}'
                            .trim()
                            .toUpperCase();
                        final mimeType = '${m['mimeType'] ?? ''}'.toLowerCase();
                        final fileUrl = '${m['fileUrl'] ?? ''}'.toLowerCase();

                        if (mediaType == expected) return true;

                        if (expected == 'IMAGE') {
                          return mimeType.startsWith('image/') ||
                              RegExp(
                                r'\.(jpg|jpeg|png|webp|gif)(\?.*)?$',
                              ).hasMatch(fileUrl);
                        }
                        if (expected == 'VIDEO') {
                          return mimeType.startsWith('video/') ||
                              RegExp(
                                r'\.(mp4|mov|m4v|webm)(\?.*)?$',
                              ).hasMatch(fileUrl);
                        }
                        return false;
                      });
                    }

                    final hasImage = hasMediaType('IMAGE');
                    final hasVideo = hasMediaType('VIDEO');

                    final shareLabel = hasImage && hasVideo
                        ? 'Share Details + Image + Video on WhatsApp'
                        : hasImage
                        ? 'Share Details + Image on WhatsApp'
                        : hasVideo
                        ? 'Share Details + Video on WhatsApp'
                        : 'Share Details on WhatsApp';

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (!hasMaker || isSharing)
                            ? null
                            : controller.shareOrderWhatsApp,
                        icon: isSharing
                            ? _buttonSpinner()
                            : const Icon(Icons.share_outlined),
                        label: Text(
                          isSharing
                              ? 'Sending...'
                              : hasMaker
                              ? shareLabel
                              : 'Assign Maker to Share on WhatsApp',
                          textAlign: TextAlign.center,
                          style: AppTextStyle.button,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.grey,
                          disabledForegroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

              _section('Customer Details', Icons.person_outline, [
                _detail('Customer name', data['customerName']),
                _detail('Phone number', data['customerPhone']),
                _detail('Area', data['customerArea']),
              ]),

              if (orderType == 'NEW' || orderType == 'REPAIR')
                _section('Jewellery Details', Icons.diamond_outlined, [
                  _detail('Metal', _relatedName(metal, ['name', 'metalName'])),
                  _detail(
                    'Category',
                    _relatedName(category, ['name', 'categoryName']),
                  ),
                  _detail('Length', data['length']),
                  _detail('Length unit', data['lengthUnit']),
                  _detail('Size', data['size']),
                  _detail('Weight', data['weight']),
                  _detail('Purity', data['purity']),
                  _detail('Description', data['description']),
                ]),

              if (orderType == 'REPAIR')
                _section('Repair Details', Icons.build_outlined, [
                  ...repairWidgets,
                  _detail(
                    'Existing jewellery',
                    data['existingJewelleryDescription'],
                  ),
                  _detail('Problem / repair', data['problemDescription']),
                  _detail('Received item', data['receivedItemDescription']),
                ]),

              _section('Payment Details', Icons.payments_outlined, [
                _detail('Estimate', data['estimate']),
                _detail('Advance', data['advance']),
              ]),

              _mediaSection(controller.mediaItems),
              const SizedBox(height: 12),
            ],
          ),
        );
      }),
    );
  }
}

String _createdByText(Map<String, dynamic>? user) {
  if (user == null) return '-';
  final name = _relatedName(user, ['name', 'username']);
  final role = _relatedName(user, ['role']);
  return role == '-' ? name : '$name ($role)';
}

String _relatedName(dynamic value, List<String> keys) {
  if (value is! Map) return '-';
  for (final key in keys) {
    final result = value[key];
    if (result != null && '$result'.trim().isNotEmpty) {
      return '$result';
    }
  }
  return '-';
}

// ============================================================
// FULL SCREEN IMAGE PREVIEW
// ============================================================

/// Full screen image preview with pinch-to-zoom and double-tap zoom.
class _ImagePreviewScreen extends StatefulWidget {
  final String url;
  final String title;

  const _ImagePreviewScreen({required this.url, required this.title});

  @override
  State<_ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<_ImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();

  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      const scale = 3.0;
      _transformController.value = Matrix4.identity()
        ..translate(-position.dx * (scale - 1), -position.dy * (scale - 1))
        ..scale(scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: AppTextStyle.body.copyWith(
            fontSize: 15,
            color: AppColors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: GestureDetector(
        onDoubleTapDown: (details) => _doubleTapDetails = details,
        onDoubleTap: _handleDoubleTap,
        child: SizedBox.expand(
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Image.network(
                widget.url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    'Unable to load image',
                    style: AppTextStyle.body.copyWith(color: AppColors.white),
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// VIDEO PLAYER
// ============================================================

class _VideoMediaPlayer extends StatefulWidget {
  final String url;

  const _VideoMediaPlayer({super.key, required this.url});

  @override
  State<_VideoMediaPlayer> createState() => _VideoMediaPlayerState();
}

class _VideoMediaPlayerState extends State<_VideoMediaPlayer> {
  VideoPlayerController? _player;
  bool _loading = false;
  String? _error;

  Future<void> _openVideo() async {
    final videoUrl = widget.url;

    debugPrint('========== VIDEO DEBUG ==========');
    debugPrint('VIDEO URL: $videoUrl');

    final existing = _player;

    if (existing != null && existing.value.isInitialized) {
      if (existing.value.isPlaying) {
        await existing.pause();
      } else {
        await existing.play();
      }
      if (mounted) setState(() {});
      return;
    }

    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    VideoPlayerController? player;

    try {
      final uri = Uri.parse(videoUrl);

      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw FormatException('Invalid media URL: $videoUrl');
      }

      player = VideoPlayerController.networkUrl(uri);
      await player.initialize();

      debugPrint('VIDEO INITIALIZED: ${player.value.isInitialized}');
      debugPrint('VIDEO SIZE: ${player.value.size}');
      debugPrint('VIDEO DURATION: ${player.value.duration}');

      await player.setLooping(false);

      if (!mounted) {
        await player.dispose();
        return;
      }

      setState(() {
        _player = player;
        _loading = false;
      });

      await player.play();
      debugPrint('VIDEO PLAY REQUEST SENT');
    } catch (e, stackTrace) {
      debugPrint('VIDEO PLAYER ERROR: $e');
      debugPrint('VIDEO STACK TRACE: $stackTrace');

      await player?.dispose();

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Video playback failed. Check debug console.';
      });
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (player == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _openVideo,
              icon: const Icon(
                Icons.play_circle_outline,
                color: AppColors.black,
              ),
              label: Text(
                _loading ? 'Loading video...' : 'Play Video',
                style: AppTextStyle.emptyTitle,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          )
        else if (player.value.isInitialized)
          Column(
            children: [
              AspectRatio(
                aspectRatio: player.value.aspectRatio > 0
                    ? player.value.aspectRatio
                    : 16 / 9,
                child: VideoPlayer(player),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _openVideo,
                    icon: Icon(
                      player.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: AppColors.black,
                    ),
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      player,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primary,
                        bufferedColor: AppColors.border,
                        backgroundColor: AppColors.lightGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: AppTextStyle.error),
          ),
      ],
    );
  }
}

// ============================================================
// AUDIO PLAYER
// ============================================================

class _AudioMediaPlayer extends StatefulWidget {
  final String url;

  const _AudioMediaPlayer({super.key, required this.url});

  @override
  State<_AudioMediaPlayer> createState() => _AudioMediaPlayerState();
}

class _AudioMediaPlayerState extends State<_AudioMediaPlayer> {
  final AudioPlayer _player = AudioPlayer();

  bool _loading = false;
  bool _loaded = false;
  bool _seeking = false;
  double? _seekValue;
  String? _error;

  Future<void> _toggleAudio() async {
    try {
      if (!_loaded) {
        setState(() {
          _loading = true;
          _error = null;
        });

        await _player.setUrl(widget.url);

        if (!mounted) return;

        setState(() {
          _loaded = true;
          _loading = false;
        });
      }

      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('AUDIO PLAYER ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load audio. Check URL and audio format.';
      });
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _loading ? null : _toggleAudio,
              icon: Icon(
                _loading
                    ? Icons.hourglass_empty
                    : _player.playing
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            Expanded(
              child: Text(
                _loading
                    ? 'Loading audio...'
                    : _player.playing
                    ? 'Playing audio'
                    : 'Tap to play audio',
                style: AppTextStyle.body,
              ),
            ),
          ],
        ),
        if (_loaded)
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _player.duration ?? Duration.zero;

              final maxMs = duration.inMilliseconds > 0
                  ? duration.inMilliseconds
                  : 1;

              final currentMs = position.inMilliseconds
                  .clamp(0, maxMs)
                  .toDouble();

              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.primary,
                    ),
                    child: Slider(
                      min: 0,
                      max: maxMs.toDouble(),
                      value:
                          (_seeking && _seekValue != null
                                  ? _seekValue!
                                  : currentMs)
                              .clamp(0, maxMs.toDouble()),
                      onChanged: (value) {
                        setState(() {
                          _seeking = true;
                          _seekValue = value;
                        });
                      },
                      onChangeEnd: (value) async {
                        await _player.seek(
                          Duration(milliseconds: value.round()),
                        );
                        if (mounted) {
                          setState(() {
                            _seeking = false;
                            _seekValue = null;
                          });
                        }
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: AppTextStyle.caption,
                      ),
                      Text(
                        _formatDuration(duration),
                        style: AppTextStyle.caption,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: AppTextStyle.error),
          ),
      ],
    );
  }
}
