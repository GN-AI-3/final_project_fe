import 'package:flutter/foundation.dart';

class PtContract {
  static const String _defaultName = '';
  static const String _defaultPhone = '';
  static const String _defaultStatus = 'UNKNOWN';

  final int memberId;
  final String memberName;
  final String phone;
  final ContractInfo contract;

  PtContract({
    required this.memberId,
    required this.memberName,
    required this.phone,
    required this.contract,
  }) {
    _validateContract();
  }

  void _validateContract() {
    if (memberId <= 0) {
      throw ArgumentError('회원 ID는 0보다 커야 합니다.');
    }
    if (memberName.isEmpty) {
      throw ArgumentError('회원 이름은 비어있을 수 없습니다.');
    }
    if (contract.remainingCount < 0) {
      throw ArgumentError('남은 PT 횟수는 음수가 될 수 없습니다.');
    }
    if (contract.totalCount < contract.remainingCount) {
      throw ArgumentError('총 PT 횟수는 남은 PT 횟수보다 작을 수 없습니다.');
    }
  }

  factory PtContract.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('PtContract fromJson: $json');
    }

    return PtContract(
      memberId: json['memberId'] as int? ?? 0,
      memberName: json['memberName'] as String? ?? _defaultName,
      phone: json['phone'] as String? ?? _defaultPhone,
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
  }) {
    _validateContractInfo();
  }

  void _validateContractInfo() {
    if (contractId <= 0) {
      throw ArgumentError('계약 ID는 0보다 커야 합니다.');
    }
    if (totalCount <= 0) {
      throw ArgumentError('총 PT 횟수는 0보다 커야 합니다.');
    }
    if (remainingCount < 0) {
      throw ArgumentError('남은 PT 횟수는 음수가 될 수 없습니다.');
    }
    if (remainingCount > totalCount) {
      throw ArgumentError('남은 PT 횟수는 총 PT 횟수를 초과할 수 없습니다.');
    }
  }

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
