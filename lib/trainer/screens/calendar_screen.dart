import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../models/meeting.dart';
import '../../models/pt_contract.dart';
import '../../models/schedule.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/common_bottom_navigation_bar.dart';
import '../screens/pt_log_screen.dart';
import '../screens/training_report_screen.dart';
import '../screens/pt_contract_screen.dart';
import '../screens/trainer_chat_screen.dart';
import '../../screens/home_screen.dart';
import '../services/pt_contract_service.dart';
import '../services/pt_logs_service.dart';
import '../services/schedule_service.dart';
import '../../services/auth_service.dart';

class CalendarConstants {
  static const Map<String, String> statusDescriptions = {
    'scheduled': '[예정된 일정]',
    // 필터용, 표시 안함
    'changed': '[변경된 일정]',
    'completed': '[완료된 일정]',
    'cancelled': '[취소된 일정]',
    'no_show': '[불참]',
  };

  static const Map<CalendarView, IconData> viewIcons = {
    CalendarView.day: Icons.view_day,
    CalendarView.week: Icons.view_week,
    CalendarView.month: Icons.calendar_month,
    CalendarView.schedule: Icons.schedule,
  };

  static const Map<CalendarView, CalendarView> nextView = {
    CalendarView.day: CalendarView.week,
    CalendarView.week: CalendarView.month,
    CalendarView.month: CalendarView.schedule,
    CalendarView.schedule: CalendarView.day,
  };
}

class CalendarState {
  final CalendarController controller = CalendarController();
  CalendarView currentView = CalendarView.month;
  List<Meeting> meetings = [];
  List<Meeting> filteredMeetings = [];
  String? selectedStatus;
  bool isLoading = false;
  DateTime? lastStartDate;
  DateTime? lastEndDate;
  final Map<int, Color> memberColors = {};

  Color getMemberColor(int memberId) {
    if (!memberColors.containsKey(memberId)) {
      final hue = (memberId * 137.508) % 360;
      memberColors[memberId] = HSLColor.fromAHSL(0.9, hue, 0.85, 0.4).toColor();
    }
    return memberColors[memberId]!;
  }

  void updateView(CalendarView newView) {
    currentView = newView;
    controller.view = newView;
  }

  void updateFilteredMeetings(List<Meeting> meetings) {
    filteredMeetings = meetings;
  }

  void updateSelectedStatus(String? status) {
    selectedStatus = status;
  }

  void updateLoading(bool loading) {
    isLoading = loading;
  }

