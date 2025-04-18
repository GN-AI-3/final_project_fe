class MemberPtLog {
  final int ptScheduleId;
  final String timestamp;
  final String finalResponse;
  final int executionTime;

  MemberPtLog({
    required this.ptScheduleId,
    required this.timestamp,
    required this.finalResponse,
    required this.executionTime,
  });

  factory MemberPtLog.fromJson(Map<String, dynamic> json) {
    return MemberPtLog(
      ptScheduleId: (json['ptScheduleId'] as num).toInt(),
      timestamp: json['timestamp'] as String,
      finalResponse: json['finalResponse'] as String,
      executionTime: (json['executionTime'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ptScheduleId': ptScheduleId,
      'timestamp': timestamp,
      'finalResponse': finalResponse,
      'executionTime': executionTime,
    };
  }
} 