import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:jewellery_order_management/routes/app_routes.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';
import 'package:jewellery_order_management/utils/app_text_style.dart';
import 'order_list_controller.dart';

class OrderListScreen extends GetView<OrderListController> {
  const OrderListScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
      case 'FINAL_CONFIRMED':
      case 'DELIVERED':
        return AppColors.success;
      case 'IN_PROGRESS':
      case 'ASSIGNED':
        return AppColors.info;
      case 'ON_HOLD':
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  void _openDetails(int? orderId) {
    if (orderId == null) return;
    Get.toNamed(AppRoutes.orderDetails, arguments: {'orderId': orderId});
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      style: AppTextStyle.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyle.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: [
        DropdownMenuItem(
          value: '',
          child: Text('All', style: AppTextStyle.body),
        ),
        ...options.map(
          (option) => DropdownMenuItem(
            value: option,
            child: Text(
              option.replaceAll('_', ' '),
              style: AppTextStyle.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _infoChip({required String label, required IconData icon}) {
    return Chip(
      label: Text(
        label,
        style: AppTextStyle.chip.copyWith(color: AppColors.black),
      ),
      avatar: Icon(icon, size: 16, color: AppColors.black),
      backgroundColor: AppColors.black.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.black.withValues(alpha: 0.2)),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          'Orders',
          style: AppTextStyle.appBarTitle.copyWith(color: AppColors.black),
        ),
        actions: [
          IconButton(
            onPressed: () => controller.fetchOrders(),
            icon: const Icon(Icons.refresh, color: AppColors.black),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.newOrder),
            icon: const Icon(Icons.add, color: AppColors.black),
            tooltip: 'Create order',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH + FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: controller.searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: controller.searchOrders,
            style: AppTextStyle.body,
            decoration: InputDecoration(
              hintText: 'Search order, customer or phone',
              hintStyle: AppTextStyle.bodySecondary,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  controller.searchController.clear();
                  controller.fetchOrders();
                },
                icon: const Icon(Icons.clear),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _filterDropdown(
                    label: 'Type',
                    value: controller.selectedOrderType.value,
                    options: const ['NEW', 'REPAIR'],
                    onChanged: (value) {
                      controller.selectedOrderType.value = value ?? '';
                      controller.applyFilters();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(
                  () => _filterDropdown(
                    label: 'Priority',
                    value: controller.selectedPriority.value,
                    options: const ['NORMAL', 'URGENT'],
                    onChanged: (value) {
                      controller.selectedPriority.value = value ?? '';
                      controller.applyFilters();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => _filterDropdown(
              label: 'Status',
              value: controller.selectedStatus.value,
              options: const [
                'DRAFT',
                'NEW',
                'ASSIGNED',
                'IN_PROGRESS',
                'COMPLETED',
                'FINAL_CONFIRMED',
                'DELIVERED',
                // 'CLEANUP',
                'ON_HOLD',
                'CANCELLED',
              ],
              onChanged: (value) {
                controller.selectedStatus.value = value ?? '';
                controller.applyFilters();
              },
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.filter_alt_off, color: AppColors.black),
              label: Text(
                'Clear filters',
                style: AppTextStyle.buttonSecondary.copyWith(
                  color: AppColors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIST (loading / error / empty / data)
  // ============================================================

  Widget _buildList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }

      if (controller.errorMessage.value.isNotEmpty &&
          controller.orders.isEmpty) {
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
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.error,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: () => controller.fetchOrders(),
                  icon: const Icon(Icons.refresh),
                  label: Text('Retry', style: AppTextStyle.button),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.orders.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text('No orders found', style: AppTextStyle.emptyTitle),
                const SizedBox(height: 4),
                Text(
                  'Try changing the filters or create a new order',
                  style: AppTextStyle.emptyDescription,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => controller.fetchOrders(),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: controller.orders.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.orders.length) {
              return _buildFooter();
            }
            return _buildOrderCard(controller.orders[index]);
          },
        ),
      );
    });
  }

  // ============================================================
  // FOOTER (Load more / Total)
  // ============================================================

  Widget _buildFooter() {
    // Obx here so the button reacts to isLoadingMore / pagination changes.
    return Obx(() {
      if (!controller.hasMore) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Total: ${controller.totalOrders.value} orders',
              style: AppTextStyle.bodySecondary.copyWith(
                color: AppColors.black,
              ),
            ),
          ),
        );
      }

      final loadingMore = controller.isLoadingMore.value;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.grey),
            ),
            onPressed: loadingMore
                ? null
                : () => controller.fetchOrders(loadMore: true),
            child: loadingMore
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.grey,
                    ),
                  )
                : Text('Load more', style: AppTextStyle.buttonSecondary.copyWith(
                  color: AppColors.black
                )),
          ),
        ),
      );
    });
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = int.tryParse('${order['id'] ?? ''}');
    final orderNumber = '${order['orderNumber'] ?? 'N/A'}';
    final customerName = '${order['customerName'] ?? 'Unknown customer'}';
    final phone = '${order['customerPhone'] ?? '-'}';
    final area = '${order['customerArea'] ?? '-'}';
    final type = '${order['orderType'] ?? 'NEW'}';
    final status = '${order['status'] ?? 'NEW'}';
    final priority = '${order['priority'] ?? 'NORMAL'}';
    final branch = order['branch'];
    final maker = order['maker'];

    final branchName = branch is Map
        ? '${branch['name'] ?? branch['branchName'] ?? '-'}'
        : '-';
    final makerName = maker is Map
        ? '${maker['name'] ?? maker['makerName'] ?? '-'}'
        : 'Not assigned';

    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: orderId == null ? null : () => _openDetails(orderId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      orderNumber,
                      style: AppTextStyle.orderNumber.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.replaceAll('_', ' '),
                      style: AppTextStyle.chip.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(customerName, style: AppTextStyle.title),
              const SizedBox(height: 5),
              Text('Phone: $phone', style: AppTextStyle.body),
              const SizedBox(height: 2),
              Text('Area: $area', style: AppTextStyle.body),
              const Divider(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _infoChip(
                    label: type,
                    icon: type == 'REPAIR'
                        ? Icons.build_outlined
                        : Icons.diamond_outlined,
                  ),
                  _infoChip(label: priority, icon: Icons.flag_outlined),
                ],
              ),
              const SizedBox(height: 8),
              Text('Branch: $branchName', style: AppTextStyle.bodySecondary),
              const SizedBox(height: 2),
              Text('Maker: $makerName', style: AppTextStyle.bodySecondary),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: orderId == null ? null : () => _openDetails(orderId),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View details',
                        style: AppTextStyle.buttonSecondary.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}