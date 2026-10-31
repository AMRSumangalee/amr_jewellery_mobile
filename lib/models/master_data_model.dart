class MasterDataModel {
  final int id;
  final String name;
  final String code;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MasterDataModel({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory MasterDataModel.fromJson(Map<String, dynamic> json) {
    return MasterDataModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      status: json['status'] == true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }
}
