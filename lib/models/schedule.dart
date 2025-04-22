import 'package:flutter/foundation.dart';

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
  final String? reason;
  final String? reservationId;
  final int trainerId;
  final String trainerName;
  final int memberId;
  final String memberName;
  final int currentPtCount;
  final int totalCount;
  final int usedCount;
  final int remainingPtCount;
  final int? ptLogId;
  final bool isDeducted;

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
    required this.usedCount,
    required this.remainingPtCount,
    required this.ptLogId,
    required this.isDeducted,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    try {
      int timestamp;
      DateTime startTime;
      
      try {
        timestamp = json['startTime'] as int;
        if (timestamp > DateTime.now().millisecondsSinceEpoch / 1000 * 10) {
          // 밀리초 단위인 경우
          startTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else {
          // 초 단위인 경우
          startTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing startTime: $e, value: ${json['startTime']}');
        }
        // 기본값 설정
        startTime = DateTime.now();
      }
      
      DateTime endTime;
      try {
        timestamp = json['endTime'] as int;
        if (timestamp > DateTime.now().millisecondsSinceEpoch / 1000 * 10) {
          // 밀리초 단위인 경우
          endTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else {
          // 초 단위인 경우
          endTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing endTime: $e, value: ${json['endTime']}');
        }
        // 기본값 설정: 시작 시간 + 1시간
        endTime = startTime.add(const Duration(hours: 1));
      }

      return Schedule(
        id: json['id'] as int? ?? 0,
        ptContractId: json['ptContractId'] as int? ?? 0,
        startTime: startTime,
        endTime: endTime,
        status: (json['status'] as String?)?.toUpperCase() ?? 'SCHEDULED',
        reason: json['reason'] as String?,
        reservationId: json['reservationId'] as String?,
        trainerId: json['trainerId'] as int? ?? 0,
        trainerName: json['trainerName'] as String? ?? '알 수 없음',
        memberId: json['memberId'] as int? ?? 0,
        memberName: json['memberName'] as String? ?? '알 수 없음',
        currentPtCount: json['currentPtCount'] as int? ?? 0,
        totalCount: json['totalCount'] as int? ?? 0,
        usedCount: json['usedCount'] as int? ?? 0,
        remainingPtCount: json['remainingPtCount'] as int? ?? 0,
        ptLogId: json['ptLogId'] as int?,
        isDeducted: json['isDeducted'] as bool? ?? false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in Schedule.fromJson: $e');
        print('JSON data: $json');
      }
      // 기본적인 스케줄 객체 생성
      return Schedule(
        id: json['id'] as int? ?? 0,
        ptContractId: json['ptContractId'] as int? ?? 0,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        status: 'ERROR',
        reason: '데이터 파싱 오류',
        reservationId: null,
        trainerId: 0,
        trainerName: '오류',
        memberId: 0,
        memberName: '오류',
        currentPtCount: 0,
        totalCount: 0,
        usedCount: 0,
        remainingPtCount: 0,
        ptLogId: null,
        isDeducted: false,
      );
    }
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
    'usedCount': usedCount,
    'remainingPtCount': remainingPtCount,
    'ptLogId': ptLogId,
    'isDeducted': isDeducted,
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
    int? usedCount,
    int? remainingPtCount,
    int? ptLogId,
    bool? isDeducted,
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
    usedCount: usedCount ?? this.usedCount,
    remainingPtCount: remainingPtCount ?? this.remainingPtCount,
    ptLogId: ptLogId ?? this.ptLogId,
    isDeducted: isDeducted ?? this.isDeducted,
  );

  @override
  String toString() =>
      'Schedule(id: $id, memberName: $memberName, '
      'startTime: $startTime, endTime: $endTime, status: $status)';
}
