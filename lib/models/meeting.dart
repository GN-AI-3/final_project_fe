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
    this.ptContractId,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch;

  final int id;
  final int? scheduleId;  // 서버의 스케줄 ID
  final int? ptContractId;  // PT 계약 ID
  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  bool isAllDay;
  String? description;
  TextStyle? textStyle;
} 