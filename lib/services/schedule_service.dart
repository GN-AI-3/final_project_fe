import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/schedule.dart';

class ScheduleService {
  static const String baseUrl = 'http://localhost:8081';

  Future<List<Schedule>> getSchedules() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/schedules'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Schedule.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load schedules');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<DateTime, List<Schedule>>> getSchedulesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final schedules = await getSchedules();
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
} 