class DashboardSummaryModel {
  final int total;
  final int draft;
  final int newOrders;
  final int assigned;
  final int inProgress;
  final int completed;
  final int finalConfirmed;
  final int delivered;
  // final int cleanup;
  final int onHold;
  final int cancelled;

  const DashboardSummaryModel({
    required this.total,
    required this.draft,
    required this.newOrders,
    required this.assigned,
    required this.inProgress,
    required this.completed,
    required this.finalConfirmed,
    required this.delivered,
    // required this.cleanup,
    required this.onHold,
    required this.cancelled,
  });

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      total: _readInt(json['total']),
      draft: _readInt(json['draft']),
      newOrders: _readInt(json['new']),
      assigned: _readInt(json['assigned']),
      inProgress: _readInt(json['inProgress']),
      completed: _readInt(json['completed']),
      finalConfirmed: _readInt(json['finalConfirmed']),
      delivered: _readInt(json['delivered']),
      // cleanup: _readInt(json['cleanup']),
      onHold: _readInt(json['onHold']),
      cancelled: _readInt(json['cancelled']),
    );
  }

  Map<String, int> toMap() => {
    'total': total,
    'draft': draft,
    'new': newOrders,
    'assigned': assigned,
    'inProgress': inProgress,
    'completed': completed,
    'finalConfirmed': finalConfirmed,
    'delivered': delivered,
    // 'cleanup': cleanup,
    'onHold': onHold,
    'cancelled': cancelled,
  };
}
