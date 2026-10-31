import 'package:dio/dio.dart';
import 'package:jewellery_order_management/services/api_service.dart';

class UserManagementRepository {
  final ApiService _apiService = ApiService.instance;

  // Change this path if your backend userRoutes
  // are mounted at a different endpoint.
  static const String _basePath = '/users';

  // ============================================================
  // GET ALL USERS
  // GET /api/users
  // ============================================================

  Future<Response> getUsers() async {
    try {
      return await _apiService.get(_basePath);
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // ============================================================
  // GET USER BY ID
  // GET /api/users/:id
  // ============================================================

  Future<Response> getUserById(int id) async {
    try {
      return await _apiService.get('$_basePath/$id');
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to fetch user details: $e');
    }
  }

  // ============================================================
  // CREATE USER
  // POST /api/users
  // ============================================================

  Future<Response> createUser({
    required String name,
    required String username,
    String? phone,
    required String password,
    required String role,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'name': name.trim(),
        'username': username.trim(),
        'password': password,
        'role': role,
      };

      if (phone != null && phone.trim().isNotEmpty) {
        data['phone'] = phone.trim();
      }

      return await _apiService.post(
        _basePath,
        data: data,
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // ============================================================
  // UPDATE USER
  // PUT /api/users/:id
  // ============================================================

  // UPDATE USER PROFILE
Future<Response> updateUser({
  required int id,
  required String name,
  required String username,
  String? phone,
  required String role,
}) async {
  try {
    final Map<String, dynamic> data = {
      'name': name.trim(),
      'username': username.trim(),
      'role': role,
      'phone': phone?.trim().isNotEmpty == true
          ? phone!.trim()
          : null,
    };

    return await _apiService.put(
      '$_basePath/$id',
      data: data,
    );
  } on DioException {
    rethrow;
  } catch (e) {
    throw Exception('Failed to update user: $e');
  }
}

// UPDATE USER PASSWORD

  // RESET USER PASSWORD
  // PATCH /api/users/:id/password
  Future<Response> updateUserPassword({
    required int id,
    required String newPassword,
  }) async {
    try {
      return await _apiService.patch(
        '$_basePath/$id/password',
        data: {
          'newPassword': newPassword,
        },
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }


  // ============================================================
  // UPDATE USER STATUS
  // PATCH /api/users/:id/status
  // ============================================================

  Future<Response> updateUserStatus({
    required int id,
    required String status,
  }) async {
    try {
      return await _apiService.patch(
        '$_basePath/$id/status',
        data: {
          'status': status,
        },
      );
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }
}
