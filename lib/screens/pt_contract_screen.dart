import 'package:flutter/material.dart';
import '../widgets/custom_dialog.dart';

import '../models/pt_contract.dart';
import '../services/pt_contract_service.dart';

class PtContractScreen extends StatefulWidget {
  const PtContractScreen({Key? key}) : super(key: key);

  @override
  PtContractScreenState createState() => PtContractScreenState();
}

class PtContractScreenState extends State<PtContractScreen> {
  final PtContractService _ptContractService = PtContractService();
  List<PtContract> _contracts = [];
  String? _selectedStatus;
  bool _isLoading = false;

  // 색상 상수 정의
  static const Color primaryColor = Color(0xff2746F8);
  static const Color secondaryColor1 = Color(0xff28CAF7);
  static const Color secondaryColor2 = Color(0xff8F28F7);
  static const Color secondaryColor3 = Color(0xff7A8DF7);
  static const Color secondaryColor4 = Color(0xff2888F7);
  static const Color textColor = Color(0xff3B3C40);

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final contracts = await _ptContractService.getContractMembers(
        _selectedStatus,
      );
      
      if (!mounted) return;
      
      setState(() {
        _contracts = contracts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      _showErrorDialog('계약 목록을 불러오는데 실패했습니다: $e');
    }
  }

  void _showFilterMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1, 80, 0, 0),
      items: [
        const PopupMenuItem<String>(value: null, child: Text('상태: 전체')),
        const PopupMenuItem<String>(value: 'ACTIVE', child: Text('진행중')),
        const PopupMenuItem<String>(value: 'COMPLETED', child: Text('완료')),
        const PopupMenuItem<String>(value: 'CANCELLED', child: Text('취소')),
        const PopupMenuItem<String>(value: 'SUSPENDED', child: Text('일시중지')),
        const PopupMenuItem<String>(value: 'EXPIRED', child: Text('만료')),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedStatus = value;
        });
        _loadContracts();
      }
    });
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: '오류',
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f0f0),
      appBar: AppBar(
        title: const Text(
          'PT 계약 관리',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xfff0f0f0),
        foregroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
            tooltip: '필터',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _contracts.length,
                itemBuilder: (context, index) {
                  final contract = _contracts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      title: Text(
                        contract.memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            '연락처: ${contract.phone}',
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildInfoChip(
                                '총 PT: ${contract.contract.totalCount}회',
                                secondaryColor2,
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                '남은 PT: ${contract.contract.remainingCount}회',
                                secondaryColor4,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildStatusChip(contract.contract.status),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final (color, text) = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '상태: $text',
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(String status) {
    switch (status) {
      case 'ACTIVE':
        return (primaryColor, '진행중');
      case 'COMPLETED':
        return (secondaryColor4, '완료');
      case 'CANCELLED':
        return (Colors.red, '취소');
      case 'SUSPENDED':
        return (secondaryColor3, '일시중지');
      case 'EXPIRED':
        return (textColor, '만료');
      default:
        return (textColor, status);
    }
  }
}
