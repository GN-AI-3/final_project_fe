import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../models/meeting.dart';

class MemberCalendarConstants {
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

  void updateView(CalendarView newView) {
    currentView = newView;
    controller.view = newView;
  }

  void updateFilteredMeetings(List<Meeting> meetings) {
    filteredMeetings = meetings;
  }
}

class MemberCalendarScreen extends StatefulWidget {
  const MemberCalendarScreen({super.key});

  @override
  State<MemberCalendarScreen> createState() => _MemberCalendarScreenState();
}

class _MemberCalendarScreenState extends State<MemberCalendarScreen> {
  final MemberCalendarState _state = MemberCalendarState();

  @override
  void initState() {
    super.initState();
    _state.meetings = [];
    _state.updateFilteredMeetings([]);
  }

  void _changeView() {
    setState(() {
      _state.updateView(
        MemberCalendarConstants.nextView[_state.currentView] ??
            CalendarView.month,
      );
    });
  }

  void _handleViewChanged(ViewChangedDetails details) {
    // 아무것도 하지 않음
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          IconButton(
            icon: Icon(
              MemberCalendarConstants.viewIcons[_state.currentView] ??
                  Icons.calendar_month,
            ),
            onPressed: _changeView,
          ),
        ],
        forceMaterialTransparency: true,
      ),
      body: SfCalendar(
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
        onViewChanged: _handleViewChanged,
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
