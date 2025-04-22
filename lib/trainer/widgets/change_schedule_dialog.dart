import 'package:flutter/material.dart';

import '../../models/meeting.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/custom_toast.dart';
import '../services/schedule_service.dart';


class ChangeScheduleDialog extends StatefulWidget {
  final ScheduleService scheduleService;
  final Meeting meeting;
  final VoidCallback onScheduleChanged;

  const ChangeScheduleDialog({
    super.key,
    required this.scheduleService,
    required this.meeting,
    required this.onScheduleChanged,
  });

  @override
  State<ChangeScheduleDialog> createState() => _ChangeScheduleDialogState();
}

class _ChangeScheduleDialogState extends State<ChangeScheduleDialog> {
  DateTime? _selectedDate;
  String _selectedAmPm = '오전';
  int _selectedHour = 9;
  final TextEditingController _reasonController = TextEditingController(
    text: '트레이너와 협의',
  );

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.meeting.from;
    _selectedHour = widget.meeting.from.hour;
    _selectedAmPm = _selectedHour < 12 ? '오전' : '오후';
    _selectedHour = _selectedHour % 12 == 0 ? 12 : _selectedHour % 12;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int _get24Hour() {
    if (_selectedAmPm == '오후' && _selectedHour != 12) {
      return _selectedHour + 12;
    } else if (_selectedAmPm == '오전' && _selectedHour == 12) {
      return 0;
    }
    return _selectedHour;
  }

  bool _isValid() {
    if (_selectedDate == null) {
      return false;
    }
    return true;
  }

  Future<void> _changeSchedule() async {
    if (!_isValid()) return;

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _get24Hour(),
    );

    final endDateTime = startDateTime.add(const Duration(hours: 1));

    try {
      await widget.scheduleService.changeSchedule(
        scheduleId: widget.meeting.scheduleId!,
        startTime: startDateTime,
        endTime: endDateTime,
        reason: _reasonController.text,
      );

      if (mounted) {
        CustomToast.show(
          context: context,
          message: '일정이 성공적으로 변경되었습니다.',
          type: ToastType.success,
        );
        widget.onScheduleChanged();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context: context,
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: '일정 변경',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDatePicker(),
            Transform.translate(
              offset: const Offset(0, -20),
              child: _buildTimeSelector(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: '변경 사유',
                hintText: '변경 사유를 입력하세요',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _isValid() ? _changeSchedule : null,
          child: const Text('변경'),
        ),
      ],
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
