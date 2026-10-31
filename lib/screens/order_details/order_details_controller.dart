import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_order_management/repositories/order_details_repository.dart';

class OrderDetailsController extends GetxController {
  final OrderDetailsRepository _repository = OrderDetailsRepository();

  // ============================================================
  // OBSERVABLE STATE
  // ============================================================

  final order = Rxn<Map<String, dynamic>>();
  final statusHistory = <Map<String, dynamic>>[].obs;

  final isLoading = false.obs;
  final isHistoryLoading = false.obs;
  final isUpdatingStatus = false.obs;
  final isSharingWhatsApp = false.obs;
  final isDeleting = false.obs;

  final errorMessage = ''.obs;
  final historyError = ''.obs;
  final selectedStatus = ''.obs;

  final remarksController = TextEditingController();

  late final int orderId;

  // ============================================================
  // ALLOWED STATUS TRANSITIONS
  // ============================================================

  static const Map<String, List<String>> allowedTransitions = {
    'DRAFT': ['NEW', 'CANCELLED'],
    'NEW': ['ASSIGNED', 'ON_HOLD', 'CANCELLED'],
    'ASSIGNED': ['IN_PROGRESS', 'ON_HOLD', 'CANCELLED'],
    'IN_PROGRESS': ['COMPLETED', 'ON_HOLD', 'CANCELLED'],
    'COMPLETED': ['FINAL_CONFIRMED', 'IN_PROGRESS', 'ON_HOLD'],
    'FINAL_CONFIRMED': ['DELIVERED'],
    // 'CLEANUP': ['DELIVERED', 'FINAL_CONFIRMED'],
    'ON_HOLD': ['NEW', 'ASSIGNED', 'IN_PROGRESS', 'CANCELLED'],
    'DELIVERED': [],
    'CANCELLED': [],
  };

  String get currentStatus =>
      '${order.value?['status'] ?? ''}'.trim().toUpperCase();

  List<String> get availableStatuses => allowedTransitions[currentStatus] ?? [];

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments;

    if (arguments is Map && arguments['orderId'] != null) {
      orderId = int.tryParse('${arguments['orderId']}') ?? 0;
    } else {
      orderId = int.tryParse('${arguments ?? ''}') ?? 0;
    }

    if (orderId <= 0) {
      errorMessage.value = 'Invalid order ID';
      return;
    }

