import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/pt_contract.dart';
import '../../trainer/services/pt_contract_service.dart';
import '../../trainer/services/schedule_service.dart';
import '../../widgets/custom_dialog.dart';


class MemberAddScheduleDialog extends StatefulWidget {
  final ScheduleService scheduleService;
  final Function() onScheduleAdded;

  const MemberAddScheduleDialog({
    super.key,
    required this.scheduleService,
    required this.onScheduleAdded,
  });

  @override
  State<MemberAddScheduleDialog> createState() => _MemberAddScheduleDialogState();
}

class _MemberAddScheduleDialogState extends State<MemberAddScheduleDialog> {
  final _ptContractService = PtContractService();
  final _formKey = GlobalKey<FormState>();

  PtContract? _selectedContract;
  DateTime? _selectedDate;
  String _selectedAmPm = '오전';
  int _selectedHour = 9;
  List<PtContract> _contracts = [];

  @override
  void initState() {
    super.initState();
    _initializeDateTime();
    _loadContracts();
  }

  void _initializeDateTime() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = now;
      _selectedHour = now.hour;
      _selectedAmPm = _selectedHour < 12 ? '오전' : '오후';
      _selectedHour = _selectedHour % 12 == 0 ? 12 : _selectedHour % 12;
    });
  }

  Future<void> _loadContracts() async {
    try {
      final contracts = await _ptContractService.getContractMembers();
      if (mounted) {
        setState(() => _contracts = contracts);
      }
    } catch (e) {
      _showError('PT 계약 회원 목록을 불러오는데 실패했습니다', e);
    }
  }

  int _get24Hour() {
    if (_selectedAmPm == '오후' && _selectedHour != 12) {
      return _selectedHour + 12;
    } else if (_selectedAmPm == '오전' && _selectedHour == 12) {
      return 0;
    }
    return _selectedHour;
  }

  bool _validateForm() {
    if (_selectedContract == null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('알림'),
              content: const Text('PT 회원을 선택해주세요'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
      );
      return false;
    }
    return true;
  }

  void _showError(String message, dynamic error) {
    if (kDebugMode) {
      print('$message: $error');
    }
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => CustomDialog(
              title: '오류',
              content: Text('$message: $error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _addSchedule() async {
    if (!_validateForm()) return;

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _get24Hour(),
    );

    final endDateTime = startDateTime.add(const Duration(hours: 1));

    try {
      await widget.scheduleService.createSchedule(
        ptContractId: _selectedContract!.id,
        startTime: startDateTime,
        endTime: endDateTime,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showError('일정 추가에 실패했습니다', e);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialog(
            title: '일정 추가',
            content: const Text('일정이 성공적으로 추가되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onScheduleAdded();
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '새 일정',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildContractDropdown(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              Transform.translate(
                offset: const Offset(0, -20),
                child: _buildTimeSelector(),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractDropdown() {
    return Align(
      alignment: const Alignment(-0.725, 0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: DropdownButtonFormField<PtContract>(
          value: _selectedContract,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'PT 회원 선택',
            hintText: '회원을 선택하세요',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(maxWidth: 300),
          ),
          items:
              _contracts.map((contract) {
                return DropdownMenuItem<PtContract>(
                  value: contract,
                  child: Text(
                    '${contract.memberName} - 남은 PT: ${contract.remainingCount}회',
                  ),
                );
              }).toList(),
          onChanged: (value) => setState(() => _selectedContract = value),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return CalendarDatePicker(
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      onDateChanged: (date) => setState(() => _selectedDate = date),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('시작 시간: ', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedAmPm,
            items:
                ['오전', '오후'].map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedAmPm = value);
              }
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _selectedHour,
            items:
                List.generate(12, (index) => index + 1).map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value', style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedHour = value);
              }
            },
          ),
          const SizedBox(width: 8),
          const Text('시', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addSchedule,
          child: const Text('추가'),
        ),
      ],
    );
  }
} 