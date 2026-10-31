class LoginResponseModel {
  final bool success;
  final String message;
  final String token;
  final Map<String, dynamic> user;

  LoginResponseModel({
    required this.success,
    required this.message,
    required this.token,
    required this.user,
  });

  factory LoginResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : <String, dynamic>{};

    return LoginResponseModel(
      success: json['success'] == true,

      message: json['message']?.toString() ?? '',

      token: data['token']?.toString() ?? '',

      user: data['user'] is Map
          ? Map<String, dynamic>.from(data['user'])
          : <String, dynamic>{},
    );
  }
}