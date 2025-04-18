import 'package:flutter/material.dart';

import '../../models/meeting.dart';
import '../../widgets/custom_toast.dart';
import '../services/schedule_service.dart';

class NoShowDialog extends StatefulWidget {
  final Meeting meeting;
  final ScheduleService scheduleService;
  final VoidCallback onNoShowProcessed;

  const NoShowDialog({
    super.key,
    required this.meeting,
    required this.scheduleService,
    required this.onNoShowProcessed,
  });

  @override
  State<NoShowDialog> createState() => _NoShowDialogState();
}

class _NoShowDialogState extends State<NoShowDialog> {
  final TextEditingController _reasonController = TextEditingController(
    text: '부재중',
  );
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _processNoShow() async {
    if (widget.meeting.scheduleId == null) {
      CustomToast.show(
        context: context,
        message: '일정 ID가 없습니다.',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.scheduleService.noShowSchedule(
        scheduleId: widget.meeting.scheduleId!,
        reason: _reasonController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onNoShowProcessed();
        CustomToast.show(
          context: context,
          message: '불참 처리가 완료되었습니다.',
          type: ToastType.success,
        );
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('불참 처리'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.meeting.eventName} 일정을 불참 처리하시겠습니까?'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: '불참 사유',
              hintText: '부재중',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _processNoShow,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('확인'),
        ),
      ],
    );
  }
}
