import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:simple_file_saver/simple_file_saver.dart';
import 'package:share_plus/share_plus.dart';

import 'package:jewellery_order_management/models/branch_model.dart';
import 'package:jewellery_order_management/models/maker_model.dart';
import 'package:jewellery_order_management/repositories/branch_repository.dart';
import 'package:jewellery_order_management/repositories/maker_repository.dart';
import 'package:jewellery_order_management/repositories/reports_repository.dart';
import 'package:jewellery_order_management/utils/app_colors.dart';

/// How an exported report is delivered.
/// download -> saved directly into the phone's Downloads folder
/// share    -> opens the share sheet (WhatsApp, Gmail, Drive, ...)
enum ExportAction { download, share }

class ReportsController extends GetxController {
  final BranchRepository _branchRepository = BranchRepository();
  final MakerRepository _makerRepository = MakerRepository();
  final ReportsRepository _reportsRepository = ReportsRepository();

  final searchController = TextEditingController();

  final branches = <BranchModel>[].obs;
  final makers = <MakerModel>[].obs;
  final orders = <Map<String, dynamic>>[].obs;

  final isLoading = false.obs;
  final isLoadingBranches = false.obs;
  final isLoadingMakers = false.obs;
  final isExporting = false.obs;

  final Rxn<int> selectedBranchId = Rxn<int>();
  final Rxn<int> selectedMakerId = Rxn<int>();

  final selectedOrderType = ''.obs;
  final selectedStatus = ''.obs;

  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();

  /// Date range mode: 'TODAY' (default), 'WEEK', 'MONTH', 'CUSTOM'
  final selectedRange = 'TODAY'.obs;

  final totalOrders = 0.obs;
  final currentPage = 1.obs;
  final totalPages = 1.obs;

  final errorMessage = ''.obs;

  final List<String> statuses = const [
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
  ];

  @override
  void onInit() {
    super.onInit();

    // Default: only today's orders
    _applyRange('TODAY');

    loadBranches();
    loadMakers();
    fetchReports();
  }

  // ============================================================
  // LOAD BRANCHES
  // ============================================================

  Future<void> loadBranches() async {
    try {
      isLoadingBranches.value = true;
      final result = await _branchRepository.getBranches();
      branches.assignAll(result);
    } catch (e) {
      debugPrint('REPORT BRANCH LOAD ERROR: $e');
      _showMessage('Error', 'Unable to load branches.');
    } finally {
      isLoadingBranches.value = false;
    }
  }

  // ============================================================
  // LOAD MAKERS
  // ============================================================

  Future<void> loadMakers() async {
    try {
      isLoadingMakers.value = true;
      final result = await _makerRepository.getMakers();
      makers.assignAll(result);
    } catch (e) {
      debugPrint('REPORT MAKER LOAD ERROR: $e');
      _showMessage('Error', 'Unable to load makers.');
    } finally {
      isLoadingMakers.value = false;
    }
  }

  // ============================================================
  // DATE RANGE (Today / This Week / This Month / Custom)
  // ============================================================

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Sets fromDate / toDate for a quick range. Does NOT fetch.
  void _applyRange(String range) {
    final today = _today;

    switch (range) {
      case 'WEEK':
        // Week starts on Monday
        fromDate.value = today.subtract(Duration(days: today.weekday - 1));
        toDate.value = today;
        selectedRange.value = 'WEEK';
        break;
      case 'MONTH':
        fromDate.value = DateTime(today.year, today.month, 1);
        toDate.value = today;
        selectedRange.value = 'MONTH';
        break;
      case 'TODAY':
      default:
        fromDate.value = today;
        toDate.value = today;
        selectedRange.value = 'TODAY';
        break;
    }
  }

  /// Quick range chips: TODAY / WEEK / MONTH
  Future<void> setDateRange(String range) async {
    _applyRange(range);
    await fetchReports();
  }

