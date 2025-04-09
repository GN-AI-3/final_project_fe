class Schedule {
  final int id;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime endTime;
  final String reason;
  final int reservationId;
  final DateTime startTime;
  final String status;
  final int ptContractId;
  final String? memberName; // 조회 후 설정될 멤버 이름

  Schedule({
    required this.id,
    required this.createdAt,
    required this.modifiedAt,
    required this.endTime,
    required this.reason,
    required this.reservationId,
    required this.startTime,
    required this.status,
    required this.ptContractId,
    this.memberName,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      modifiedAt: DateTime.parse(json['modified_at']),
      endTime: DateTime.parse(json['end_time']),
      reason: json['reason'],
      reservationId: json['reservation_id'],
      startTime: DateTime.parse(json['start_time']),
      status: json['status'],
      ptContractId: json['pt_contract_id'],
    );
  }
} 