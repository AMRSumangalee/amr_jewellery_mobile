import 'package:jewellery_order_management/models/maker_model.dart';
import 'package:jewellery_order_management/services/api_constants.dart';
import 'package:jewellery_order_management/services/api_service.dart';

class MakerRepository {
  final ApiService _apiService = ApiService.instance;

  Future<List<MakerModel>> getMakers() async {
    final response = await _apiService.get(ApiConstants.makers);
    final responseData = Map<String, dynamic>.from(response.data as Map);
    final data = responseData['data'];

    if (data is! List) return <MakerModel>[];

    return data
        .whereType<Map>()
        .map((item) => MakerModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<MakerModel> createMaker({
    required String name,
    String? phone,
    String? whatsappNumber,
    String? specialization,
  }) async {
    final response = await _apiService.post(
      ApiConstants.makers,
      data: {
        'name': name.trim(),
        'phone': _clean(phone),
        'whatsappNumber': _clean(whatsappNumber),
        'specialization': _clean(specialization),
      },
    );

    final responseData = Map<String, dynamic>.from(response.data as Map);
    final data = responseData['data'];
    if (data is! Map) throw Exception('Invalid create maker response');

    return MakerModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<MakerModel> updateMaker({
    required int id,
    required String name,
    String? phone,
    String? whatsappNumber,
    String? specialization,
  }) async {
    final response = await _apiService.put(
      ApiConstants.makerDetails(id),
      data: {
        'name': name.trim(),
        'phone': _clean(phone),
        'whatsappNumber': _clean(whatsappNumber),
        'specialization': _clean(specialization),
      },
    );

    final responseData = Map<String, dynamic>.from(response.data as Map);
    final data = responseData['data'];
    if (data is! Map) throw Exception('Invalid update maker response');

    return MakerModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<MakerModel> updateMakerStatus({
    required int id,
    required bool status,
  }) async {
    final response = await _apiService.patch(
      '${ApiConstants.makerDetails(id)}/status',
      data: {'status': status},
    );

    final responseData = Map<String, dynamic>.from(response.data as Map);
    final data = responseData['data'];
    if (data is! Map) throw Exception('Invalid maker status response');

    return MakerModel.fromJson(Map<String, dynamic>.from(data));
  }

  String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}
