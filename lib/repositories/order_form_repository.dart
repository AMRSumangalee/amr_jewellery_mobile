import 'package:dio/dio.dart';

import 'package:jewellery_order_management/services/api_constants.dart';
import 'package:jewellery_order_management/services/api_service.dart';

import '../models/order_form_option.dart';

class OrderFormRepository {
  final ApiService _api = ApiService.instance;

  List<dynamic> _extractList(dynamic response) {
    dynamic value = response;
    if (value is Response) value = value.data;
    if (value is Map) {
      value = value['data'] ?? value['results'] ?? value['items'] ?? value;
      if (value is Map) value = value['data'] ?? value['items'] ?? value['results'] ?? [];
    }
    return value is List ? value : <dynamic>[];
  }

  Future<List<OrderFormOption>> _getOptions(String path) async {
    final response = await _api.get(path);
    return _extractList(response)
        .whereType<Map>()
        .map((e) => OrderFormOption.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id > 0 && e.name.trim().isNotEmpty && e.status)
        .toList();
  }

  Future<List<OrderFormOption>> getBranches() => _getOptions(ApiConstants.branches);
  Future<List<OrderFormOption>> getMetals() => _getOptions(ApiConstants.metals);
  Future<List<OrderFormOption>> getCategories() => _getOptions(ApiConstants.categories);
  Future<List<OrderFormOption>> getRepairTypes() => _getOptions(ApiConstants.repairTypes);
  Future<List<OrderFormOption>> getMakers() => _getOptions(ApiConstants.makers);

  Future<dynamic> createOrder(FormData formData) async {
    return _api.postMultipart(ApiConstants.orders, formData);
  }
  Future<dynamic> updateOrder(int id, FormData formData) async {
  final response = await _api.put(
    '/orders/$id',
    data: formData,
  );
  return response;
}
}
