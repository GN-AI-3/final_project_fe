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
  bool _isLoading = false;

  // 멤버 ID별 랜덤 색상 생성
  final Map<int, Color> _memberColors = {};

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
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
    } catch (e) {
      _showError('일정을 불러오는데 실패했습니다', e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        _filteredMeetings = _meetings;
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
        default:
          _currentView = CalendarView.month;
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
      default:
        return Icons.calendar_month;
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

  void _showError(String message, dynamic error) {
    if (kDebugMode) {
      print('$message: $error');
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message: $error')),
      );
    }
  }

  void _showFilterMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1, 80, 0, 0),
      items: [
        const PopupMenuItem<String>(
          value: null,
          child: Text('상태: 전체'),
        ),
        const PopupMenuItem<String>(
          value: 'SCHEDULED',
          child: Text('예정'),
        ),
        const PopupMenuItem<String>(
          value: 'CHANGED',
          child: Text('변경'),
        ),
        const PopupMenuItem<String>(
          value: 'COMPLETED',
          child: Text('완료'),
        ),
        const PopupMenuItem<String>(
          value: 'CANCELLED',
          child: Text('취소'),
        ),
        const PopupMenuItem<String>(
          value: 'NO_SHOW',
          child: Text('불참'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _selectedStatus = value;
        });
        _filterMeetings();
      }
    });
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
            icon: Icon(_getViewIcon()),
            onPressed: _changeView,
          ),
        ], forceMaterialTransparency: true,),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SfCalendar(
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
                  _showMeetingDetails(details.appointments![0] as Meeting);
                }
              },
              onLongPress: (CalendarLongPressDetails details) {
                if (details.targetElement == CalendarElement.appointment) {
                  _showMeetingOptions(details.appointments![0] as Meeting);
                }
              },
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
