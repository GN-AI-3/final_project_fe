import 'package:flutter/material.dart';

import '../../models/meeting.dart';
import '../../trainer/services/schedule_service.dart';
import '../../widgets/custom_toast.dart';


class MemberNoShowDialog extends StatefulWidget {
  final ScheduleService scheduleService;
  final Meeting meeting;
  final VoidCallback onNoShowProcessed;

  const MemberNoShowDialog({
    super.key,
    required this.scheduleService,
    required this.meeting,
    required this.onNoShowProcessed,
  });

  @override
  State<MemberNoShowDialog> createState() => _MemberNoShowDialogState();
}

class _MemberNoShowDialogState extends State<MemberNoShowDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reasonController.text = '회원 사정';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _processNoShow() async {
    if (_reasonController.text.isEmpty) {
      CustomToast.show(
        context: context,
        message: '불참 사유를 입력해주세요.',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.scheduleService.noShowSchedule(
        scheduleId: widget.meeting.scheduleId!,
        reason: _reasonController.text,
      );

      if (mounted) {
        CustomToast.show(
          context: context,
          message: '불참 처리가 완료되었습니다.',
          type: ToastType.success,
        );
        widget.onNoShowProcessed();
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
              '불참 처리',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('일정: ${widget.meeting.eventName}'),
            const SizedBox(height: 8),
            Text(
              '시작: ${_formatDateTime(widget.meeting.from)}\n'
              '종료: ${_formatDateTime(widget.meeting.to)}',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: '불참 사유',
                hintText: '불참 사유를 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processNoShow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('불참 처리'),
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
} 