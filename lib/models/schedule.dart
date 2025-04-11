class Schedule {
  static const String _defaultStatus = 'SCHEDULED';
  static const String _defaultReservationId = '';
  static const String _defaultName = '';
  static const int _defaultCount = 0;

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
  }) {
    _validateSchedule();
  }

  void _validateSchedule() {
    if (startTime.isAfter(endTime)) {
      throw ArgumentError('시작 시간은 종료 시간보다 빨라야 합니다.');
    }
    if (currentPtCount > totalCount) {
      throw ArgumentError('현재 PT 횟수는 총 PT 횟수를 초과할 수 없습니다.');
    }
    if (remainingPtCount < 0) {
      throw ArgumentError('남은 PT 횟수는 음수가 될 수 없습니다.');
    }
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] ?? 0,
      ptContractId: json['ptContractId'] ?? 0,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        (json['startTime'] ?? 0) * 1000,
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        (json['endTime'] ?? 0) * 1000,
      ),
      status: json['status'] ?? _defaultStatus,
      reservationId: json['reservationId'] ?? _defaultReservationId,
      trainerId: json['trainerId'] ?? 0,
      trainerName: json['trainerName'] ?? _defaultName,
      memberId: json['memberId'] ?? 0,
      memberName: json['memberName'] ?? _defaultName,
      currentPtCount: json['currentPtCount'] ?? _defaultCount,
      totalCount: json['totalCount'] ?? _defaultCount,
      remainingPtCount: json['remainingPtCount'] ?? _defaultCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ptContractId': ptContractId,
      'startTime': startTime.millisecondsSinceEpoch ~/ 1000,
      'endTime': endTime.millisecondsSinceEpoch ~/ 1000,
      'status': status,
      'reservationId': reservationId,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'memberId': memberId,
      'memberName': memberName,
      'currentPtCount': currentPtCount,
      'totalCount': totalCount,
      'remainingPtCount': remainingPtCount,
    };
  }

  Schedule copyWith({
    int? id,
    int? ptContractId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? reservationId,
    int? trainerId,
    String? trainerName,
    int? memberId,
    String? memberName,
    int? currentPtCount,
    int? totalCount,
    int? remainingPtCount,
  }) {
    return Schedule(
      id: id ?? this.id,
      ptContractId: ptContractId ?? this.ptContractId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      reservationId: reservationId ?? this.reservationId,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      currentPtCount: currentPtCount ?? this.currentPtCount,
      totalCount: totalCount ?? this.totalCount,
      remainingPtCount: remainingPtCount ?? this.remainingPtCount,
    );
  }

  @override
  String toString() {
    return 'Schedule(id: $id, memberName: $memberName, startTime: $startTime, endTime: $endTime, status: $status)';
  }
}