  void updateLastDates(DateTime? start, DateTime? end) {
    lastStartDate = start;
    lastEndDate = end;
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ScheduleService _scheduleService = TrainerScheduleService();
  final PtContractService _ptContractService = PtContractService();
  final PtLogsService _ptLogsService = PtLogsService();
  List<PtContract> _ptContracts = [];
  final CalendarState _state = CalendarState();

  // 일정 추가 관련 상태 변수
  PtContract? _selectedContract;
  DateTime? _selectedDate;
  String _selectedAmPm = '오전';
  int _selectedHour = 9;

  @override
  void initState() {
    super.initState();
    _loadPtContracts();
    _selectedDate = DateTime.now();
    _selectedHour = TimeOfDay.now().hour;
    _selectedAmPm = _selectedHour < 12 ? '오전' : '오후';
    _selectedHour = _selectedHour % 12 == 0 ? 12 : _selectedHour % 12;
  }

  Future<void> _loadMeetings({DateTime? startDate, DateTime? endDate}) async {
    if (_state.isLoading) return;
    if (!mounted) return;

    _state.updateLoading(true);

    try {
      if (kDebugMode) {
        print(
          'Loading schedules from: ${startDate?.toIso8601String()} to ${endDate?.toIso8601String()}',
        );
      }

      List<Schedule> schedules = [];
      try {
        schedules = await _scheduleService.getSchedules(
          startTime: startDate,
          endTime: endDate,
        );

        if (kDebugMode) {
          print('Loaded schedules: ${schedules.length}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading schedules: $e');
        }
        schedules = [];
      }

      if (!mounted) return;

      final meetings =
          schedules.map<Meeting>((Schedule schedule) {
            return _createMeeting(schedule);
          }).toList();

      if (!mounted) return;

      _state.meetings = meetings;

      // 초기 필터링: scheduled와 completed 상태의 일정만 표시
      _state.updateFilteredMeetings(
        meetings.where((meeting) {
          final status = meeting.description?.split('\n')[0];
          // scheduled 상태는 description이 null이거나 '남은 PT: X회' 형식
          // completed 상태는 description이 '[완료된 일정]' 형식
          return status == null ||
              !status.contains('[') || // scheduled 상태
              status == CalendarConstants.statusDescriptions['completed'];
        }).toList(),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      _showError('앗!', e);
    } finally {
      if (mounted) {
        _state.updateLoading(false);
      }
    }
  }

  Future<void> _loadPtContracts() async {
    try {
      if (kDebugMode) {
        print('Loading PT contracts...');
      }

      final contracts = await _ptContractService.getContractMembers();

      if (kDebugMode) {
        print('Loaded ${contracts.length} PT contracts');
      }

      if (mounted) {
        setState(() => _ptContracts = contracts);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading PT contracts: $e');
      }

      if (mounted) {
        CustomToast.show(
          context: context,
          message: 'PT 계약 회원 목록을 불러오는데 실패했습니다: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Meeting _createMeeting(Schedule schedule) {
    final eventName =
        [
              'changed',
              'cancelled',
              'no_show',
            ].contains(schedule.status.toLowerCase())
            ? '${_getStatusDescription(schedule.status)} ${schedule.memberName} 회원님 - ${schedule.reason}'
            : schedule.status.toLowerCase() == 'scheduled'
            ? '${schedule.memberName} 회원님 (${schedule.currentPtCount}회차)'
            : '${_getStatusDescription(schedule.status)} ${schedule.memberName} 회원님 (${schedule.currentPtCount}회차)';

    return Meeting(
      eventName,
      schedule.startTime,
      schedule.endTime,
      _state.getMemberColor(schedule.memberId),
      false,
      id: schedule.id,
      scheduleId: schedule.id,
      ptContractId: schedule.ptContractId,
      description:
          schedule.status.toLowerCase() == 'scheduled'
              ? '남은 PT: ${schedule.remainingPtCount}회'
              : '${_getStatusDescription(schedule.status)}\n남은 PT: ${schedule.remainingPtCount}회',
    );
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

  Future<void> _showAddScheduleDialog() async {
    await CustomDialog.show(
      context: context,
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
          child: const Text('취소', style: TextStyle(color: Colors.black87)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PT 회원 선택', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          StatefulBuilder(
            builder: (context, setState) => DropdownButtonFormField<PtContract>(
              value: _selectedContract,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: _ptContracts
                  .where((contract) => contract.status.toLowerCase() == 'active')
                  .map((contract) {
                    return DropdownMenuItem<PtContract>(
                      value: contract,
                      child: Text(
                        '${contract.memberName} - 남은 PT: ${contract.remainingCount}회',
                      ),
                    );
                  })
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedContract = value);
                this.setState(() {});
              },
            ),
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('시작 시간', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatefulBuilder(
                builder: (context, setState) => DropdownButton<String>(
                  value: _selectedAmPm,
                  underline: Container(),
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 30),
                  items: ['오전', '오후'].map((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedAmPm = value);
                      this.setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              StatefulBuilder(
                builder: (context, setState) => DropdownButton<int>(
                  value: _selectedHour,
                  underline: Container(),
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 30),
                  items: List.generate(12, (index) => index + 1).map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedHour = value);
                      this.setState(() {});
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('시', style: TextStyle(fontSize: 20, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
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
      await _scheduleService.createSchedule(
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
        _loadMeetings();
      }
    } catch (e) {
      _showError('일정 추가에 실패했습니다', e);
    }
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

  int _get24Hour() {
    if (_selectedAmPm == '오후' && _selectedHour != 12) {
      return _selectedHour + 12;
    } else if (_selectedAmPm == '오전' && _selectedHour == 12) {
      return 0;
    }
    return _selectedHour;
  }

  void _showMeetingDetails(Meeting meeting) {
    CustomDialog.show(
      context: context,
      title: meeting.eventName,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // 데모 회원인 경우에만 트레이닝 리포트 화면으로 이동
              if (meeting.eventName.contains('데모')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => TrainingReportScreen(
                      ptContractId: meeting.ptContractId!,
                    ),
                  ),
                );
              } else {
                // 데모 회원이 아닌 경우 메시지 표시
                CustomToast.show(
                  context: context,
                  message: '체험 화면에선 데모 회원님의 트레이닝 리포트만\n보실 수 있습니다',
                  type: ToastType.info,
                );
              }
            },
            icon: const Icon(Icons.assessment),
            label: const Text('트레이닝 리포트'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
          const SizedBox(height: 8),
          if (meeting.description?.contains('[완료된 일정]') ?? false) ...[
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final exercises = await _ptLogsService.getPtLogExercises(
                    meeting.scheduleId!,
                  );
                  if (!mounted) return;

                  Navigator.pop(context);
                  _showPtLogDetails(exercises, meeting);
                } catch (e) {
                  if (!mounted) return;
                  CustomToast.show(
                    context: context,
                    message: '해당 일정의 PT 일지가 없습니다.',
                    type: ToastType.info,
                  );
                }
              },
              icon: const Icon(Icons.history),
              label: const Text('PT 일지 조회'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PtLogScreen(
                      scheduleId: meeting.scheduleId!,
                      meeting: meeting,
                      title:
                      meeting.eventName.length >= 8
                          ? '${meeting.eventName.substring(9)} 회원님 PT 일지 작성'
                          : '${meeting.eventName} 회원님 PT 일지 작성',
                    ),
                  ),
                ).then((_) {
                  if (_state.lastStartDate != null &&
                      _state.lastEndDate != null) {
                    _loadMeetings(
                      startDate: _state.lastStartDate,
                      endDate: _state.lastEndDate,
                    );
                  }
                });
              },
              icon: const Icon(Icons.edit_note),
              label: const Text('PT 일지 작성'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 8),
            if (DateTime.now().difference(meeting.to).inHours <= 24) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showNoShowDialog(meeting);
                },
                icon: const Icon(Icons.person_off),
                label: const Text('불참 처리'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ],
          ] else if (!(meeting.description?.contains('[취소된 일정]') ?? false) &&
              !(meeting.description?.contains('[변경된 일정]') ?? false) &&
              !(meeting.description?.contains('[완료된 일정]') ?? false)) ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showChangeScheduleDialog(meeting);
              },
              icon: const Icon(Icons.edit_calendar),
              label: const Text('일정 변경'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showCancelDialog(meeting);
              },
              icon: const Icon(Icons.cancel),
              label: const Text('일정 취소'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기', style: TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }

  void _showPtLogDetails(List<PtLogExercise> exercises, Meeting meeting) {
    CustomDialog.show(
      context: context,
      title: 'PT 기록 - ${meeting.eventName.substring(9)}',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              exercises
                  .map(
                    (exercise) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.exerciseName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildExerciseDetail(
                                  '무게',
                                  '${exercise.weight}kg',
                                ),
                                _buildExerciseDetail(
                                  '횟수',
                                  exercise.reps.toString(),
                                ),
                                _buildExerciseDetail(
                                  '세트',
                                  exercise.sets.toString(),
                                ),
                                _buildExerciseDetail(
                                  '휴식',
                                  '${exercise.restTime}초',
                                ),
                              ],
                            ),
                            if (exercise.feedback?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              const Text(
                                '피드백:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(exercise.feedback ?? ''),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기', style: TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }

  Widget _buildExerciseDetail(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Future<void> _showChangeScheduleDialog(Meeting meeting) async {
    await CustomDialog.show(
      context: context,
      title: '일정 변경',
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
          child: const Text('취소', style: TextStyle(color: Colors.black87)),
        ),
        TextButton(
          onPressed: () => _changeSchedule(meeting),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: const Text('변경'),
        ),
      ],
    );
  }

  Future<void> _changeSchedule(Meeting meeting) async {
    if (!_validateForm()) return;

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _get24Hour(),
    );

    final endDateTime = startDateTime.add(const Duration(hours: 1));

    try {
      await _scheduleService.changeSchedule(
        scheduleId: meeting.scheduleId!,
        startTime: startDateTime,
        endTime: endDateTime,
        reason: '트레이너와 협의',
      );

      if (mounted) {
        CustomToast.show(
          context: context,
          message: '일정이 성공적으로 변경되었습니다.',
          type: ToastType.success,
        );
        Navigator.of(context).pop();
        _loadMeetings();
      }
    } catch (e) {
      _showError('일정 변경에 실패했습니다', e);
    }
  }

  void _showCancelDialog(Meeting meeting) {
    final TextEditingController reasonController = TextEditingController(
      text: '트레이너와 협의',
    );

    if (kDebugMode) {
      print('일정 취소 요청 - meeting: $meeting');
      print('일정 ID: ${meeting.scheduleId}');
      print('일정 이름: ${meeting.eventName}');
    }

    CustomDialog.show(
      context: context,
      title: '일정 취소',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${meeting.eventName} 일정을 취소하시겠습니까?'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: '취소 사유',
              hintText: '취소 사유를 입력하세요',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: Colors.black87)),
        ),
        TextButton(
          onPressed: () async {
            try {
              if (meeting.scheduleId == null) {
                throw Exception('오류');
              }
              await _scheduleService.cancelSchedule(
                scheduleId: meeting.scheduleId!,
                reason: reasonController.text,
              );
              if (mounted) {
                Navigator.pop(context);
                _loadMeetings(
                  startDate: _state.lastStartDate,
                  endDate: _state.lastEndDate,
                );
              }
            } catch (e) {
              if (mounted) {
                Navigator.pop(context);
                CustomToast.show(
                  context: context,
                  message: e.toString(),
                  type: ToastType.error,
                );
              }
            }
          },
          child: const Text('확인'),
        ),
      ],
    );
  }

  Future<void> _showNoShowDialog(Meeting meeting) async {
    final TextEditingController reasonController = TextEditingController(
      text: '부재중',
    );

    await CustomDialog.show(
      context: context,
      title: '불참 처리',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${meeting.eventName.substring(9)} 일정을 불참 처리하시겠습니까?'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: '불참 사유',
              hintText: '부재중',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소', style: TextStyle(color: Colors.black87)),
        ),
        TextButton(
          onPressed: () => _processNoShow(meeting, reasonController.text),
          child: const Text('확인'),
        ),
      ],
    );
  }

