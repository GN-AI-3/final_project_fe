import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/pt_contract.dart';
import '../services/pt_contract_service.dart';
import '../services/schedule_service.dart';

class AddReservationDialog extends StatefulWidget {
  final ScheduleService scheduleService;
  final Function() onScheduleAdded;

  const AddReservationDialog({
    super.key,
    required this.scheduleService,
    required this.onScheduleAdded,
  });

  @override
  State<AddReservationDialog> createState() => _AddReservationDialogState();
}

class _AddReservationDialogState extends State<AddReservationDialog> {
  final _ptContractService = PtContractService();
  final _formKey = GlobalKey<FormState>();

  PtContract? _selectedContract;
  DateTime? _selectedDate;
  String _selectedAmPm = '오전';
  int _selectedHour = 9;
  List<PtContract> _contracts = [];
  bool _isLoading = false;

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
      final contracts = await _ptContractService.getContractMembers('ACTIVE');
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

  Future<void> _createSchedule() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final selectedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _get24Hour(),
      );
      final endDateTime = selectedDateTime.add(const Duration(hours: 1));

      final schedule = await widget.scheduleService.createSchedule(
        ptContractId: _selectedContract!.contract.contractId,
        startTime: selectedDateTime,
        endTime: endDateTime,
      );

      if (kDebugMode) {
        print('일정 생성 성공: ${schedule.id}');
      }

      widget.onScheduleAdded();
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('일정이 추가되었습니다')),
      );
    } catch (e) {
      _showError('일정 추가에 실패했습니다', e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateForm() {
    if (_selectedContract == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PT 회원을 선택해주세요')));
      return false;
    }
    return true;
  }

  void _showError(String message, dynamic error) {
    if (kDebugMode) {
      print('$message: $error');
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$message: $error')));
    }
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
                '새 일정 추가',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildContractDropdown(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTimeSelector(),
              const SizedBox(height: 16),
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
            hintText: 'PT 계약 회원을 선택하세요',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(maxWidth: 300),
          ),
          items:
              _contracts.map((contract) {
                return DropdownMenuItem<PtContract>(
                  value: contract,
                  child: Text(
                    '${contract.memberName} (${contract.phone}) - 남은 PT: ${contract.contract.remainingCount}회',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownButton<String>(
          value: _selectedAmPm,
          items:
              ['오전', '오후'].map((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
                  child: Text('$value시'),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedHour = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _createSchedule,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('추가'),
        ),
      ],
    );
  }
}
