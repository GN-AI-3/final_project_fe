import 'package:flutter/material.dart';

class Meeting {
  Meeting(
    this.eventName,
    this.from,
    this.to,
    this.background,
    this.isAllDay, {
    int? id,
    this.description,
    this.scheduleId,
    this.textStyle,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch;

  final int id;
  final int? scheduleId;  // 서버의 스케줄 ID
  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
  String? description;
  TextStyle? textStyle;
} 