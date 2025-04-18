class PtLog {
  final int ptScheduleId;
  final String timestamp;
  final String finalResponse;
  final int executionTime;

  PtLog({
    required this.ptScheduleId,
    required this.timestamp,
    required this.finalResponse,
    required this.executionTime,
  });

  factory PtLog.fromJson(Map<String, dynamic> json) {
    return PtLog(
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