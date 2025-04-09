// lib/constants/calendar_constants.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarConstants {
  static List<Appointment> getDummyAppointments() {
    final List<Appointment> appointments = <Appointment>[];
    
    // 현재 날짜 기준으로 정시로 설정
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    appointments.add(
      Appointment(
        startTime: today.add(Duration(hours: 19)),
        endTime: today.add(Duration(hours: 20)),
        subject: 'PT - 김지훈 회원님',
        color: Colors.red,
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 2, hours: 10)),
        endTime: today.add(Duration(days: 2, hours: 11)),
        subject: 'PT - 진현무 회원님',
        color: Color(0xFf527318),
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 2, hours: 15)),
        endTime: today.add(Duration(days: 2, hours: 16)),
        subject: 'PT - 오지혜 회원님',
        color: Color(0xFf3282b8),
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 2, hours: 17)),
        endTime: today.add(Duration(days: 2, hours: 18)),
        subject: 'PT - 김세혁 회원님',
        color: Color(0xFf2a7886),
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 1, hours: 9)),
        endTime: today.add(Duration(days: 1, hours: 10)),
        subject: '휴무',
        color: Colors.lightBlueAccent,
        isAllDay: true,
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 3, hours: 16)),
        endTime: today.add(Duration(days: 3, hours: 17)),
        subject: 'PT - 장근우 회원님',
        color: Colors.purple,
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 7, hours: 19)),
        endTime: today.add(Duration(days: 7, hours: 20)),
        subject: 'PT - 김지훈 회원님',
        color: Colors.red,
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 9, hours: 10)),
        endTime: today.add(Duration(days: 9, hours: 11)),
        subject: 'PT - 진현무 회원님',
        color: Color(0xFf527318),
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 9, hours: 15)),
        endTime: today.add(Duration(days: 9, hours: 16)),
        subject: 'PT - 오지혜 회원님',
        color: Color(0xFf3282b8),
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 9, hours: 17)),
        endTime: today.add(Duration(days: 9, hours: 18)),
        subject: 'PT - 김세혁 회원님',
        color: Color(0xFf2a7886),
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 8, hours: 9)),
        endTime: today.add(Duration(days: 8, hours: 10)),
        subject: '휴일',
        color: Colors.lightBlueAccent,
        isAllDay: true,
      ),
    );
    appointments.add(
      Appointment(
        startTime: today.add(Duration(days: 10, hours: 16)),
        endTime: today.add(Duration(days: 10, hours: 17)),
        subject: 'PT - 장근우 회원님',
        color: Colors.purple,
      ),
    );
    return appointments;
  }
}