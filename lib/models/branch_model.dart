class BranchModel {
  final int id;
  final String name;
  final String code;
  final String? address;
  final String? phone;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BranchModel({
    required this.id,
    required this.name,
    required this.code,
    this.address,
    this.phone,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  /// Handles true/false, 1/0, "1"/"0", "true"/"false"
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'active';
    }
    return false;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      status: _parseBool(json['status']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  BranchModel copyWith({bool? status}) {
    return BranchModel(
      id: id,
      name: name,
      code: code,
      address: address,
      phone: phone,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}