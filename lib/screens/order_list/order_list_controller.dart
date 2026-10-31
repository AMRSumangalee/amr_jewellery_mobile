import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jewellery_order_management/repositories/order_list_repository.dart';

class OrderListController extends GetxController {
  final OrderListRepository _repository = OrderListRepository();

  final orders = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;

  final searchController = TextEditingController();

  final selectedOrderType = ''.obs;
  final selectedStatus = ''.obs;
  final selectedPriority = ''.obs;

  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final totalOrders = 0.obs;

  /// Orders shown per page. "Load more" fetches the next [pageSize].
  static const int pageSize = 10;

  /// Incremented on every fresh load (filters / search / refresh) so that
  /// a slow older response can never overwrite a newer one.
  int _requestId = 0;

  bool get hasMore => currentPage.value < totalPages.value;

@override
void onInit() {
  super.onInit();

  final arguments = Get.arguments;

  if (arguments is Map) {
    selectedStatus.value =
        (arguments['status'] ?? '').toString().toUpperCase();
  }

  fetchOrders();
}

  Future<void> fetchOrders({bool loadMore = false}) async {
    if (loadMore) {
      if (isLoading.value || isLoadingMore.value || !hasMore) return;
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      errorMessage.value = '';
      currentPage.value = 1;
    }

    final requestId = loadMore ? _requestId : ++_requestId;

    try {
      final result = await _repository.getOrders(
        page: loadMore ? currentPage.value + 1 : 1,
        limit: pageSize,
        search: searchController.text.trim(),
        orderType: selectedOrderType.value,
        status: selectedStatus.value,
        priority: selectedPriority.value,
      );

      // A newer fresh load started while this one was running: ignore it.
      if (requestId != _requestId) return;

      final rawOrders = result['orders'];
      final parsedOrders = rawOrders is List
          ? rawOrders
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      final pagination = result['pagination'];
      final paginationMap = pagination is Map
          ? Map<String, dynamic>.from(pagination)
          : <String, dynamic>{};

      if (loadMore) {
        orders.addAll(parsedOrders);
        currentPage.value =
            int.tryParse('${paginationMap['page']}') ?? currentPage.value + 1;
      } else {
        orders.assignAll(parsedOrders);
        currentPage.value = int.tryParse('${paginationMap['page']}') ?? 1;
      }

      totalOrders.value =
          int.tryParse('${paginationMap['total']}') ?? orders.length;

      totalPages.value =
          int.tryParse('${paginationMap['totalPages']}') ?? 1;
    } catch (e) {
      if (requestId != _requestId) return;

      errorMessage.value = e.toString().replaceFirst('Exception: ', '');

      if (!loadMore) {
        orders.clear();
      }

      Get.snackbar(
        'Orders',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (requestId == _requestId) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> searchOrders(String value) async {
    await fetchOrders();
  }

  Future<void> applyFilters() async {
    await fetchOrders();
  }

  Future<void> clearFilters() async {
    searchController.clear();
    selectedOrderType.value = '';
    selectedStatus.value = '';
    selectedPriority.value = '';
    await fetchOrders();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}