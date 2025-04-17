import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/pt_contract.dart';
import '../services/schedule_service.dart';
import 'custom_dialog.dart';

class AddScheduleDialog extends StatefulWidget {
  final List<PtContract> contracts;
  final ScheduleService scheduleService;

  const AddScheduleDialog({
    super.key,
    required this.contracts,
    required this.scheduleService,
  });

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  PtContract? _selectedContract;
  DateTime? _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isAm = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  int _get24Hour() {
    int hour = _selectedTime.hour;
    if (!_isAm && hour != 12) {
      hour += 12;
    } else if (_isAm && hour == 12) {
      hour = 0;
    }
    return hour;
  }

  bool _validateForm() {
    if (_selectedContract == null) {
      _showError('회원을 선택해주세요', null);
      return false;
    }
    if (_selectedDate == null) {
      _showError('날짜를 선택해주세요', null);
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
          (context) => AlertDialog(
            title: const Text('일정 추가 완료'),
            content: const Text('일정이 성공적으로 추가되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('일정 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContractDropdown(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildTimePicker(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(onPressed: _addSchedule, child: const Text('추가')),
      ],
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
              widget.contracts.map((contract) {
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
    return Row(
      children: [
        const Text('날짜: '),
        TextButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          child: Text(
            _selectedDate != null
                ? '${_selectedDate!.year}년 ${_selectedDate!.month}월 ${_selectedDate!.day}일'
                : '날짜 선택',
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Row(
      children: [
        const Text('시간: '),
        TextButton(
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
            );
            if (time != null) {
              setState(() => _selectedTime = time);
            }
          },
          child: Text(
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: _isAm,
              onChanged: (value) => setState(() => _isAm = value!),
            ),
            const Text('AM'),
            Radio<bool>(
              value: false,
              groupValue: _isAm,
              onChanged: (value) => setState(() => _isAm = value!),
            ),
            const Text('PM'),
          ],
        ),
      ],
    );
  }
}
