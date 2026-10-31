import 'package:jewellery_order_management/models/master_data_model.dart';
import 'package:jewellery_order_management/services/api_constants.dart';
import 'package:jewellery_order_management/services/api_service.dart';

enum MasterDataType { metals, categories, repairTypes }

class MasterDataRepository {
  final ApiService _apiService = ApiService.instance;

  String _endpoint(MasterDataType type) {
    switch (type) {
      case MasterDataType.metals:
        return ApiConstants.metals;
      case MasterDataType.categories:
        return ApiConstants.categories;
      case MasterDataType.repairTypes:
        return ApiConstants.repairTypes;
    }
  }

  Future<List<MasterDataModel>> getItems(MasterDataType type) async {
    final response = await _apiService.get(_endpoint(type));
    final responseData = Map<String, dynamic>.from(response.data as Map);
    final data = responseData['data'];

    if (data is! List) return <MasterDataModel>[];

    return data
        .whereType<Map>()
        .map(
          (item) => MasterDataModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<MasterDataModel> createItem({
    required MasterDataType type,
    required String name,
    required String code,
    required bool status,
  }) async {
    final response = await _apiService.post(
      _endpoint(type),
      data: {'name': name, 'code': code, 'status': status},
    );

    final responseData = Map<String, dynamic>.from(response.data as Map);
    final data = responseData['data'];

    if (data is! Map) {
      throw Exception('Invalid create response from server');
    }

    return MasterDataModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<MasterDataModel> updateItem({
    required MasterDataType type,
    required int id,
    required String name,
    required String code,
    required bool status,
  }) async {
    final response = await _apiService.put(
      '${_endpoint(type)}/$id',
      data: {'name': name, 'code': code, 'status': status},
    );

    final responseData = Map<String, dynamic>.from(response.data as Map);
    final data = responseData['data'];

    if (data is! Map) {
      throw Exception('Invalid update response from server');
    }

    return MasterDataModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<MasterDataModel> updateStatus({
    required MasterDataType type,
    required int id,
    required bool status,
  }) async {
    final String endpoint;

    switch (type) {
      case MasterDataType.metals:
        endpoint = '${ApiConstants.metals}/$id/status';
        break;

      case MasterDataType.categories:
        endpoint = '${ApiConstants.categories}/$id/status';
        break;

      case MasterDataType.repairTypes:
        endpoint = '${ApiConstants.repairTypes}/$id/status';
        break;
    }

    final response = await _apiService.patch(
      endpoint,
      data: {'status': status},
    );

    final responseData = Map<String, dynamic>.from(response.data as Map);

    final data = responseData['data'];

    if (data is! Map) {
      throw Exception('Invalid status update response');
    }

    return MasterDataModel.fromJson(Map<String, dynamic>.from(data));
  }
}
