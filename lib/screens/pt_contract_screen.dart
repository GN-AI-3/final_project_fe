import 'package:flutter/material.dart';
import '../models/pt_contract.dart';
import '../services/pt_contract_service.dart';

class PtContractScreen extends StatefulWidget {
  const PtContractScreen({Key? key}) : super(key: key);

  @override
  _PtContractScreenState createState() => _PtContractScreenState();
}

class _PtContractScreenState extends State<PtContractScreen> {
  final PtContractService _ptContractService = PtContractService();
  List<PtContract> _contracts = [];
  String? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contracts = await _ptContractService.getContractMembers(_selectedStatus);
      setState(() {
        _contracts = contracts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계약 목록을 불러오는데 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PT 계약 관리'),
        actions: [
          DropdownButton<String?>(
            value: _selectedStatus,
            hint: const Text('상태 필터'),
            items: const [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('전체'),
              ),
              DropdownMenuItem<String>(
                value: 'ACTIVE',
                child: Text('진행중'),
              ),
              DropdownMenuItem<String>(
                value: 'COMPLETED',
                child: Text('완료'),
              ),
              DropdownMenuItem<String>(
                value: 'CANCELLED',
                child: Text('취소'),
              ),
              DropdownMenuItem<String>(
                value: 'SUSPENDED',
                child: Text('일시중지'),
              ),
              DropdownMenuItem<String>(
                value: 'EXPIRED',
                child: Text('만료'),
              ),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _selectedStatus = newValue;
              });
              _loadContracts();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _contracts.length,
              itemBuilder: (context, index) {
                final contract = _contracts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(contract.memberName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('연락처: ${contract.phone}'),
                        Text('총 PT: ${contract.contract.totalCount}회'),
                        Text('남은 PT: ${contract.contract.remainingCount}회'),
                        Text(
                          '상태: ${_getStatusText(contract.contract.status)}',
                          style: TextStyle(
                            color: _getStatusColor(contract.contract.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ACTIVE':
        return '진행중';
      case 'COMPLETED':
        return '완료';
      case 'CANCELLED':
        return '취소';
      case 'SUSPENDED':
        return '일시중지';
      case 'EXPIRED':
        return '만료';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      case 'SUSPENDED':
        return Colors.orange;
      case 'EXPIRED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
} 