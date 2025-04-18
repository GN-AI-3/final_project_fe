class PtContract {
  final int id;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime startDate;
  final DateTime endDate;
  final String memo;
  final String status;
  final int totalCount;
  final int usedCount;
  final int remainingCount;
  final int memberId;
  final String memberName;
  final String gender;
  final String email;
  final String phone;
  final int trainerId;
  final String trainerName;
  final int createdBy;
  final int modifiedBy;

  PtContract({
    required this.id,
    required this.createdAt,
    required this.modifiedAt,
    required this.startDate,
    required this.endDate,
    required this.memo,
    required this.status,
    required this.totalCount,
    required this.usedCount,
    required this.remainingCount,
    required this.memberId,
    required this.memberName,
    required this.gender,
    required this.email,
    required this.phone,
    required this.trainerId,
    required this.trainerName,
    required this.createdBy,
    required this.modifiedBy,
  });

  factory PtContract.fromJson(Map<String, dynamic> json) {
    return PtContract(
      id: json['id'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as int? ?? 0) * 1000,
      ),
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['modifiedAt'] as int? ?? 0) * 1000,
      ),
      startDate: DateTime.fromMillisecondsSinceEpoch(
        (json['startDate'] as int? ?? 0) * 1000,
      ),
      endDate: DateTime.fromMillisecondsSinceEpoch(
        (json['endDate'] as int? ?? 0) * 1000,
      ),
      memo: json['memo'] as String? ?? '',
      status: json['status'] as String? ?? 'UNKNOWN',
      totalCount: json['totalCount'] as int? ?? 0,
      usedCount: json['usedCount'] as int? ?? 0,
      remainingCount: json['remainingCount'] as int? ?? 0,
      memberId: json['memberId'] as int? ?? 0,
      memberName: json['memberName'] as String? ?? '알 수 없음',
      gender: _parseGender(json['gender'] as String?),
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '연락처 없음',
      trainerId: json['trainerId'] as int? ?? 0,
      trainerName: json['trainerName'] as String? ?? '',
      createdBy: json['createdBy'] as int? ?? 0,
      modifiedBy: json['modifiedBy'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch ~/ 1000,
      'startDate': startDate.millisecondsSinceEpoch ~/ 1000,
      'endDate': endDate.millisecondsSinceEpoch ~/ 1000,
      'memo': memo,
      'status': status,
      'totalCount': totalCount,
      'usedCount': usedCount,
      'remainingCount': remainingCount,
      'memberId': memberId,
      'memberName': memberName,
      'gender': gender,
      'email': email,
      'phone': phone,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
    };
  }

  PtContract copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? modifiedAt,
    DateTime? startDate,
    DateTime? endDate,
    String? memo,
    String? status,
    int? totalCount,
    int? usedCount,
    int? remainingCount,
    int? memberId,
    String? memberName,
    String? gender,
    String? email,
    String? phone,
    int? trainerId,
    String? trainerName,
    int? createdBy,
    int? modifiedBy,
  }) {
    return PtContract(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      memo: memo ?? this.memo,
      status: status ?? this.status,
      totalCount: totalCount ?? this.totalCount,
      usedCount: usedCount ?? this.usedCount,
      remainingCount: remainingCount ?? this.remainingCount,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }

  @override
  String toString() {
    return 'PtContract(id: $id, memberName: $memberName, status: $status, totalCount: $totalCount, remainingCount: $remainingCount)';
  }

  static String _parseGender(String? gender) {
    switch (gender) {
      case 'M':
        return '남성';
      case 'F':
        return '여성';
      default:
        return '알 수 없음';
    }
  }
}
