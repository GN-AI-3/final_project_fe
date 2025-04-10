import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../services/schedule_service.dart';
import '../widgets/add_reservation_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarController _calendarController;
  CalendarView _currentView = CalendarView.month;
  List<Meeting> _meetings = [];
  List<Meeting> _filteredMeetings = [];
  final ScheduleService _scheduleService = ScheduleService();
  String? _selectedStatus;

  // 멤버 ID별 랜덤 색상 생성
  final Map<int, Color> _memberColors = {};

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _loadMeetings();
  }

  void _showAddMeetingDialog() {
    showDialog(
      context: context,
      builder: (context) => AddReservationDialog(
        scheduleService: _scheduleService,
        onScheduleAdded: _loadMeetings,
      ),
    );
  }

  void _showMeetingDetails(Meeting meeting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      builder: (context) => SafeArea(
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
      builder: (context) => AlertDialog(
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
        _meetings.removeWhere((m) => m.id == meeting.id);
      });
      // TODO: 서버에 삭제 요청 보내기
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour}시 ${dateTime.minute}분';
  }

  void _changeView() {
    setState(() {
      switch (_currentView) {
        case CalendarView.day:
          _currentView = CalendarView.week;
          break;
        case CalendarView.week:
          _currentView = CalendarView.month;
          break;
        case CalendarView.month:
          _currentView = CalendarView.schedule;
          break;
        case CalendarView.schedule:
          _currentView = CalendarView.day;
          break;
        case CalendarView.workWeek:
        case CalendarView.timelineDay:
        case CalendarView.timelineWeek:
        case CalendarView.timelineWorkWeek:
        case CalendarView.timelineMonth:
          break;
      }
      _calendarController.view = _currentView;
    });
  }

  IconData _getViewIcon() {
    switch (_currentView) {
      case CalendarView.day:
        return Icons.view_day;
      case CalendarView.week:
        return Icons.view_week;
      case CalendarView.month:
        return Icons.calendar_month;
      case CalendarView.schedule:
        return Icons.schedule;
      case CalendarView.workWeek:
      case CalendarView.timelineDay:
      case CalendarView.timelineWeek:
      case CalendarView.timelineWorkWeek:
      case CalendarView.timelineMonth:
        return Icons.schedule;
    }
  }

  void _filterMeetings() {
    setState(() {
      if (_selectedStatus == null) {
        _filteredMeetings = _meetings;
      } else {
        _filteredMeetings = _meetings.where((meeting) {
          final status = meeting.description?.split('\n')[0];
          return status == _getStatusDescription(_selectedStatus!);
        }).toList();
      }
    });
  }

  Color _getMemberColor(int memberId) {
    if (!_memberColors.containsKey(memberId)) {
      final hue = (memberId * 137.508) % 360;
      _memberColors[memberId] = HSLColor.fromAHSL(0.9, hue, 0.85, 0.4).toColor();
    }
    return _memberColors[memberId]!;
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return '📌';
      case 'changed':
        return '🔄';
      case 'completed':
        return '✅';
      case 'cancelled':
        return '❌';
      case 'no_show':
        return '⏰';
      default:
        return '📌';
    }
  }

  String _getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return '[예약됨]';
      case 'changed':
        return '[변경됨]';
      case 'completed':
        return '[완료]';
      case 'cancelled':
        return '[취소됨]';
      case 'no-show':
        return '[노쇼]';
      default:
        return '[${status.toUpperCase()}]';
    }
  }

  Future<void> _loadMeetings() async {
    try {
      final now = DateTime.now();
      final startDate = now;
      final endDate = DateTime(now.year, now.month + 12, 0, 23, 59, 59);

      if (kDebugMode) {
        print('일정 조회 기간: ${startDate.toString()} ~ ${endDate.toString()}');
      }

      final schedules = await _scheduleService.getSchedules(
        startTime: startDate,
        endTime: endDate,
      );

      if (kDebugMode) {
        print('조회된 일정 수: ${schedules.length}');
      }

      setState(() {
        _meetings = schedules.map((schedule) {
          if (kDebugMode) {
            print(
              '일정 변환: ${schedule.memberName} - ${schedule.startTime} ~ ${schedule.endTime}',
            );
          }
          return Meeting(
            '${_getStatusText(schedule.status)} ${schedule.memberName} - PT ${schedule.currentPtCount}/${schedule.totalCount}',
            schedule.startTime,
            schedule.endTime,
            _getMemberColor(schedule.memberId),
            false,
            description:
                '${_getStatusDescription(schedule.status)}\n남은 PT: ${schedule.remainingPtCount}회',
          );
        }).toList();
        _filteredMeetings = _meetings;
      });

      if (kDebugMode) {
        print('변환된 미팅 수: ${_meetings.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('일정 로드 중 오류 발생: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        backgroundColor: const Color(0xfff0f0f0),
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _selectedStatus,
              hint: const Text('상태 필터'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('전체')),
                ...[
                  'scheduled',
                  'changed',
                  'completed',
                  'cancelled',
                  'no-show',
                ].map(
                  (status) => DropdownMenuItem<String>(
                    value: status,
                    child: Row(
                      children: [
                        Text(_getStatusText(status)),
                        const SizedBox(width: 8),
                        Text(_getStatusDescription(status)),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                  _filterMeetings();
                });
              },
            ),
          ),
          IconButton(
            icon: Icon(_getViewIcon()),
            onPressed: _changeView,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _showAddMeetingDialog,
        backgroundColor: const Color(0xff2746f8),
        elevation: 4,
        shape: const CircleBorder(),
        heroTag: 'addMeeting',
        child: const Icon(Icons.edit_calendar, color: Colors.white, size: 64),
      ),
      body: SfCalendar(
        controller: _calendarController,
        view: _currentView,
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
        dataSource: MeetingDataSource(_filteredMeetings),
        timeSlotViewSettings: const TimeSlotViewSettings(timeIntervalHeight: 70),
        showDatePickerButton: true,
        showTodayButton: true,
        onTap: (CalendarTapDetails details) {
          if (details.targetElement == CalendarElement.appointment) {
            final appointments = details.appointments;
            if (appointments != null && appointments.isNotEmpty) {
              final meeting = appointments[0] as Meeting;
              _showMeetingDetails(meeting);
            }
          }
        },
        onLongPress: (CalendarLongPressDetails details) {
          if (details.targetElement == CalendarElement.appointment) {
            final appointments = details.appointments;
            if (appointments != null && appointments.isNotEmpty) {
              final meeting = appointments[0] as Meeting;
              _showMeetingOptions(meeting);
            }
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
