import 'package:flutter/material.dart';

import '../../models/meeting.dart';
import '../../trainer/services/schedule_service.dart';
import '../../widgets/custom_toast.dart';


class MemberChangeScheduleDialog extends StatefulWidget {
  final ScheduleService scheduleService;
  final Meeting meeting;
  final VoidCallback onScheduleChanged;

  const MemberChangeScheduleDialog({
    super.key,
    required this.scheduleService,
    required this.meeting,
    required this.onScheduleChanged,
  });

  @override
  State<MemberChangeScheduleDialog> createState() =>
      _MemberChangeScheduleDialogState();
}

class _MemberChangeScheduleDialogState extends State<MemberChangeScheduleDialog> {
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _selectedStartTime;
  DateTime? _selectedEndTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStartTime = widget.meeting.from;
    _selectedEndTime = widget.meeting.to;
    _reasonController.text = '회원 사정';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedStartTime!),
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = DateTime(
          _selectedStartTime!.year,
          _selectedStartTime!.month,
          _selectedStartTime!.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedEndTime!),
    );
    if (picked != null) {
      setState(() {
        _selectedEndTime = DateTime(
          _selectedEndTime!.year,
          _selectedEndTime!.month,
          _selectedEndTime!.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _changeSchedule() async {
    if (_selectedStartTime == null || _selectedEndTime == null) {
      CustomToast.show(
        context: context,
        message: '시작 시간과 종료 시간을 모두 선택해주세요.',
        type: ToastType.error,
      );
      return;
    }

    if (_reasonController.text.isEmpty) {
      CustomToast.show(
        context: context,
        message: '변경 사유를 입력해주세요.',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.scheduleService.changeSchedule(
        scheduleId: widget.meeting.scheduleId!,
        startTime: _selectedStartTime!,
        endTime: _selectedEndTime!,
        reason: _reasonController.text,
      );

      if (mounted) {
        CustomToast.show(
          context: context,
          message: '일정이 변경되었습니다.',
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '일정 변경',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('기존 일정: ${widget.meeting.eventName}'),
            const SizedBox(height: 8),
            Text(
              '시작: ${_formatDateTime(widget.meeting.from)}\n'
              '종료: ${_formatDateTime(widget.meeting.to)}',
            ),
            const SizedBox(height: 24),
            const Text(
              '새로운 일정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectStartTime,
                    child: Text(
                      _selectedStartTime != null
                          ? _formatTime(_selectedStartTime!)
                          : '시작 시간 선택',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectEndTime,
                    child: Text(
                      _selectedEndTime != null
                          ? _formatTime(_selectedEndTime!)
                          : '종료 시간 선택',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: '변경 사유',
                hintText: '변경 사유를 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changeSchedule,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('일정 변경'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 '
        '${dateTime.hour}시 ${dateTime.minute}분';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}시 ${dateTime.minute}분';
  }
} 