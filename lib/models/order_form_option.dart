class OrderFormOption {
  final int id;
  final String name;
  final bool status;

  const OrderFormOption({
    required this.id,
    required this.name,
    this.status = true,
  });

  factory OrderFormOption.fromJson(Map<String, dynamic> json) {
    final rawId =
        json['id'] ??
        json['branchId'] ??
        json['metalId'] ??
        json['categoryId'] ??
        json['repairTypeId'] ??
        json['makerId'];
    final rawName =
        json['name'] ??
        json['branchName'] ??
        json['metalName'] ??
        json['categoryName'] ??
        json['repairTypeName'] ??
        json['title'] ??
        '';
    final rawStatus = json['status'] ?? json['isActive'] ?? true;
    return OrderFormOption(
      id: int.tryParse('$rawId') ?? 0,
      name: '$rawName',
      status:
          rawStatus == true ||
          rawStatus == 1 ||
          rawStatus == '1' ||
          rawStatus == 'ACTIVE',
    );
  }
}
