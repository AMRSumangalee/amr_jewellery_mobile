class MakerModel {
  final int id;
  final String name;
  final String? phone;
  final String? whatsappNumber;
  final String? specialization;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MakerModel({
    required this.id,
    required this.name,
    this.phone,
    this.whatsappNumber,
    this.specialization,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory MakerModel.fromJson(Map<String, dynamic> json) {
    return MakerModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      whatsappNumber: json['whatsappNumber']?.toString(),
      specialization: json['specialization']?.toString(),
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
