
class PtContract {
  final int memberId;
  final String memberName;
  final String phone;
  final ContractInfo contract;

  PtContract({
    required this.memberId,
    required this.memberName,
    required this.phone,
    required this.contract,
  });

  factory PtContract.fromJson(Map<String, dynamic> json) {
    final memberName = json['memberName'] as String?;
    final phone = json['phone'] as String?;

    return PtContract(
      memberId: json['memberId'] as int? ?? 0,
      memberName: memberName ?? '알 수 없음',
      phone: phone ?? '연락처 없음',
      contract: ContractInfo.fromJson(json['contract'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'phone': phone,
      'contract': contract.toJson(),
    };
  }

  PtContract copyWith({
    int? memberId,
    String? memberName,
    String? phone,
    ContractInfo? contract,
  }) {
    return PtContract(
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      phone: phone ?? this.phone,
      contract: contract ?? this.contract,
    );
  }

  @override
  String toString() {
    return 'PtContract(memberId: $memberId, memberName: $memberName, phone: $phone, contract: $contract)';
  }
}

class ContractInfo {
  static const int _defaultCount = 0;
  static const String _defaultStatus = 'UNKNOWN';

  final int contractId;
  final int totalCount;
  final int remainingCount;
  final String status;

  ContractInfo({
    required this.contractId,
    required this.totalCount,
    required this.remainingCount,
    required this.status,
  });

  factory ContractInfo.fromJson(Map<String, dynamic> json) {
    return ContractInfo(
      contractId: json['contractId'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? _defaultCount,
      remainingCount: json['remainingCount'] as int? ?? _defaultCount,
      status: json['status'] as String? ?? _defaultStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contractId': contractId,
      'totalCount': totalCount,
      'remainingCount': remainingCount,
      'status': status,
    };
  }

  ContractInfo copyWith({
    int? contractId,
    int? totalCount,
    int? remainingCount,
    String? status,
  }) {
    return ContractInfo(
      contractId: contractId ?? this.contractId,
      totalCount: totalCount ?? this.totalCount,
      remainingCount: remainingCount ?? this.remainingCount,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'ContractInfo(contractId: $contractId, totalCount: $totalCount, remainingCount: $remainingCount, status: $status)';
  }
}
