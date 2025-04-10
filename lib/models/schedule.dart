class Schedule {
  final int id;
  final int ptContractId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String reservationId;
  final int trainerId;
  final String trainerName;
  final int memberId;
  final String memberName;
  final int currentPtCount;
  final int totalCount;
  final int remainingPtCount;

  Schedule({
    required this.id,
    required this.ptContractId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.reservationId,
    required this.trainerId,
    required this.trainerName,
    required this.memberId,
    required this.memberName,
    required this.currentPtCount,
    required this.totalCount,
    required this.remainingPtCount,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] ?? 0,
      ptContractId: json['ptContractId'] ?? 0,
      startTime: DateTime.fromMillisecondsSinceEpoch((json['startTime'] ?? 0) * 1000),
      endTime: DateTime.fromMillisecondsSinceEpoch((json['endTime'] ?? 0) * 1000),
      status: json['status'] ?? 'SCHEDULED',
      reservationId: json['reservationId'] ?? '',
      trainerId: json['trainerId'] ?? 0,
      trainerName: json['trainerName'] ?? '',
      memberId: json['memberId'] ?? 0,
      memberName: json['memberName'] ?? '',
      currentPtCount: json['currentPtCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      remainingPtCount: json['remainingPtCount'] ?? 0,
    );
  }
} 