  /// Makes the OK / Cancel buttons of the date picker black.
  Widget _blackPickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.black,
          ),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  /// Custom chip: pick a start and end date in one dialog.
  Future<void> chooseCustomRange(BuildContext context) async {
    final today = _today;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: fromDate.value ?? today,
        end: toDate.value ?? today,
      ),
      helpText: 'Select date range',
      builder: _blackPickerTheme,
    );

    if (picked == null) return;

    fromDate.value = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    toDate.value = DateTime(
      picked.end.year,
      picked.end.month,
      picked.end.day,
    );
    selectedRange.value = 'CUSTOM';

    await fetchReports();
  }

  // Single date pickers (used inside the filter sheet)

  Future<void> chooseFromDate(BuildContext context) async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: fromDate.value ?? now,
      firstDate: DateTime(2000),
      lastDate: toDate.value ?? now,
      helpText: 'Select start date',
      builder: _blackPickerTheme,
    );

    if (selected != null) {
      fromDate.value = DateTime(
        selected.year,
        selected.month,
        selected.day,
      );
      selectedRange.value = 'CUSTOM';
    }
  }

  Future<void> chooseToDate(BuildContext context) async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: toDate.value ?? now,
      firstDate: fromDate.value ?? DateTime(2000),
      lastDate: now,
      helpText: 'Select end date',
      builder: _blackPickerTheme,
    );

    if (selected != null) {
      toDate.value = DateTime(
        selected.year,
        selected.month,
        selected.day,
      );
      selectedRange.value = 'CUSTOM';
    }
  }

  // ============================================================
  // FETCH REPORTS
  // ============================================================

  Future<void> fetchReports({int? page}) async {
    if (isLoading.value) return;

    currentPage.value = page ?? 1;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _reportsRepository.getReports(
        page: currentPage.value,
        limit: 100,
        search: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
        fromDate: fromDate.value == null
            ? null
            : DateFormat('yyyy-MM-dd').format(fromDate.value!),
        toDate: toDate.value == null
            ? null
            : DateFormat('yyyy-MM-dd').format(toDate.value!),
        orderType: selectedOrderType.value.isEmpty
            ? null
            : selectedOrderType.value,
        status: selectedStatus.value.isEmpty
            ? null
            : selectedStatus.value,
        branchId: selectedBranchId.value,
        makerId: selectedMakerId.value,
      );

      final dynamic rawOrders = result['data'] ?? result['orders'] ?? [];
      final dynamic pagination = result['pagination'] ?? {};

      if (rawOrders is List) {
        orders.assignAll(
          rawOrders.whereType<Map>().map(
                (item) => Map<String, dynamic>.from(item),
              ),
        );
      } else {
        orders.clear();
      }

      totalOrders.value = _toInt(
        pagination is Map ? pagination['total'] : null,
        fallback: orders.length,
      );

      totalPages.value = _toInt(
        pagination is Map ? pagination['totalPages'] : null,
        fallback: 1,
      );

      if (totalPages.value < 1) totalPages.value = 1;
      if (currentPage.value > totalPages.value) {
        currentPage.value = totalPages.value;
      }
    } catch (e) {
      debugPrint('FETCH REPORTS ERROR: $e');
      errorMessage.value = 'Unable to load reports. Please try again.';
      orders.clear();
      totalOrders.value = 0;
      _showMessage('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // CLEAR FILTERS (resets back to Today)
  // ============================================================

  Future<void> clearFilters() async {
    searchController.clear();
    _applyRange('TODAY');

    selectedOrderType.value = '';
    selectedStatus.value = '';
    selectedBranchId.value = null;
    selectedMakerId.value = null;

    await fetchReports();
  }

  // ============================================================
  // COMMON ORDER DETAILS FOR EXPORT
  // Media URLs are intentionally excluded.
  // ============================================================

  static const List<String> _headers = [
    'Order Number',
    'Customer Name',
    'Phone',
    'Area',
    'Order Type',
    'Status',
    'Priority',
    'Created Date',
    'Branch',
    'Maker',
    'Metal',
    'Category',
    'Repair Types',
    'Amount',
    'Description',
  ];

  String _relationName(dynamic value) {
    if (value is Map) {
      return (value['name'] ?? value['title'] ?? '-').toString();
    }
    return '-';
  }

  String _repairTypes(dynamic value) {
    if (value is! List) return '-';

    final names = <String>[];

    for (final item in value) {
      if (item is! Map) continue;

      final repair = item['repairType'];

      final name = repair is Map
          ? repair['name']?.toString()
          : item['name']?.toString();

      if (name != null && name.trim().isNotEmpty) {
        names.add(name);
      }
    }

    return names.isEmpty ? '-' : names.join(', ');
  }

  String _date(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '-';

    return DateFormat('dd-MM-yyyy HH:mm').format(date.toLocal());
  }

  List<String> _row(Map<String, dynamic> order) {
    final amount = order['totalAmount'] ??
        order['totalPrice'] ??
        order['amount'] ??
        '-';

    final description =
        order['description'] ?? order['notes'] ?? '-';

    return [
      (order['orderNumber'] ?? order['id'] ?? '-').toString(),
      (order['customerName'] ?? '-').toString(),
      (order['customerPhone'] ?? '-').toString(),
      (order['customerArea'] ?? '-').toString(),
      (order['orderType'] ?? '-').toString(),
      (order['status'] ?? '-').toString(),
      (order['priority'] ?? '-').toString(),
      _date(order['createdAt']),
      _relationName(order['branch']),
      _relationName(order['maker']),
      _relationName(order['metal']),
      _relationName(order['category']),
      _repairTypes(order['repairTypes']),
      amount.toString(),
      description.toString(),
    ];
  }

  List<List<String>> _exportRows() {
    return orders.map(_row).toList();
  }

  String _fileStamp() {
    return DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
  }

  /// Delivers the generated bytes either by saving into the Downloads
  /// folder or by opening the share sheet.
  Future<void> _deliver({
    required Uint8List bytes,
    required String extension,
    required String mimeType,
    required String title,
    required ExportAction action,
  }) async {
    final baseName = 'order_reports_${_fileStamp()}';

    if (action == ExportAction.download) {
      await SimpleFileSaver.saveFile(
        fileInfo: FileSaveInfo.fromBytes(
          bytes: bytes,
          basename: baseName,
          extension: extension,
        ),
      );

      _showMessage(
        'Download Complete',
        '$baseName.$extension saved in your Downloads folder.',
      );
      return;
    }

    // Share: write to temp folder, then open the share sheet
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$baseName.$extension');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: title,
      text: title,
    );
  }

  // ============================================================
  // PDF EXPORT
  // ============================================================

  Future<void> exportPdf({
    ExportAction action = ExportAction.download,
  }) async {
    if (orders.isEmpty) {
      _showMessage('No Data', 'No orders available to export.');
      return;
    }

    isExporting.value = true;

    try {
      final pdf = pw.Document();
      final rows = _exportRows();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            pw.Text(
              'Order Reports',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Created: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
            ),
            pw.Text('Orders in this report: ${orders.length}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: _headers,
              data: rows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 7,
              ),
              cellStyle: const pw.TextStyle(fontSize: 6),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE8E8E8),
              ),
              border: pw.TableBorder.all(
                color: const PdfColor.fromInt(0xFFCCCCCC),
                width: 0.5,
              ),
            ),
          ],
        ),
      );

      await _deliver(
        bytes: await pdf.save(),
        extension: 'pdf',
        mimeType: 'application/pdf',
        title: 'Order Reports (PDF)',
        action: action,
      );
    } catch (e) {
      debugPrint('PDF EXPORT ERROR: $e');
      _showMessage('Export Error', 'Unable to export PDF.\n$e');
    } finally {
      isExporting.value = false;
    }
  }

  // ============================================================
  // EXCEL EXPORT
  // download -> Downloads folder, share -> share sheet
  // ============================================================

  Future<void> exportExcel({
    ExportAction action = ExportAction.download,
  }) async {
    if (orders.isEmpty) {
      _showMessage('No Data', 'No orders available to export.');
      return;
    }

    isExporting.value = true;

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Order Reports'];

      // Remove the default empty "Sheet1"
      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null && defaultSheet != 'Order Reports') {
        excel.delete(defaultSheet);
      }

      sheet.appendRow(
        _headers.map((value) => TextCellValue(value)).toList(),
      );

      for (final row in _exportRows()) {
        sheet.appendRow(
          row.map((value) => TextCellValue(value)).toList(),
        );
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Unable to generate Excel file.');
      }

      await _deliver(
        bytes: Uint8List.fromList(bytes),
        extension: 'xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        title: 'Order Reports (Excel)',
        action: action,
      );
    } catch (e) {
      debugPrint('EXCEL EXPORT ERROR: $e');
      _showMessage('Export Error', 'Unable to export Excel.\n$e');
    } finally {
      isExporting.value = false;
    }
  }

  // ============================================================
  // WORD-READABLE DOCUMENT EXPORT
  // Saves an HTML document with .doc extension.
  // ============================================================

  Future<void> exportWord({
    ExportAction action = ExportAction.download,
  }) async {
    if (orders.isEmpty) {
      _showMessage('No Data', 'No orders available to export.');
      return;
    }

    isExporting.value = true;

    try {
      final buffer = StringBuffer();

      buffer.writeln('<html><head><meta charset="UTF-8">');
      buffer.writeln(
        '<style>body{font-family:Arial}table{border-collapse:collapse;width:100%;font-size:9px}th,td{border:1px solid #ccc;padding:5px;text-align:left}th{background:#eee}</style>',
      );
      buffer.writeln('</head><body>');
      buffer.writeln('<h2>Order Reports</h2>');
      buffer.writeln('<p>Total orders: ${orders.length}</p>');
      buffer.writeln('<table><thead><tr>');

      for (final header in _headers) {
        buffer.writeln('<th>${_escapeHtml(header)}</th>');
      }

      buffer.writeln('</tr></thead><tbody>');

      for (final row in _exportRows()) {
        buffer.writeln('<tr>');
        for (final value in row) {
          buffer.writeln('<td>${_escapeHtml(value)}</td>');
        }
        buffer.writeln('</tr>');
      }

      buffer.writeln('</tbody></table></body></html>');

      await _deliver(
        bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
        extension: 'doc',
        mimeType: 'application/msword',
        title: 'Order Reports (Word)',
        action: action,
      );
    } catch (e) {
      debugPrint('WORD EXPORT ERROR: $e');
      _showMessage('Export Error', 'Unable to export document.\n$e');
    } finally {
      isExporting.value = false;
    }
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}