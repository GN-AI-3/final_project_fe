import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../models/meeting.dart';
import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/member_change_schedule_dialog.dart';
import '../widgets/member_no_show_dialog.dart';

class MemberCalendarConstants {
  static const Map<String, String> statusDescriptions = {
    'scheduled': '[예정된 일정]',
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

class MemberCalendarState {
  final CalendarController controller = CalendarController();
  CalendarView currentView = CalendarView.month;
  List<Meeting> meetings = [];
  List<Meeting> filteredMeetings = [];
  String? selectedStatus;
  bool isLoading = false;
  DateTime? lastStartDate;
  DateTime? lastEndDate;

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

class MemberCalendarScreen extends StatefulWidget {
  const MemberCalendarScreen({super.key});

  @override
  State<MemberCalendarScreen> createState() => _MemberCalendarScreenState();
}

class _MemberCalendarScreenState extends State<MemberCalendarScreen> {
  final ScheduleService _scheduleService = MemberScheduleService();
  final MemberCalendarState _state = MemberCalendarState();
  DateTime _selectedDate = DateTime.now();
  bool _isButtonVisible = false;

  @override
  void initState() {
    super.initState();
    _isButtonVisible = true;
    _state.updateSelectedStatus('scheduled');
    _loadMeetings();
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
      _filterMeetings();

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

  Meeting _createMeeting(Schedule schedule) {
    final eventName =
        [
              'changed',
              'cancelled',
              'no_show',
            ].contains(schedule.status.toLowerCase())
            ? '${_getStatusDescription(schedule.status)} ${schedule.trainerName} 트레이너님 - ${schedule.reason}'
            : schedule.status.toLowerCase() == 'scheduled'
            ? '${schedule.currentPtCount}회차 PT'
            : '${_getStatusDescription(schedule.status)} ${schedule.trainerName} 트레이너님 (${schedule.currentPtCount}회차)';

    return Meeting(
      eventName,
      schedule.startTime,
      schedule.endTime,
      Colors.blue,
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
                ],
              ],
            ),
          ),
    );
  }

  void _showChangeScheduleDialog(Meeting meeting) {
    CustomDialog.show(
      context: context,
      child: MemberChangeScheduleDialog(
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

  void _showNoShowDialog(Meeting meeting) {
    CustomDialog.show(
      context: context,
      child: MemberNoShowDialog(
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
        MemberCalendarConstants.nextView[_state.currentView] ??
            CalendarView.month,
      );
    });
  }

  void _filterMeetings() {
    setState(() {
      if (_state.selectedStatus == null) {
        _state.updateFilteredMeetings(_state.meetings);
      } else {
        final targetDescription =
            MemberCalendarConstants.statusDescriptions[_state.selectedStatus!
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
    return MemberCalendarConstants.statusDescriptions[status.toLowerCase()] ??
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

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('깔쌈한 제목'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
          ),
          IconButton(
            icon: Icon(
              MemberCalendarConstants.viewIcons[_state.currentView] ??
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
                    appointmentDisplayCount: 2,
                    agendaItemHeight: 50,
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
                    } else if (details.targetElement ==
                        CalendarElement.calendarCell) {
                      setState(() {
                        _selectedDate = details.date!;
                        _isButtonVisible = false;
                      });
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (mounted) {
                          setState(() {
                            _isButtonVisible = true;
                          });
                        }
                      });
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(
                0,
                _isButtonVisible ? 0 : 100,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // 버튼 클릭 시 동작 추가
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xff2746f8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '${_formatDate(_selectedDate)} 개인 운동 기록하기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
