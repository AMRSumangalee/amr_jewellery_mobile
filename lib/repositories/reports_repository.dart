
import 'package:jewellery_order_management/services/api_service.dart';
import 'package:jewellery_order_management/services/api_constants.dart';

class ReportsRepository {
  final ApiService _api = ApiService.instance;

  Future<Map<String, dynamic>> getReports({
    int page = 1,
    int limit = 100,
    String? search,
    String? orderType,
    String? status,
    int? branchId,
    int? makerId,
    String? fromDate,
    String? toDate,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.trim().isNotEmpty)
        'search': search.trim(),
      if (orderType != null && orderType.isNotEmpty)
        'orderType': orderType,
      if (status != null && status.isNotEmpty)
        'status': status,
      if (branchId != null) 'branchId': branchId,
      if (makerId != null) 'makerId': makerId,
      if (fromDate != null && fromDate.isNotEmpty)
        'fromDate': fromDate,
      if (toDate != null && toDate.isNotEmpty)
        'toDate': toDate,
    };

    final response = await _api.get(
      ApiConstants.orders,
      queryParameters: query,
    );

    final body = response.data;

    if (body is! Map) {
      throw Exception('Invalid reports API response');
    }

    if (body['success'] == false) {
      throw Exception(
        body['message']?.toString() ?? 'Failed to load reports',
      );
    }

    final data = body['data'];
    final pagination = body['pagination'];

    if (data is! List) {
      throw Exception('Reports list not found in API response');
    }

    return {
      'orders': data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      'pagination': pagination is Map
          ? Map<String, dynamic>.from(pagination)
          : <String, dynamic>{},
    };
  }
}
