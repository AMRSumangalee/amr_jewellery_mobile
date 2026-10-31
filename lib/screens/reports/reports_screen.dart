import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:jewellery_order_management/utils/app_colors.dart';
import 'package:jewellery_order_management/utils/app_text_style.dart';

import 'reports_controller.dart';

class ReportsScreen extends GetView<ReportsController> {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: Text(
          'Order Reports',
          style: AppTextStyle.appBarTitle.copyWith(
            color: AppColors.black,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Export Reports',
            icon: const Icon(
              Icons.download_outlined,
              color: AppColors.black,
            ),
            onSelected: (value) {
              switch (value) {
                case 'pdf_download':
                  controller.exportPdf(action: ExportAction.download);
                  break;
                case 'excel_download':
                  controller.exportExcel(action: ExportAction.download);
                  break;
                case 'word_download':
                  controller.exportWord(action: ExportAction.download);
                  break;
                case 'pdf_share':
                  controller.exportPdf(action: ExportAction.share);
                  break;
                case 'excel_share':
                  controller.exportExcel(action: ExportAction.share);
                  break;
                case 'word_share':
                  controller.exportWord(action: ExportAction.share);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                enabled: false,
                height: 32,
                child: Text(
                  'Download to Downloads folder',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'pdf_download',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined),
                    SizedBox(width: 10),
                    Text('PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel_download',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined),
                    SizedBox(width: 10),
                    Text('Excel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'word_download',
                child: Row(
                  children: [
                    Icon(Icons.description_outlined),
                    SizedBox(width: 10),
                    Text('Word'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                enabled: false,
                height: 32,
                child: Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'pdf_share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined),
                    SizedBox(width: 10),
                    Text('PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel_share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined),
                    SizedBox(width: 10),
                    Text('Excel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'word_share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined),
                    SizedBox(width: 10),
                    Text('Word'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(
        () => Stack(
          children: [
            Column(
              children: [
                _buildSearchBar(context),
                _buildQuickRanges(context),
                _buildActiveFilters(),
                _buildSummary(),
                Expanded(child: _buildReportList()),
                _buildPagination(),
              ],
            ),
            if (controller.isExporting.value)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.primaryDark,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Preparing report...',
                            style: TextStyle(color: AppColors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH + FILTER BUTTON
  // ============================================================

  /// Date range is shown by the quick range chips, so it is not
  /// counted here. Only the extra filters are counted.
  int get _activeFilterCount {
    var count = 0;
    if (controller.selectedOrderType.value.isNotEmpty) count++;
    if (controller.selectedStatus.value.isNotEmpty) count++;
    if (controller.selectedBranchId.value != null) count++;
    if (controller.selectedMakerId.value != null) count++;
    return count;
  }

  Widget _buildSearchBar(BuildContext context) {
    final count = _activeFilterCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.searchController,
              textInputAction: TextInputAction.search,
              style: AppTextStyle.body.copyWith(
                color: AppColors.black,
              ),
              onSubmitted: (_) => controller.fetchReports(),
              decoration: _decoration(
                'Search order, customer or phone',
                icon: Icons.search,
              ).copyWith(
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: AppColors.black,
                  ),
                  onPressed: () => controller.fetchReports(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openFilterSheet(context),
                  child: const SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.tune,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK DATE RANGES: Today / This Week / This Month / Custom
  // ============================================================

  String _customLabel() {
    final from = controller.fromDate.value;
    final to = controller.toDate.value;

    if (controller.selectedRange.value != 'CUSTOM' ||
        from == null ||
        to == null) {
      return 'Custom';
    }

    final fmt = DateFormat('dd MMM');
    if (from == to) return fmt.format(from);
    return '${fmt.format(from)} - ${fmt.format(to)}';
  }

  Widget _buildQuickRanges(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        children: [
          _rangeChip(
            label: 'Today',
            icon: Icons.today,
            selected: controller.selectedRange.value == 'TODAY',
            onTap: () => controller.setDateRange('TODAY'),
          ),
          const SizedBox(width: 8),
          _rangeChip(
            label: 'This Week',
            icon: Icons.view_week_outlined,
            selected: controller.selectedRange.value == 'WEEK',
            onTap: () => controller.setDateRange('WEEK'),
          ),
          const SizedBox(width: 8),
          _rangeChip(
            label: 'This Month',
            icon: Icons.calendar_view_month,
            selected: controller.selectedRange.value == 'MONTH',
            onTap: () => controller.setDateRange('MONTH'),
          ),
          const SizedBox(width: 8),
          _rangeChip(
            label: _customLabel(),
            icon: Icons.date_range,
            selected: controller.selectedRange.value == 'CUSTOM',
            onTap: () => controller.chooseCustomRange(context),
          ),
        ],
      ),
    );
  }

  Widget _rangeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      showCheckmark: false,
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      avatar: Icon(icon, size: 16, color: AppColors.black),
      label: Text(
        label,
        style: TextStyle(
          color: AppColors.black,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // ACTIVE FILTER CHIPS (type, status, branch, maker)
  // ============================================================

  Widget _buildActiveFilters() {
    final chips = <Widget>[];

    if (controller.selectedOrderType.value.isNotEmpty) {
      chips.add(_filterChip(
        Icons.category_outlined,
        controller.selectedOrderType.value == 'NEW'
            ? 'New Order'
            : 'Repair',
        onRemove: () {
          controller.selectedOrderType.value = '';
          controller.fetchReports();
        },
      ));
    }

    if (controller.selectedStatus.value.isNotEmpty) {
      chips.add(_filterChip(
        Icons.flag_outlined,
        controller.selectedStatus.value.replaceAll('_', ' '),
        onRemove: () {
          controller.selectedStatus.value = '';
          controller.fetchReports();
        },
      ));
    }

    final branchId = controller.selectedBranchId.value;
    if (branchId != null) {
      final branch =
          controller.branches.firstWhereOrNull((b) => b.id == branchId);
      chips.add(_filterChip(
        Icons.store_outlined,
        branch?.name ?? 'Branch',
        onRemove: () {
          controller.selectedBranchId.value = null;
          controller.fetchReports();
        },
      ));
    }

    final makerId = controller.selectedMakerId.value;
    if (makerId != null) {
      final maker =
          controller.makers.firstWhereOrNull((m) => m.id == makerId);
      chips.add(_filterChip(
        Icons.person_outline,
        maker?.name ?? 'Maker',
        onRemove: () {
          controller.selectedMakerId.value = null;
          controller.fetchReports();
        },
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == chips.length) {
            return TextButton(
              onPressed: controller.clearFilters,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Clear all'),
            );
          }
          return chips[index];
        },
      ),
    );
  }

  Widget _filterChip(
    IconData icon,
    String label, {
    VoidCallback? onRemove,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 0, onRemove == null ? 10 : 4, 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.black),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyle.caption.copyWith(
              color: AppColors.black,
            ),
          ),
          if (onRemove != null)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.close,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BOTTOM SHEET
  // ============================================================

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Obx(() => _buildFilterSheetContent(sheetContext)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterSheetContent(BuildContext sheetContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                'Filter Orders',
                style: AppTextStyle.title.copyWith(
                  color: AppColors.black,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(sheetContext),
              icon: const Icon(Icons.close, color: AppColors.black),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _sheetLabel('Created Date'),
        Row(
          children: [
            Expanded(
              child: _dateButton(
                label: 'From Date',
                date: controller.fromDate.value,
                onTap: () => controller.chooseFromDate(sheetContext),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dateButton(
                label: 'To Date',
                date: controller.toDate.value,
                onTap: () => controller.chooseToDate(sheetContext),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _sheetLabel('Order Type & Status'),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: controller.selectedOrderType.value.isEmpty
                    ? null
                    : controller.selectedOrderType.value,
                isExpanded: true,
                decoration: _decoration('Order Type'),
                dropdownColor: AppColors.white,
                style: const TextStyle(color: AppColors.black),
                items: const [
                  DropdownMenuItem(
                    value: 'NEW',
                    child: Text('New Order'),
                  ),
                  DropdownMenuItem(
                    value: 'REPAIR',
                    child: Text('Repair'),
                  ),
                ],
                onChanged: (value) {
                  controller.selectedOrderType.value = value ?? '';
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: controller.selectedStatus.value.isEmpty
                    ? null
                    : controller.selectedStatus.value,
                isExpanded: true,
                decoration: _decoration('Status'),
                dropdownColor: AppColors.white,
                style: const TextStyle(color: AppColors.black),
                items: controller.statuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.replaceAll('_', ' '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  controller.selectedStatus.value = value ?? '';
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _sheetLabel('Branch & Maker'),
        if (controller.isLoadingBranches.value)
          const LinearProgressIndicator()
        else
          DropdownButtonFormField<int?>(
            value: controller.selectedBranchId.value,
            isExpanded: true,
            decoration: _decoration('Branch', icon: Icons.store_outlined),
            dropdownColor: AppColors.white,
            style: const TextStyle(color: AppColors.black),
            hint: const Text(
              'All Branches',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Branches'),
              ),
              ...controller.branches.map(
                (branch) => DropdownMenuItem<int?>(
                  value: branch.id,
                  child: Text(
                    branch.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              controller.selectedBranchId.value = value;
            },
          ),
        const SizedBox(height: 10),
        if (controller.isLoadingMakers.value)
          const LinearProgressIndicator()
        else
          DropdownButtonFormField<int?>(
            value: controller.selectedMakerId.value,
            isExpanded: true,
            decoration: _decoration('Maker', icon: Icons.person_outline),
            dropdownColor: AppColors.white,
            style: const TextStyle(color: AppColors.black),
            hint: const Text(
              'All Makers',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Makers'),
              ),
              ...controller.makers.map(
                (maker) => DropdownMenuItem<int?>(
                  value: maker.id,
                  child: Text(
                    maker.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              controller.selectedMakerId.value = value;
            },
          ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.clearFilters,
                icon: const Icon(Icons.clear, color: AppColors.black),
                label: Text(
                  'Clear',
                  style: AppTextStyle.buttonSecondary.copyWith(
                    color: AppColors.black,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  controller.fetchReports();
                },
                icon: const Icon(
                  Icons.filter_alt,
                  color: AppColors.black,
                ),
                label: Text(
                  'Apply Filters',
                  style: AppTextStyle.button.copyWith(
                    color: AppColors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Reports are filtered by order creation date.',
            style: AppTextStyle.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sheetLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyle.label.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _decoration(
    String label, {
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyle.label.copyWith(
        color: AppColors.textSecondary,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.primaryDark,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        backgroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month,
            size: 19,
            color: AppColors.black,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyle.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date == null
                      ? 'Select date'
                      : DateFormat('dd MMM yyyy').format(date),
                  style: AppTextStyle.label.copyWith(
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  String _rangeLabel() {
    switch (controller.selectedRange.value) {
      case 'TODAY':
        return 'Today';
      case 'WEEK':
        return 'This week';
      case 'MONTH':
        return 'This month';
      default:
        return _customLabel();
    }
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long,
            size: 18,
            color: AppColors.black,
          ),
          const SizedBox(width: 6),
          Text(
            '${controller.totalOrders.value} orders',
            style: AppTextStyle.title.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '• ${_rangeLabel()}',
            style: AppTextStyle.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (controller.totalPages.value > 1)
            Text(
              'Page ${controller.currentPage.value}/'
              '${controller.totalPages.value}',
              style: AppTextStyle.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => controller.fetchReports(
              page: controller.currentPage.value,
            ),
            icon: const Icon(
              Icons.refresh,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDERS LIST
  // ============================================================

  Widget _buildReportList() {
    if (controller.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryDark,
        ),
      );
    }

    if (controller.orders.isEmpty) {
      final isToday = controller.selectedRange.value == 'TODAY';

      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 58,
                color: AppColors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                isToday ? 'No Orders Today' : 'No Orders Found',
                style: AppTextStyle.emptyTitle.copyWith(
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                controller.errorMessage.value.isNotEmpty
                    ? controller.errorMessage.value
                    : isToday
                        ? 'No orders have been created today. '
                            'Check another date range.'
                        : 'Try changing the selected filters.',
                textAlign: TextAlign.center,
                style: AppTextStyle.emptyDescription.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (isToday)
                    OutlinedButton.icon(
                      onPressed: () => controller.setDateRange('MONTH'),
                      icon: const Icon(
                        Icons.calendar_view_month,
                        color: AppColors.black,
                      ),
                      label: Text(
                        'View this month',
                        style: AppTextStyle.buttonSecondary.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  if (_activeFilterCount > 0)
                    OutlinedButton.icon(
                      onPressed: controller.clearFilters,
                      icon: const Icon(Icons.clear, color: AppColors.black),
                      label: Text(
                        'Clear filters',
                        style: AppTextStyle.buttonSecondary.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryDark,
      onRefresh: () => controller.fetchReports(
        page: controller.currentPage.value,
      ),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        itemCount: controller.orders.length,
        itemBuilder: (context, index) {
          return _orderCard(controller.orders[index]);
        },
      ),
    );
  }

  Widget _orderCard(dynamic raw) {
    final order = raw as Map;

    final repairTypes = order['repairTypes'] is List
        ? order['repairTypes'] as List
        : <dynamic>[];

    final repairNames = repairTypes.map((item) {
      if (item is! Map) return '';

      final repair = item['repairType'];

      if (repair is Map) {
        return repair['name']?.toString() ?? '';
      }

      return item['name']?.toString() ?? '';
    }).where((name) => name.isNotEmpty).join(', ');

    final amount =
        order['totalAmount'] ?? order['totalPrice'] ?? order['amount'];

    final description = order['description'] ?? order['notes'];

    final orderType = order['orderType']?.toString() ?? '';
    final customerName = order['customerName']?.toString().trim() ?? '';
    final customerPhone = order['customerPhone']?.toString().trim() ?? '';

    return Card(
      color: AppColors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(Get.context!).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: AppColors.black,
          collapsedIconColor: AppColors.black,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              orderType == 'REPAIR'
                  ? Icons.build_outlined
                  : Icons.receipt_long,
              color: AppColors.black,
            ),
          ),
          title: Text(
            (order['orderNumber'] ?? 'Order #${order['id'] ?? '-'}')
                .toString(),
            style: AppTextStyle.orderNumber.copyWith(
              color: AppColors.black,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customerName.isNotEmpty)
                  Text(
                    customerPhone.isEmpty
                        ? customerName
                        : '$customerName  •  $customerPhone',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.body.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(order['createdAt']),
                  style: AppTextStyle.bodySecondary,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _statusChip(order['status']?.toString() ?? '-'),
                    if (orderType.isNotEmpty)
                      _statusChip(
                        orderType == 'NEW' ? 'New Order' : orderType,
                      ),
                    if (amount != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.currency_rupee,
                            size: 15,
                            color: AppColors.black,
                          ),
                          Text(
                            amount.toString(),
                            style: AppTextStyle.label.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 16, color: AppColors.border),
            _sectionTitle('Customer Details'),
            _detail(Icons.person_outline, 'Name', order['customerName']),
            _detail(Icons.phone_outlined, 'Phone', order['customerPhone']),
            _detail(
              Icons.location_on_outlined,
              'Area',
              order['customerArea'],
            ),
            if (order['customerAddress'] != null &&
                order['customerAddress'].toString().trim().isNotEmpty)
              _detail(
                Icons.home_outlined,
                'Address',
                order['customerAddress'].toString(),
              ),
            const Divider(height: 24, color: AppColors.border),
            _sectionTitle('Order Details'),
            _detail(
              Icons.calendar_today_outlined,
              'Created Date',
              _formatDate(order['createdAt']),
            ),
            _detail(Icons.category_outlined, 'Order Type', order['orderType']),
            _detail(Icons.flag_outlined, 'Priority', order['priority']),
            _detail(
              Icons.store_outlined,
              'Branch',
              _relationName(order['branch']),
            ),
            _detail(
              Icons.person_pin_outlined,
              'Maker',
              _relationName(order['maker']),
            ),
            _detail(
              Icons.diamond_outlined,
              'Metal',
              _relationName(order['metal']),
            ),
            _detail(
              Icons.inventory_2_outlined,
              'Category',
              _relationName(order['category']),
            ),
            if (repairNames.isNotEmpty)
              _detail(Icons.build_outlined, 'Repair Types', repairNames),
            if (description != null &&
                description.toString().trim().isNotEmpty)
              _detail(
                Icons.notes_outlined,
                'Description',
                description.toString(),
              ),
          ],
        ),
      ),
    );
  }

  String _relationName(dynamic value) {
    if (value is Map) {
      return (value['name'] ?? value['title'] ?? '-').toString();
    }
    return '-';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '-';

    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        title,
        style: AppTextStyle.title.copyWith(
          color: AppColors.black,
        ),
      ),
    );
  }

  Widget _detail(
    IconData icon,
    String label,
    dynamic rawValue,
  ) {
    final value = rawValue?.toString().trim();
    final displayValue = value == null || value.isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.black),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyle.body.copyWith(
                  color: AppColors.black,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: displayValue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.chip.copyWith(
          color: AppColors.black,
        ),
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    if (controller.totalPages.value <= 1) {
      return const SizedBox.shrink();
    }

    final canPrev =
        controller.currentPage.value > 1 && !controller.isLoading.value;
    final canNext =
        controller.currentPage.value < controller.totalPages.value &&
            !controller.isLoading.value;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canPrev
                    ? () => controller.fetchReports(
                          page: controller.currentPage.value - 1,
                        )
                    : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${controller.currentPage.value} / '
                '${controller.totalPages.value}',
                style: AppTextStyle.body.copyWith(
                  color: AppColors.black,
                ),
              ),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canNext
                    ? () => controller.fetchReports(
                          page: controller.currentPage.value + 1,
                        )
                    : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}