    fetchOrderDetails();
    fetchStatusHistory();
  }

  @override
  void onClose() {
    remarksController.dispose();
    super.onClose();
  }

  // ============================================================
  // FETCH ORDER DETAILS
  // ============================================================

  Future<void> fetchOrderDetails() async {
    if (orderId <= 0) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      order.value = await _repository.getOrderDetails(orderId);

      if (order.value == null) {
        errorMessage.value = 'Order details not found.';
        return;
      }

      if (currentStatus.isEmpty) {
        selectedStatus.value = '';
      } else if (!availableStatuses.contains(selectedStatus.value)) {
        selectedStatus.value = availableStatuses.isNotEmpty
            ? availableStatuses.first
            : '';
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // FETCH STATUS HISTORY
  // ============================================================

  Future<void> fetchStatusHistory() async {
    if (orderId <= 0) return;

    isHistoryLoading.value = true;
    historyError.value = '';

    try {
      final result = await _repository.getOrderStatusHistory(orderId);

      final rawHistory = result['history'];

      if (rawHistory is List) {
        statusHistory.assignAll(
          rawHistory
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(),
        );
      } else {
        statusHistory.clear();
      }
    } catch (e) {
      historyError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isHistoryLoading.value = false;
    }
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================

  Future<void> updateOrderStatus() async {
    if (orderId <= 0 || isUpdatingStatus.value) return;

    final newStatus = selectedStatus.value.trim().toUpperCase();

    if (!availableStatuses.contains(newStatus)) {
      Get.snackbar(
        'Invalid Status',
        'Please select an allowed next status.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isUpdatingStatus.value = true;

    try {
      final result = await _repository.updateOrderStatus(
        orderId,
        status: newStatus,
        remarks: remarksController.text.trim(),
      );

      Get.snackbar(
        'Success',
        result['message']?.toString() ?? 'Order status updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );

      remarksController.clear();

      await fetchOrderDetails();
      await fetchStatusHistory();
    } catch (e) {
      Get.snackbar(
        'Status Update Failed',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  // ============================================================
  // DELETE ORDER
  // ============================================================

  Future<void> deleteOrder() async {
    if (orderId <= 0 || isDeleting.value) return;

    isDeleting.value = true;

    try {
      await _repository.deleteOrder(orderId);

      // Go back to the list; the list should refresh when result == true.
      Get.back(result: true);

      Get.snackbar(
        'Deleted',
        'Order deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Delete Failed',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isDeleting.value = false;
    }
  }

  // ============================================================
  // MEDIA
  // ============================================================

  List<Map<String, dynamic>> get mediaItems {
    final media = order.value?['media'];

    if (media is! List) return [];

    return media
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // REPAIR TYPES
  // ============================================================

  List<Map<String, dynamic>> get repairItems {
    final items = order.value?['repairTypes'];

    if (items is! List) return [];

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // WHATSAPP SHARING
  // ORDER DETAILS + IMAGE (required) + VIDEO (optional)
  // ============================================================

  Future<void> shareOrderWhatsApp() async {
  if (orderId <= 0 || isSharingWhatsApp.value) return;

  final currentOrder = order.value;

  if (currentOrder == null) {
    Get.snackbar(
      'Order Not Loaded',
      'Please wait until order details are loaded.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  final orderType = '${currentOrder['orderType'] ?? ''}'.trim().toUpperCase();

  // NEW and REPAIR both allowed
  if (orderType != 'NEW' && orderType != 'REPAIR') {
    Get.snackbar(
      'Not Available',
      'WhatsApp sharing is available for NEW and REPAIR orders only.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  final maker = currentOrder['maker'];

  if (currentOrder['makerId'] == null || maker is! Map || maker.isEmpty) {
    Get.snackbar(
      'Maker Required',
      'Please assign a maker before sharing.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  bool isMediaType(Map<String, dynamic> item, String expectedType) {
    final mediaType = '${item['mediaType'] ?? item['type'] ?? ''}'
        .trim()
        .toUpperCase();
    final fileUrl = '${item['fileUrl'] ?? ''}'.toLowerCase();
    final mimeType = '${item['mimeType'] ?? ''}'.toLowerCase();

    if (mediaType == expectedType) return true;

    if (expectedType == 'IMAGE') {
      return mimeType.startsWith('image/') ||
          RegExp(r'\.(jpg|jpeg|png|webp|gif)(\?.*)?$').hasMatch(fileUrl);
    }
    if (expectedType == 'VIDEO') {
      return mimeType.startsWith('video/') ||
          RegExp(r'\.(mp4|mov|m4v|webm)(\?.*)?$').hasMatch(fileUrl);
    }
    return false;
  }

  final hasImage = mediaItems.any((item) => isMediaType(item, 'IMAGE'));
  final hasVideo = mediaItems.any((item) => isMediaType(item, 'VIDEO'));

  isSharingWhatsApp.value = true;

  final sent = <String>[];
  final failed = <String>[];

  try {
    // Step 1: details (always) - if this fails, stop everything.
    await _repository.shareOrderWhatsApp(orderId);
    sent.add('details');

    // Step 2: image (optional, independent)
    if (hasImage) {
      try {
        await _repository.shareOrderWhatsAppImage(orderId);
        sent.add('image');
      } catch (e) {
        debugPrint('WHATSAPP IMAGE ERROR: $e');
        failed.add('image: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }

    // Step 3: video (optional, independent)
    if (hasVideo) {
      try {
        await _repository.shareOrderWhatsAppVideo(orderId);
        sent.add('video');
      } catch (e) {
        debugPrint('WHATSAPP VIDEO ERROR: $e');
        failed.add('video: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }

    Get.snackbar(
      failed.isEmpty ? 'WhatsApp Sharing Completed' : 'Partially Sent',
      failed.isEmpty
          ? 'Sent: ${sent.join(', ')}'
          : 'Sent: ${sent.join(', ')}\nFailed: ${failed.join('; ')}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 6),
    );
  } catch (e) {
    Get.snackbar(
      'WhatsApp Sharing Failed',
      e.toString().replaceFirst('Exception: ', ''),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 6),
    );
  } finally {
    isSharingWhatsApp.value = false;
  }
}

  // ============================================================
  // CREATED BY
  // ============================================================

  // Prefers order['createdBy'] from the API, otherwise falls back to the
  // "ORDER CREATED" entry of the status history (fromStatus == null).
  Map<String, dynamic>? get createdByUser {
    final direct = order.value?['createdBy'];
    if (direct is Map) return Map<String, dynamic>.from(direct);

    for (final item in statusHistory) {
      if (item['fromStatus'] == null && item['changedBy'] is Map) {
        return Map<String, dynamic>.from(item['changedBy'] as Map);
      }
    }
    return null;
  }
}