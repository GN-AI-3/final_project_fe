import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/schedule.dart';

class ScheduleService {
  static String get baseUrl => Env.getServerURL();
  static const String _authToken =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwYXNzd29yZCI6IiQyYSQxMCRkNEhjZUNXc1VnL2FUdzQ2am14bDV1SHVwV0h4YjdIeWpTVmUuRzlXSi5LeXdoMkRQVmVyRyIsImNhcmVlciI6Iu2XrOyKpO2KuOugiOydtOuEiCAxMOuFhCIsInBob25lIjoiMDEwMTExMTIyMjIiLCJuYW1lIjoidHJhaW5lcjEiLCJpZCI6MSwidXNlclR5cGUiOiJUUkFJTkVSIiwiY2VydGlmaWNhdGlvbnMiOlsi7IOd7Zmc7Iqk7Y-s7Lig7KeA64-E7IKsIDLquIkiLCLqsbTqsJXsmrTrj5nqtIDrpqzsgqwiXSwiZW1haWwiOiJ0cmFpbmVyQGV4YW1wbGUuY29tIiwic3BlY2lhbGl0aWVzIjpbIuyytOykkeqwkOufiSIsIuq3vOugpeqwle2ZlCIsIuyekOyEuOq1kOyglSJdLCJpYXQiOjE3NDQyNzI1NzYsImV4cCI6MTc0NDYzMjU3Nn0.9vRLk0KMPz6MKAbe3KZOpHTXkQqSkFWVgn_oH1Iz297Oq6IAXOeheeTAvXHVabFA';

  static const String _schedulesEndpoint = '/api/pt_schedules';
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_authToken',
  };

  Future<List<Schedule>> getSchedules({
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  }) async {
    try {
      final queryParams = _buildQueryParams(startTime, endTime, status);
      final uri = Uri.parse(
        '$baseUrl$_schedulesEndpoint',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _defaultHeaders);
      _validateResponse(response);

      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Schedule.fromJson(json)).toList();
    } catch (e) {
      _logError('일정 조회 중 오류 발생', e);
      rethrow;
    }
  }

  Future<Map<DateTime, List<Schedule>>> getSchedulesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final schedules = await getSchedules(startTime: start, endTime: end);
    return _groupSchedulesByDate(schedules);
  }

  Future<Schedule> createSchedule({
    required int ptContractId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final requestBody = _buildScheduleRequestBody(
        ptContractId: ptContractId,
        startTime: startTime,
        endTime: endTime,
      );

      final response = await http.post(
        Uri.parse('$baseUrl$_schedulesEndpoint'),
        headers: _defaultHeaders,
        body: json.encode(requestBody),
      );

      _validateResponse(response);
      return Schedule.fromJson(json.decode(response.body));
    } catch (e) {
      _logError('일정 생성 중 오류 발생', e);
      rethrow;
    }
  }

  Map<String, String> _buildQueryParams(
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  ) {
    final params = <String, String>{};
    if (startTime != null) {
      params['startTime'] =
          (startTime.millisecondsSinceEpoch ~/ 1000).toString();
    }
    if (endTime != null) {
      params['endTime'] = (endTime.millisecondsSinceEpoch ~/ 1000).toString();
    }
    if (status != null) {
      params['status'] = status;
    }
    return params;
  }

  Map<String, dynamic> _buildScheduleRequestBody({
    required int ptContractId,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return {
      'ptContractId': ptContractId,
      'startTime': startTime.millisecondsSinceEpoch ~/ 1000,
      'endTime': endTime.millisecondsSinceEpoch ~/ 1000,
    };
  }

  Map<DateTime, List<Schedule>> _groupSchedulesByDate(
    List<Schedule> schedules,
  ) {
    final Map<DateTime, List<Schedule>> scheduleMap = {};

    for (var schedule in schedules) {
      final date = DateTime(
        schedule.startTime.year,
        schedule.startTime.month,
        schedule.startTime.day,
      );

      scheduleMap.putIfAbsent(date, () => []).add(schedule);
    }

    return scheduleMap;
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('API 요청 실패: ${response.statusCode}');
    }
  }

  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('$message: $error');
    }
  }
}
