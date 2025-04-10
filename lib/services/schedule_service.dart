import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';
import '../config/env.dart';

class ScheduleService {
  static String get baseUrl => Env.getServerURL();
  static const String _authToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwYXNzd29yZCI6IiQyYSQxMCRkNEhjZUNXc1VnL2FUdzQ2am14bDV1SHVwV0h4YjdIeWpTVmUuRzlXSi5LeXdoMkRQVmVyRyIsImNhcmVlciI6Iu2XrOyKpO2KuOugiOydtOuEiCAxMOuFhCIsInBob25lIjoiMDEwMTExMTIyMjIiLCJuYW1lIjoidHJhaW5lcjEiLCJpZCI6MSwidXNlclR5cGUiOiJUUkFJTkVSIiwiY2VydGlmaWNhdGlvbnMiOlsi7IOd7Zmc7Iqk7Y-s7Lig7KeA64-E7IKsIDLquIkiLCLqsbTqsJXsmrTrj5nqtIDrpqzsgqwiXSwiZW1haWwiOiJ0cmFpbmVyQGV4YW1wbGUuY29tIiwic3BlY2lhbGl0aWVzIjpbIuyytOykkeqwkOufiSIsIuq3vOugpeqwle2ZlCIsIuyekOyEuOq1kOyglSJdLCJpYXQiOjE3NDQyNzI1NzYsImV4cCI6MTc0NDYzMjU3Nn0.9vRLk0KMPz6MKAbe3KZOpHTXkQqSkFWVgn_oH1Iz297Oq6IAXOeheeTAvXHVabFA';

  Future<List<Schedule>> getSchedules({
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  }) async {
    try {
      final queryParams = {
        if (startTime != null) 'startTime': (startTime.millisecondsSinceEpoch ~/ 1000).toString(),
        if (endTime != null) 'endTime': (endTime.millisecondsSinceEpoch ~/ 1000).toString(),
        if (status != null) 'status': status,
      };

      final uri = Uri.parse('$baseUrl/api/pt_schedules').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Schedule.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load schedules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<DateTime, List<Schedule>>> getSchedulesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final schedules = await getSchedules(
      startTime: start,
      endTime: end,
    );
    
    final Map<DateTime, List<Schedule>> scheduleMap = {};

    for (var schedule in schedules) {
      final date = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );
      
      if (!scheduleMap.containsKey(date)) {
        scheduleMap[date] = [];
      }
      scheduleMap[date]!.add(schedule);
    }

    return scheduleMap;
  }

  Future<Schedule> createSchedule({
    required int memberId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pt_schedules'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'memberId': memberId,
          'startTime': startTime.millisecondsSinceEpoch ~/ 1000,
          'endTime': endTime.millisecondsSinceEpoch ~/ 1000,
        }),
      );

      if (response.statusCode == 200) {
        return Schedule.fromJson(json.decode(response.body));
      } else {
        throw Exception('일정 생성에 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('일정 생성 중 오류 발생: $e');
      }
      rethrow;
    }
  }
} 