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
    print('PtContract fromJson: $json'); // 디버깅용 로그

    return PtContract(
      memberId: json['memberId'] as int? ?? 0,
      memberName: json['memberName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      contract: ContractInfo.fromJson(json['contract'] as Map<String, dynamic>),
    );
  }
}

class ContractInfo {
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
      totalCount: json['totalCount'] as int? ?? 0,
      remainingCount: json['remainingCount'] as int? ?? 0,
      status: json['status'] as String? ?? 'UNKNOWN',
    );
  }
} 