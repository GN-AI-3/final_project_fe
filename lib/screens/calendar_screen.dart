import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../models/schedule.dart';
import '../services/schedule_service.dart';
import '../widgets/add_reservation_dialog.dart';

/// 캘린더 관련 상수 값들을 정의하는 클래스
class CalendarConstants {
  static const Map<String, String> statusEmojis = {
    'scheduled': '📌',
    'changed': '🔄',
    'completed': '✅',
    'cancelled': '❌',
    'no_show': '⏰',
  };

  static const Map<String, String> statusDescriptions = {
    'scheduled': '[예약됨]',
    'changed': '[변경됨]',
    'completed': '[완료]',
    'cancelled': '[취소됨]',
    'no-show': '[노쇼]',
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

/// 캘린더 상태 관리를 담당하는 클래스
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
  final CalendarState _state = CalendarState();
  final ScheduleService _scheduleService = ScheduleService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadMeetings({DateTime? startDate, DateTime? endDate}) async {
    if (_state.isLoading) return;
    if (!mounted) return;

    _state.updateLoading(true);

    try {
      final queryStartDate = startDate ?? DateTime.now();
      final queryEndDate = endDate ?? DateTime.now();

      final schedules = await _scheduleService.getSchedules(
        startTime: queryStartDate,
        endTime: queryEndDate,
      );

      if (!mounted) return;

      final meetings =
          schedules.map((schedule) {
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
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        _state.updateLoading(false);
      }
    }
  }

  Meeting _createMeeting(Schedule schedule) {
    final eventName = ['changed', 'cancelled'].contains(schedule.status.toLowerCase())
        ? '${_getStatusEmoji(schedule.status)} ${schedule.memberName} - ${schedule.reason}'
        : '${_getStatusEmoji(schedule.status)} ${schedule.memberName} - PT ${schedule.currentPtCount}/${schedule.totalCount}';

    return Meeting(
      eventName,
      schedule.startTime,
      schedule.endTime,
      _state.getMemberColor(schedule.memberId),
      false,
      description:
          '${_getStatusDescription(schedule.status)}\n남은 PT: ${schedule.remainingPtCount}회',
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('오류'),
            content: Text('일정을 불러오는데 실패했습니다: $error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showAddMeetingDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddReservationDialog(
            scheduleService: _scheduleService,
            onScheduleAdded: () {
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

  void _showMeetingDetails(Meeting meeting) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(meeting.eventName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('시작: ${_formatDateTime(meeting.from)}'),
                Text('종료: ${_formatDateTime(meeting.to)}'),
                if (meeting.description != null) Text('${meeting.description}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          ),
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
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('일정 수정'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 일정 수정 기능 구현
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    '일정 삭제',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMeeting(meeting);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _deleteMeeting(Meeting meeting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('일정 삭제'),
            content: const Text('이 일정을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        _state.meetings.removeWhere((m) => m.id == meeting.id);
        _state.updateFilteredMeetings(_state.meetings);
      });
      // TODO: 서버에 삭제 요청 보내기
    }
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
        _state.updateFilteredMeetings(
          _state.meetings.where((meeting) {
            final status = meeting.description?.split('\n')[0];
            return status == _getStatusDescription(_state.selectedStatus!);
          }).toList(),
        );
      }
    });
  }

  String _getStatusEmoji(String status) {
    return CalendarConstants.statusEmojis[status.toLowerCase()] ?? '📌';
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
        const PopupMenuItem<String>(value: null, child: Text('상태: 전체')),
        const PopupMenuItem<String>(value: 'SCHEDULED', child: Text('예정')),
        const PopupMenuItem<String>(value: 'CHANGED', child: Text('변경')),
        const PopupMenuItem<String>(value: 'COMPLETED', child: Text('완료')),
        const PopupMenuItem<String>(value: 'CANCELLED', child: Text('취소')),
        const PopupMenuItem<String>(value: 'NO_SHOW', child: Text('불참')),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _state.updateSelectedStatus(value);
        });
        _filterMeetings();
      }
    });
  }

  void _handleViewChanged(ViewChangedDetails details) {
    if (_state.isLoading) return;

    final visibleDates = details.visibleDates;
    if (visibleDates.isNotEmpty) {
      final startDate = visibleDates.first;
      final endDate = DateTime(
        visibleDates.last.year,
        visibleDates.last.month,
        visibleDates.last.day,
        23,
        59,
        59,
      );

      if (_state.lastStartDate != startDate || _state.lastEndDate != endDate) {
        _state.updateLastDates(startDate, endDate);
        _loadMeetings(startDate: startDate, endDate: endDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body:
          _state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SfCalendar(
                controller: _state.controller,
                view: _state.currentView,
                headerHeight: 50,
                headerStyle: const CalendarHeaderStyle(
                  textAlign: TextAlign.start,
                  backgroundColor: Color(0xfff0f0f0),
                  textStyle: TextStyle(fontSize: 22, color: Colors.black87),
                ),
                headerDateFormat: 'yyyy년 M월',
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
                  border: Border.all(color: const Color(0xff2746f8), width: 2),
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
                timeSlotViewSettings: const TimeSlotViewSettings(
                  timeIntervalHeight: 70,
                ),
                showDatePickerButton: true,
                showTodayButton: true,
                onTap: (CalendarTapDetails details) {
                  if (details.targetElement == CalendarElement.appointment) {
                    _showMeetingDetails(details.appointments![0] as Meeting);
                  }
                },
                onLongPress: (CalendarLongPressDetails details) {
                  if (details.targetElement == CalendarElement.appointment) {
                    _showMeetingOptions(details.appointments![0] as Meeting);
                  }
                },
                onViewChanged: _handleViewChanged,
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

class Meeting {
  Meeting(
    this.eventName,
    this.from,
    this.to,
    this.background,
    this.isAllDay, {
    String? id,
    this.description,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  final String id;
  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
  String? description;
}