  Future<void> _processNoShow(Meeting meeting, String reason) async {
    if (meeting.scheduleId == null) {
      CustomToast.show(
        context: context,
        message: '일정 ID가 없습니다.',
        type: ToastType.error,
      );
      return;
    }

    try {
      await _scheduleService.markNoShow(
        scheduleId: meeting.scheduleId!,
        reason: reason,
      );

      if (mounted) {
        Navigator.pop(context);
        _loadMeetings();
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
    }
  }

  void _changeView() {
    setState(() {
      _state.updateView(
        CalendarConstants.nextView[_state.currentView] ?? CalendarView.month,
      );
    });
  }

  void _filterMeetings() {
    setState(() {
      if (_state.selectedStatus == null) {
        _state.updateFilteredMeetings(_state.meetings);
      } else {
        final targetDescription =
            CalendarConstants.statusDescriptions[_state.selectedStatus!
                .toLowerCase()];
        _state.updateFilteredMeetings(
          _state.meetings.where((meeting) {
            final status = meeting.description?.split('\n')[0];
            if (_state.selectedStatus!.toLowerCase() == 'scheduled') {
              return status == null || !status.contains('[');
            }
            return status == targetDescription;
          }).toList(),
        );
      }
    });
  }

  String _getStatusDescription(String status) {
    return CalendarConstants.statusDescriptions[status.toLowerCase()] ??
        '[${status.toUpperCase()}]';
  }

  void _showFilterMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1, 80, 0, 0),
      items: [
        const PopupMenuItem<String>(value: 'RESET', child: Text('전체')),
        const PopupMenuItem<String>(value: 'scheduled', child: Text('예정')),
        const PopupMenuItem<String>(value: 'changed', child: Text('변경')),
        const PopupMenuItem<String>(value: 'completed', child: Text('완료')),
        const PopupMenuItem<String>(value: 'cancelled', child: Text('취소')),
        const PopupMenuItem<String>(value: 'no_show', child: Text('불참')),
      ],
    ).then((value) {
      if (value == null) return;

      setState(() {
        _state.updateSelectedStatus(value == 'RESET' ? null : value);
        _filterMeetings();
      });
    });
  }

  void _handleViewChanged(ViewChangedDetails details) {
    if (_state.isLoading) return;

    final visibleDates = details.visibleDates;
    if (visibleDates.isEmpty) return;

    final startDate = visibleDates.first;
    final endDate = DateTime(
      visibleDates.last.year,
      visibleDates.last.month,
      visibleDates.last.day,
      23,
      59,
      59,
    );

    _state.updateLastDates(startDate, endDate);
    _loadMeetings(startDate: startDate, endDate: endDate);
  }

  Future<void> _showRoleSwitchDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('역할 전환'),
        content: const Text('멤버 화면으로 전환하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (result == true) {
      await AuthService.login('user1@test.com', '1234', 'member');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
          ),
          IconButton(
            icon: Icon(
              CalendarConstants.viewIcons[_state.currentView] ??
                  Icons.calendar_month,
            ),
            onPressed: _changeView,
          ),
        ],
        forceMaterialTransparency: true,
        backgroundColor: const Color(0xfff0f0f0),
      ),
      body: Stack(
        children: [
          _state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                color: const Color(0xfff0f0f0),
                child: SfCalendar(
                  controller: _state.controller,
                  view: _state.currentView,
                  headerHeight: 50,
                  headerStyle: const CalendarHeaderStyle(
                    textAlign: TextAlign.start,
                    backgroundColor: Color(0xfff0f0f0),
                    textStyle: TextStyle(fontSize: 22, color: Colors.black87),
                  ),
                  cellBorderColor: const Color(0xffd8d8d8),
                  headerDateFormat: ' yyyy년 M월',
                  timeZone: 'Korea Standard Time',
                  scheduleViewSettings: const ScheduleViewSettings(
                    hideEmptyScheduleWeek: true,
                    appointmentItemHeight: 70,
                    appointmentTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                    weekHeaderSettings: WeekHeaderSettings(
                      startDateFormat: 'M월 d일 ',
                      endDateFormat: 'd일',
                      textAlign: TextAlign.start,
                    ),
                    monthHeaderSettings: MonthHeaderSettings(
                      monthFormat: 'yyyy년 M월',
                      height: 70,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  monthViewSettings: const MonthViewSettings(
                    showAgenda: true,
                    agendaViewHeight: 350,
                    appointmentDisplayCount: 6,
                  ),
                  appointmentBuilder: (
                    BuildContext context,
                    CalendarAppointmentDetails calendarAppointmentDetails,
                  ) {
                    try {
                      final Meeting meeting =
                          calendarAppointmentDetails.appointments.first
                              as Meeting;
                      return Container(
                        width: calendarAppointmentDetails.bounds.width,
                        height: calendarAppointmentDetails.bounds.height,
                        decoration: BoxDecoration(
                          color: meeting.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              meeting.eventName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${meeting.from.hour.toString().padLeft(2, '0')}:${meeting.from.minute.toString().padLeft(2, '0')} - ${meeting.to.hour.toString().padLeft(2, '0')}:${meeting.to.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      if (kDebugMode) {
                        print('Error in appointmentBuilder: $e');
                      }
                      // 오류 발생 시 기본 UI 반환
                      return Container(
                        width: calendarAppointmentDetails.bounds.width,
                        height: calendarAppointmentDetails.bounds.height,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: const Center(
                          child: Text(
                            '일정 정보 오류',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      );
                    }
                  },
                  selectionDecoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xff2746f8),
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    shape: BoxShape.rectangle,
                  ),
                  cellEndPadding: 0,
                  todayHighlightColor: const Color(0xff2746f8),
                  backgroundColor: const Color(0xfff0f0f0),
                  initialSelectedDate: DateTime.now().toLocal(),
                  initialDisplayDate: DateTime.now().toLocal(),
                  dataSource: MeetingDataSource(_state.filteredMeetings),
                  showDatePickerButton: true,
                  showTodayButton: true,
                  onTap: (CalendarTapDetails details) {
                    if (details.targetElement == CalendarElement.appointment) {
                      try {
                        if (details.appointments != null &&
                            details.appointments!.isNotEmpty &&
                            details.appointments![0] is Meeting) {
                          final meeting = details.appointments![0] as Meeting;
                          // 변경된 일정이나 취소된 일정은 탭해도 아무 동작도 하지 않음
                          if (meeting.description?.contains('[변경된 일정]') ??
                              false ||
                                  meeting.description!.contains('[취소된 일정]')) {
                            return;
                          }
                          _showMeetingDetails(meeting);
                        }
                      } catch (e) {
                        if (kDebugMode) {
                          print('Error in onTap: $e');
                        }
                        // 오류 발생 시 처리하지 않음
                      }
                    }
                  },
                  onViewChanged: _handleViewChanged,
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScheduleDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: CommonBottomNavigationBar(
        isTrainer: true,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // 현재 화면이므로 아무것도 하지 않음
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrainerChatScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PtContractScreen()),
              );
              break;
            case 4:
              _showRoleSwitchDialog();
              break;
          }
        },
      ),
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }
}
