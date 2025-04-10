import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/schedule_service.dart';
import '../services/pt_contract_service.dart';
import '../models/pt_contract.dart';

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
  PtContract? _selectedContract;
  DateTime? _selectedDate;
  String _selectedAmPm = '오전';
  int _selectedHour = 9;  // 기본값 9시
  List<PtContract> _contracts = [];
  final PtContractService _ptContractService = PtContractService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedHour = DateTime.now().hour;
    _selectedAmPm = _selectedHour < 12 ? '오전' : '오후';
    _selectedHour = _selectedHour % 12 == 0 ? 12 : _selectedHour % 12;
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    try {
      final contracts = await _ptContractService.getContractMembers('ACTIVE');
      setState(() {
        _contracts = contracts;
      });
    } catch (e) {
      if (kDebugMode) {
        print('PT 계약 회원 목록 로드 중 오류 발생: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PT 계약 회원 목록을 불러오는데 실패했습니다: $e')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '새 일정 추가',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Align(
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
                  items: _contracts.map((contract) {
                    return DropdownMenuItem<PtContract>(
                      value: contract,
                      child: Text('${contract.memberName} (${contract.phone}) - 남은 PT: ${contract.contract.remainingCount}회'),
                    );
                  }).toList(),
                  onChanged: (PtContract? value) {
                    setState(() {
                      _selectedContract = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            CalendarDatePicker(
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onDateChanged: (DateTime date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton<String>(
                  value: _selectedAmPm,
                  items: ['오전', '오후'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedAmPm = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedHour,
                  items: List.generate(12, (index) => index + 1).map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value시'),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedHour = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_selectedContract == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PT 회원을 선택해주세요')),
                      );
                      return;
                    }

                    final selectedDateTime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _get24Hour(),
                    );

                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    try {
                      final endDateTime = selectedDateTime.add(const Duration(hours: 1));
                      final schedule = await widget.scheduleService.createSchedule(
                        memberId: _selectedContract!.memberId,
                        startTime: selectedDateTime,
                        endTime: endDateTime,
                      );

                      if (kDebugMode) {
                        print('일정 생성 성공: ${schedule.id}');
                      }

                      widget.onScheduleAdded();

                      if (mounted) {
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('일정이 추가되었습니다')),
                        );
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print('일정 생성 실패: $e');
                      }
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('일정 추가에 실패했습니다: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('추가'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 