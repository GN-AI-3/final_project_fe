import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/pt_contract.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/custom_toast.dart';
import '../services/schedule_service.dart';


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
  String _selectedAmPm = '오전';
  int _selectedHour = 9;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedHour = TimeOfDay.now().hour;
    _selectedAmPm = _selectedHour < 12 ? '오전' : '오후';
    _selectedHour = _selectedHour % 12 == 0 ? 12 : _selectedHour % 12;
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
      CustomDialog.show(
        context: context,
        title: '앗!',
        content: Text('$message\n${error?.toString() ?? ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
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
        CustomToast.show(
          context: context,
          message: '일정이 성공적으로 추가되었습니다.',
          type: ToastType.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('일정 추가에 실패했습니다', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: '일정 추가',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContractDropdown(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            Transform.translate(
              offset: const Offset(0, -20),
              child: _buildTimeSelector(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _addSchedule,
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text('추가'),
        ),
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
}
