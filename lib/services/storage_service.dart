import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  StorageService._();

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const String boxName = 'app_storage';

  static const String tokenKey = 'token';
  static const String userKey = 'user';

  static Box? _box;

  // ============================================================
  // INIT
  // ============================================================

  static Future<void> init() async {
    await Hive.initFlutter();

    if (Hive.isBoxOpen(boxName)) {
      _box = Hive.box(boxName);
    } else {
      _box = await Hive.openBox(boxName);
    }
  }

  // ============================================================
  // BOX
  // ============================================================

  static Box get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception(
        'StorageService is not initialized. '
        'Call StorageService.init() first.',
      );
    }

    return _box!;
  }

  // ============================================================
  // TOKEN
  // ============================================================

  static Future<void> saveToken(String token) async {
    await box.put(tokenKey, token);
  }

  static String? getToken() {
    final token = box.get(tokenKey);

    return token?.toString();
  }

  static Future<void> removeToken() async {
    await box.delete(tokenKey);
  }

  // ============================================================
  // USER
  // ============================================================

  static Future<void> saveUser(
    Map<String, dynamic> user,
  ) async {
    await box.put(userKey, user);
  }

  static Map<String, dynamic>? getUser() {
    final data = box.get(userKey);

    if (data == null) {
      return null;
    }

    return Map<String, dynamic>.from(data);
  }

  // ============================================================
  // SESSION
  // ============================================================

  static Future<void> clearSession() async {
    await box.delete(tokenKey);
    await box.delete(userKey);
  }

  static Future<void> logout() async {
    await clearSession();
  }

  // ============================================================
  // LOGIN STATUS
  // ============================================================

  static bool get isLoggedIn {
    final token = getToken();

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  static Future<void> clearAll() async {
    await box.clear();
  }
}