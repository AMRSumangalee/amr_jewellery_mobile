import 'package:jewellery_order_management/models/login_response_model.dart';
import 'package:jewellery_order_management/services/api_constants.dart';
import 'package:jewellery_order_management/services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService.instance;

  Future<LoginResponseModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
      },
    );

    return LoginResponseModel.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _apiService.get(
      ApiConstants.me,
    );

    return Map<String, dynamic>.from(response.data);
  }
}