import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jewellery_order_management/services/api_constants.dart';
import 'package:jewellery_order_management/services/storage_service.dart';

class ApiService {
  // ============================================================
  // SINGLETON
  // ============================================================

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,

        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 3),

        headers: {
          "Accept": "application/json",
        },
      ),
    );

    // ==========================================================
    // INTERCEPTORS
    // ==========================================================

    dio.interceptors.add(
      InterceptorsWrapper(

        // --------------------------------------------------------
        // REQUEST
        // --------------------------------------------------------

        onRequest: (options, handler) async {
          final token = StorageService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }

          if (kDebugMode) {
            debugPrint(
              "➡️ ${options.method} ${options.baseUrl}${options.path}",
            );

            if (options.queryParameters.isNotEmpty) {
              debugPrint(
                "QUERY => ${options.queryParameters}",
              );
            }

            if (options.data != null) {
              debugPrint(
                "BODY => ${options.data}",
              );
            }
          }

          return handler.next(options);
        },

        // --------------------------------------------------------
        // RESPONSE
        // --------------------------------------------------------

        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              "✅ RESPONSE ${response.statusCode} => "
              "${response.requestOptions.path}",
            );

            debugPrint(
              "RESPONSE DATA => ${response.data}",
            );
          }

          return handler.next(response);
        },

        // --------------------------------------------------------
        // ERROR
        // --------------------------------------------------------

        onError: (DioException error, handler) async {
          if (kDebugMode) {
            debugPrint(
              "❌ API ERROR => "
              "${error.requestOptions.method} "
              "${error.requestOptions.path}",
            );

            debugPrint(
              "STATUS => ${error.response?.statusCode}",
            );

            debugPrint(
              "ERROR => ${error.message}",
            );

            debugPrint(
              "DATA => ${error.response?.data}",
            );
          }

          // ------------------------------------------------------
          // 401 UNAUTHORIZED
          // ------------------------------------------------------

          if (error.response?.statusCode == 401) {
            await StorageService.logout();
          }

          return handler.next(error);
        },
      ),
    );
  }

  static final ApiService instance = ApiService._internal();

  // ============================================================
  // DIO
  // ============================================================

  late final Dio dio;

  // ============================================================
  // GET
  // ============================================================

  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.get(
      url,
      queryParameters: queryParameters,
    );
  }

  // ============================================================
  // POST
  // ============================================================

  Future<Response> post(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.post(
      url,
      data: data,
      queryParameters: queryParameters,
    );
  }

  // ============================================================
  // PUT
  // ============================================================

  Future<Response> put(
  String url, {
  dynamic data,
  Map<String, dynamic>? queryParameters,
  Options? options,
}) async {
  return await dio.put(
    url,
    data: data,
    queryParameters: queryParameters,
    options: options,
  );
}

  // ============================================================
  // PATCH
  // ============================================================

  Future<Response> patch(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.patch(
      url,
      data: data,
      queryParameters: queryParameters,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<Response> delete(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.delete(
      url,
      data: data,
      queryParameters: queryParameters,
    );
  }

  // ============================================================
  // MULTIPART POST
  // ============================================================

  Future<Response> postMultipart(
    String url,
    FormData formData,
  ) async {
    return await dio.post(
      url,
      data: formData,
      options: Options(
        contentType: "multipart/form-data",
      ),
    );
  }

  // ============================================================
  // MULTIPART PUT
  // ============================================================

  Future<Response> putMultipart(
    String url,
    FormData formData,
  ) async {
    return await dio.put(
      url,
      data: formData,
      options: Options(
        contentType: "multipart/form-data",
      ),
    );
  }
}