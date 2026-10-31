import 'package:get/get.dart';
import 'package:jewellery_order_management/models/dashboard_summary_model.dart';
import 'package:jewellery_order_management/repositories/dashboard_repository.dart';
import 'package:jewellery_order_management/routes/app_routes.dart';
import 'package:jewellery_order_management/services/storage_service.dart';

class DashboardController extends GetxController {
  final DashboardRepository _repository = DashboardRepository();

  final RxMap<String, int> stats = <String, int>{
    'total': 0, 'draft': 0, 'new': 0, 'assigned': 0,
    'inProgress': 0, 'completed': 0, 'finalConfirmed': 0,
    'delivered': 0,'onHold': 0, 'cancelled': 0,
  }.obs;
  final RxBool isDashboardLoading = false.obs;
  final RxString dashboardError = ''.obs;

  Map<String, dynamic>? get user => StorageService.getUser();
  String get userName => user?['name']?.toString() ?? 'User';
  String get userRole => user?['role']?.toString() ?? '';

  int get totalOrders => stats['total'] ?? 0;
  int get draftOrders => stats['draft'] ?? 0;
  int get newOrders => stats['new'] ?? 0;
  int get assignedOrders => stats['assigned'] ?? 0;
  int get inProgressOrders => stats['inProgress'] ?? 0;
  int get completedOrders => stats['completed'] ?? 0;
  int get finalConfirmedOrders => stats['finalConfirmed'] ?? 0;
  int get deliveredOrders => stats['delivered'] ?? 0;
  // int get cleanupOrders => stats['cleanup'] ?? 0;
  int get onHoldOrders => stats['onHold'] ?? 0;
  int get cancelledOrders => stats['cancelled'] ?? 0;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardSummary();
  }

  Future<void> fetchDashboardSummary() async {
    isDashboardLoading.value = true;
    dashboardError.value = '';
    try {
      final DashboardSummaryModel result = await _repository.getDashboardSummary();
      stats.assignAll(result.toMap());
    } catch (error) {
      dashboardError.value = error.toString();
    } finally {
      isDashboardLoading.value = false;
    }
  }

  Future<void> logout() async {
    await StorageService.logout();
    Get.offAllNamed(AppRoutes.login);
  }
}
