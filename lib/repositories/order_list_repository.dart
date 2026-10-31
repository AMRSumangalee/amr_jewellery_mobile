
import 'package:jewellery_order_management/services/api_service.dart';
import 'package:jewellery_order_management/services/api_constants.dart';

class OrderListRepository {
  final ApiService _api = ApiService.instance;

  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 10,
    String? search,
    String? orderType,
    String? status,
    int? branchId,
    String? priority,
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
      if (priority != null && priority.isNotEmpty)
        'priority': priority,
    };

    final response = await _api.get(
      ApiConstants.orders,
      queryParameters: query,
    );

    final body = response.data;

    if (body is! Map) {
      throw Exception('Invalid orders API response');
    }

    if (body['success'] == false) {
      throw Exception(
        body['message']?.toString() ?? 'Failed to load orders',
      );
    }

    final dynamic data = body['data'];
    final dynamic pagination = body['pagination'];

    // Backend response:
    // { success: true, data: [...], pagination: {...} }
    if (data is List) {
      return {
        'orders': data,
        'pagination': pagination is Map
            ? Map<String, dynamic>.from(pagination)
            : <String, dynamic>{},
      };
    }

    // Alternative response:
    // { success: true, data: { orders: [...], pagination: {...} } }
    if (data is Map) {
      final payload = Map<String, dynamic>.from(data);

      if (payload['orders'] is List) {
        return {
          'orders': payload['orders'],
          'pagination': payload['pagination'] is Map
              ? Map<String, dynamic>.from(payload['pagination'])
              : pagination is Map
                  ? Map<String, dynamic>.from(pagination)
                  : <String, dynamic>{},
        };
      }
    }

    // Alternative response without the success/data wrapper.
    if (body['orders'] is List) {
      return {
        'orders': body['orders'],
        'pagination': pagination is Map
            ? Map<String, dynamic>.from(pagination)
            : <String, dynamic>{},
      };
    }

    throw Exception('Orders list not found in API response');
  }
}
