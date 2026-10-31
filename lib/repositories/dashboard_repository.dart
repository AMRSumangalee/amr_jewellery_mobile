import 'package:jewellery_order_management/models/dashboard_summary_model.dart';
import 'package:jewellery_order_management/services/api_constants.dart';
import 'package:jewellery_order_management/services/api_service.dart';

class DashboardRepository {
  final ApiService _apiService = ApiService.instance;

  Future<DashboardSummaryModel> getDashboardSummary() async {
    final response = await _apiService.get(
      ApiConstants.dashboardSummary,
    );

    final body = Map<String, dynamic>.from(response.data as Map);

    if (body['success'] != true) {
      throw Exception(
        body['message']?.toString() ??
            'Unable to load dashboard summary',
      );
    }

    final data = Map<String, dynamic>.from(
      body['data'] as Map,
    );

    return DashboardSummaryModel.fromJson(data);
  }
}