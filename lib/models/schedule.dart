
/// Schedule 관련 상수 값들을 정의하는 클래스
class ScheduleConstants {
  static const String defaultStatus = 'SCHEDULED';
  static const String defaultReason = '';
  static const String defaultReservationId = '';
  static const String defaultName = '';
  static const int defaultCount = 0;
}

/// DateTime 관련 확장 메서드
extension DateTimeExtension on DateTime {
  int get secondsSinceEpoch => millisecondsSinceEpoch ~/ 1000;
}

class Schedule {
  final int id;
  final int ptContractId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String reason;
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
    required this.reason,
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
    final times = _parseAndSortTimes(json);

    return Schedule(
      id: json['id'] ?? 0,
      ptContractId: json['ptContractId'] ?? 0,
      startTime: times.start,
      endTime: times.end,
      status: json['status'] ?? ScheduleConstants.defaultStatus,
      reason: json['reason'] ?? ScheduleConstants.defaultReason,
      reservationId: json['reservationId'] ?? ScheduleConstants.defaultReservationId,
      trainerId: json['trainerId'] ?? 0,
      trainerName: json['trainerName'] ?? ScheduleConstants.defaultName,
      memberId: json['memberId'] ?? 0,
      memberName: json['memberName'] ?? ScheduleConstants.defaultName,
      currentPtCount: json['currentPtCount'] ?? ScheduleConstants.defaultCount,
      totalCount: json['totalCount'] ?? ScheduleConstants.defaultCount,
      remainingPtCount: json['remainingPtCount'] ?? ScheduleConstants.defaultCount,
    );
  }

  static ({DateTime start, DateTime end}) _parseAndSortTimes(Map<String, dynamic> json) {
    final startTime = DateTime.fromMillisecondsSinceEpoch(
      (json['startTime'] ?? 0) * 1000,
    );
    final endTime = DateTime.fromMillisecondsSinceEpoch(
      (json['endTime'] ?? 0) * 1000,
    );

    final sortedTimes = [startTime, endTime]..sort();
    return (start: sortedTimes[0], end: sortedTimes[1]);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ptContractId': ptContractId,
    'startTime': startTime.secondsSinceEpoch,
    'endTime': endTime.secondsSinceEpoch,
    'status': status,
    'reason': reason,
    'reservationId': reservationId,
    'trainerId': trainerId,
    'trainerName': trainerName,
    'memberId': memberId,
    'memberName': memberName,
    'currentPtCount': currentPtCount,
    'totalCount': totalCount,
    'remainingPtCount': remainingPtCount,
  };

  Schedule copyWith({
    int? id,
    int? ptContractId,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
    String? reason,
    String? reservationId,
    int? trainerId,
    String? trainerName,
    int? memberId,
    String? memberName,
    int? currentPtCount,
    int? totalCount,
    int? remainingPtCount,
  }) => Schedule(
    id: id ?? this.id,
    ptContractId: ptContractId ?? this.ptContractId,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    status: status ?? this.status,
    reason: reason ?? this.reason,
    reservationId: reservationId ?? this.reservationId,
    trainerId: trainerId ?? this.trainerId,
    trainerName: trainerName ?? this.trainerName,
    memberId: memberId ?? this.memberId,
    memberName: memberName ?? this.memberName,
    currentPtCount: currentPtCount ?? this.currentPtCount,
    totalCount: totalCount ?? this.totalCount,
    remainingPtCount: remainingPtCount ?? this.remainingPtCount,
  );

  @override
  String toString() => 'Schedule(id: $id, memberName: $memberName, '
      'startTime: $startTime, endTime: $endTime, status: $status)';
}
