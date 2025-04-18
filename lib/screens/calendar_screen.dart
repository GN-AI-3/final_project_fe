import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../models/meeting.dart';
import '../models/pt_contract.dart';
import '../models/schedule.dart';
import '../screens/pt_log_screen.dart';
import '../services/pt_contract_service.dart';
import '../services/schedule_service.dart';
import '../widgets/add_schedule_dialog.dart';
import '../widgets/change_schedule_dialog.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_toast.dart';
import '../widgets/no_show_dialog.dart';

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
  List<PtContract> _ptContracts = [];
  final CalendarState _state = CalendarState();

  @override
  void initState() {
    super.initState();
    _loadMeetings();
    _loadPtContracts();
  }

  Future<void> _loadMeetings({DateTime? startDate, DateTime? endDate}) async {
    if (_state.isLoading) return;
    if (!mounted) return;

    _state.updateLoading(true);

    try {
      final queryStartDate = startDate;
      final queryEndDate = endDate;

      final schedules = await _scheduleService.getSchedules(
        startTime: queryStartDate,
        endTime: queryEndDate,
      );

      if (!mounted) return;

      final meetings = schedules.map((schedule) {
        return _createMeeting(schedule);
      }).toList();

      if (!mounted) return;

      _state.meetings = meetings;
      _state.updateFilteredMeetings(meetings);

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
      final contracts = await _ptContractService.getContractMembers();
      if (mounted) {
        setState(() => _ptContracts = contracts);
      }
    } catch (e) {
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

  void _showAddMeetingDialog() {
    CustomDialog.show(
      context: context,
      child: AddScheduleDialog(
        scheduleService: _scheduleService,
        contracts: _ptContracts,
      ),
    ).then((_) {
      if (_state.lastStartDate != null && _state.lastEndDate != null) {
        _loadMeetings(
          startDate: _state.lastStartDate,
          endDate: _state.lastEndDate,
        );
      } else {
        _loadMeetings();
      }
    });
  }

  void _showMeetingDetails(Meeting meeting) {
    CustomDialog.show(
      context: context,
      title: meeting.eventName,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('시작 일시: ${_formatDateTime(meeting.from)}'),
          Text('종료 일시: ${_formatDateTime(meeting.to)}'),
          if (meeting.description != null) Text('${meeting.description}'),
        ],
      ),
      actions: [
        if (meeting.description?.contains('[완료된 일정]') ?? false)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PtLogScreen(
                        scheduleId: meeting.scheduleId!,
                        meeting: meeting,
                      ),
                ),
              );
            },
            child: const Text('일지 작성'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  void _showMeetingOptions(Meeting meeting) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (meeting.description?.contains('[완료된 일정]') ?? false)
                  ListTile(
                    leading: const Icon(Icons.person_off, color: Colors.red),
                    title: const Text(
                      '불참 처리',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showNoShowDialog(meeting);
                    },
                  )
                else ...[
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('일정 수정'),
                    onTap: () {
                      Navigator.pop(context);
                      _showChangeScheduleDialog(meeting);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.red),
                    title: const Text(
                      '일정 취소',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showCancelDialog(meeting);
                    },
                  ),
                ],
              ],
            ),
          ),
    );
  }

  void _showChangeScheduleDialog(Meeting meeting) {
    CustomDialog.show(
      context: context,
      child: ChangeScheduleDialog(
        scheduleService: _scheduleService,
        meeting: meeting,
        onScheduleChanged: () {
          if (_state.lastStartDate != null && _state.lastEndDate != null) {
            _loadMeetings(
              startDate: _state.lastStartDate,
              endDate: _state.lastEndDate,
            );
          } else {
            _loadMeetings();
          }
        },
      ),
    );
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
          child: const Text('취소'),
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

  void _showNoShowDialog(Meeting meeting) {
    CustomDialog.show(
      context: context,
      child: NoShowDialog(
        meeting: meeting,
        scheduleService: _scheduleService,
        onNoShowProcessed: () {
          if (_state.lastStartDate != null && _state.lastEndDate != null) {
            _loadMeetings(
              startDate: _state.lastStartDate,
              endDate: _state.lastEndDate,
            );
          } else {
            _loadMeetings();
          }
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour}시 ${dateTime.minute}분';
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
        const PopupMenuItem<String>(value: null, child: Text('전체')),
        const PopupMenuItem<String>(value: 'scheduled', child: Text('예정')),
        const PopupMenuItem<String>(value: 'changed', child: Text('변경')),
        const PopupMenuItem<String>(value: 'completed', child: Text('완료')),
        const PopupMenuItem<String>(value: 'cancelled', child: Text('취소')),
        const PopupMenuItem<String>(value: 'no_show', child: Text('불참')),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _state.updateSelectedStatus(value);
          _filterMeetings();
        });
      }
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

    final cachedStart = _state.lastStartDate;
    final cachedEnd = _state.lastEndDate;

    final needsLoading =
        cachedStart == null ||
        cachedEnd == null ||
        startDate.isBefore(cachedStart) ||
        endDate.isAfter(cachedEnd);

    if (needsLoading) {
      _state.updateLastDates(startDate, endDate);
      _loadMeetings(startDate: startDate, endDate: endDate);
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
                  selectionDecoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xff2746f8),
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    shape: BoxShape.rectangle,
                  ),
                  firstDayOfWeek: 1,
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
                      _showMeetingDetails(details.appointments![0] as Meeting);
                    }
                  },
                  onLongPress: (CalendarLongPressDetails details) {
                    if (details.targetElement == CalendarElement.appointment) {
                      final meeting = details.appointments![0] as Meeting;
                      if (meeting.description != null &&
                          !meeting.description!.contains('[취소된 일정]') &&
                          !meeting.description!.contains('[변경된 일정]')) {
                        _showMeetingOptions(meeting);
                      }
                    }
                  },
                  onViewChanged: _handleViewChanged,
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMeetingDialog,
        child: const Icon(Icons.add),
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
