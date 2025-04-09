import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

import '../constants/calendar_constants.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarView _currentView = CalendarView.schedule;
  late CalendarController _calendarController;

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
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
        // 이 뷰들은 전환하지 않음
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
      // 이 뷰들은 전환하지 않음
      case CalendarView.workWeek:
      case CalendarView.timelineDay:
      case CalendarView.timelineWeek:
      case CalendarView.timelineWorkWeek:
      case CalendarView.timelineMonth:
        return Icons.schedule; // 기본 아이콘 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        SfGlobalLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // iOS 스타일 로케일 지원
      ],
      supportedLocales: [
        const Locale('ko', 'KR'), // 한국어 추가
        const Locale('zh'), const Locale('ar'), const Locale('ja'),
      ],
      locale: const Locale('ko', 'KR'),
      // 기본 로케일을 한국어로 설정
      title: 'Calendar Localization',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('캘린더'),
          actions: [
            IconButton(
              icon: Icon(_getViewIcon()),
              onPressed: _changeView,
              tooltip: '캘린더 전환',
            ),
          ],
        ),
        body: SfCalendar(
          controller: _calendarController,
          view: _currentView,
          scheduleViewSettings: ScheduleViewSettings(
              weekHeaderSettings: WeekHeaderSettings(
                  startDateFormat: 'M월 d일 ',
                  endDateFormat: 'd일',
                  textAlign: TextAlign.center,
              )
          ),
          selectionDecoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Color(0xff2746f8), width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            shape: BoxShape.rectangle,
          ),
          firstDayOfWeek: 1,
          cellEndPadding: 0,
          todayHighlightColor: Color(0xff2746f8),
          backgroundColor: Color(0xfff0f0f0),
          initialDisplayDate: DateTime.now(),
          dataSource: MeetingDataSource(_getDataSource()),
          timeSlotViewSettings: TimeSlotViewSettings(timeIntervalHeight: 70),
        ),
      ),
    );
  }
}

List<Meeting> _getDataSource() {
  final List<Meeting> meetings = <Meeting>[];

  // calendar_constants.dart의 더미 데이터 사용
  final appointments = CalendarConstants.getDummyAppointments();

  for (var appointment in appointments) {
    meetings.add(
      Meeting(
        appointment.subject,
        appointment.startTime,
        appointment.endTime,
        appointment.color,
        appointment.isAllDay,
      ),
    );
  }

  return meetings;
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
  Meeting(this.eventName, this.from, this.to, this.background, this.isAllDay);

  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
}
