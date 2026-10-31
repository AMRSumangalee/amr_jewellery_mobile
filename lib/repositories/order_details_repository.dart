
import 'package:get/get_connect/http/src/multipart/form_data.dart';
import 'package:jewellery_order_management/services/api_service.dart';
import 'package:jewellery_order_management/services/api_constants.dart';

class OrderDetailsRepository {
  final ApiService _api = ApiService.instance;

  // ============================================================
  // GET ORDER DETAILS
  // ============================================================

  Future<Map<String, dynamic>> getOrderDetails(int id) async {
    final response = await _api.get(
      ApiConstants.orderDetails(id),
    );

    final body = response.data;

    if (body is! Map || body['success'] != true) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ??
                'Unable to load order details'
            : 'Invalid API response',
      );
    }

    final data = body['data'];

    if (data is! Map) {
      throw Exception('Order details not found');
    }

    return Map<String, dynamic>.from(data);
  }

  // ============================================================
  // SHARE ORDER DETAILS ON WHATSAPP
  // POST /api/orders/:id/share-whatsapp
  // ============================================================

  Future<Map<String, dynamic>> shareOrderWhatsApp(int id) async {
    final response = await _api.post(
      ApiConstants.shareOrderWhatsApp(id),
      data: <String, dynamic>{},
    );

    final body = response.data;

    if (body is! Map || body['success'] != true) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ??
                'Unable to share order details on WhatsApp'
            : 'Invalid API response while sharing order details',
      );
    }

    return Map<String, dynamic>.from(body);
  }

  // ============================================================
  // SHARE ACTUAL ORDER IMAGE ON WHATSAPP
  // POST /api/orders/:id/share-whatsapp-image
  // ============================================================

  Future<Map<String, dynamic>> shareOrderWhatsAppImage(int id) async {
    final response = await _api.post(
      ApiConstants.shareOrderWhatsAppImage(id),
      data: <String, dynamic>{},
    );

    final body = response.data;

    if (body is! Map || body['success'] != true) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ??
                'Unable to share order image on WhatsApp'
            : 'Invalid API response while sharing order image',
      );
    }

    return Map<String, dynamic>.from(body);
  }



  // ============================================================
// SHARE ORDER VIDEO ON WHATSAPP
// POST /api/orders/:id/share-whatsapp-video
// ============================================================

Future<Map<String, dynamic>> shareOrderWhatsAppVideo(int id) async {
  final response = await _api.post(
    ApiConstants.shareOrderWhatsAppVideo(id),
    data: <String, dynamic>{},
  );

  final body = response.data;

  if (body is! Map || body['success'] != true) {
    throw Exception(
      body is Map
          ? body['message']?.toString() ??
              'Unable to share order video on WhatsApp'
          : 'Invalid API response while sharing order video',
    );
  }

  return Map<String, dynamic>.from(body);
}

  // ============================================================
  // GET ORDER STATUS HISTORY
  // GET /api/orders/:id/status-history
  // ============================================================

  Future<Map<String, dynamic>> getOrderStatusHistory(int id) async {
    final response = await _api.get(
      ApiConstants.orderStatusHistory(id),
    );

    final body = response.data;

    if (body is! Map || body['success'] != true) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ??
                'Unable to load status history'
            : 'Invalid API response',
      );
    }

    final data = body['data'];

    if (data is! Map) {
      throw Exception('Invalid status history response');
    }

    return Map<String, dynamic>.from(data);
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // PATCH /api/orders/:id/status
  // ============================================================

  Future<Map<String, dynamic>> updateOrderStatus(
    int id, {
    required String status,
    String? remarks,
  }) async {
    final response = await _api.patch(
      ApiConstants.updateOrderStatus(id),
      data: {
        'status': status,
        if (remarks != null && remarks.trim().isNotEmpty)
          'remarks': remarks.trim(),
      },
    );

    final body = response.data;

    if (body is! Map || body['success'] != true) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ??
                'Unable to update order status'
            : 'Invalid API response',
      );
    }

    return Map<String, dynamic>.from(body);
  }

  Future<void> deleteOrder(int orderId) async {
  // use the same dio instance / headers you use in getOrderDetails
  await _api.delete('/orders/$orderId');
}

Future<dynamic> updateOrder(int id, FormData formData) async {
  final response = await _api.put(
    '/orders/$id',
    data: formData,
  );
  return response;
}
}
