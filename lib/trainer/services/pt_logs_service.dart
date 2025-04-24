import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/env.dart';
import '../../models/pt_log.dart';

class PtLogExercise {
  final String exerciseName;
  final int sets;
  final int reps;
  final int weight;
  final int restTime;
  final String? feedback;
  final DateTime? date;

  PtLogExercise({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restTime,
    this.feedback,
    this.date,
  });

  factory PtLogExercise.fromJson(Map<String, dynamic> json, {DateTime? date}) {
    return PtLogExercise(
      exerciseName: json['exerciseName'] as String? ?? '',
      sets: json['sets'] as int? ?? 0,
      reps: json['reps'] as int? ?? 0,
      weight: json['weight'] as int? ?? 0,
      restTime: json['restTime'] as int? ?? 0,
      feedback: json['feedback'] as String?,
      date: date,
    );
  }
}

class GroupedPtLogExercise {
  final DateTime date;
  final List<PtLogExercise> exercises;

  GroupedPtLogExercise({
    required this.date,
    required this.exercises,
  });
}

class PtLogsService {
  static String get baseUrl => Env.getServerURL();
  static const String _endpoint = '/api/trainer/chat/pt_log';

  // 토큰을 동적으로 가져오는 메소드
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('TRAINER_TOKEN');
  }

  Future<PtLog> sendMessage(
    String message,
    int ptScheduleId,
  ) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }
      
      if (kDebugMode) {
        print('Request body: ${jsonEncode({
          'message': message,
          'ptScheduleId': ptScheduleId,
        })}');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$_endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'ptScheduleId': ptScheduleId,
        }),
      );

      if (response.statusCode == 200) {
        return PtLog.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '메시지 전송에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in sendMessage: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<List<PtLogExercise>> getPtLogExercises(int ptScheduleId) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/pt-log-exercises/pt-schedule/$ptScheduleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PtLogExercise.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'PT 일지 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getPtLogExercises: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<List<GroupedPtLogExercise>> getPtLogExercisesForReport(int ptContractId) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/pt-log-exercises/pt-contract/$ptContractId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (kDebugMode) {
          print('Parsed Data: $data');
        }
        
        final List<GroupedPtLogExercise> groupedExercises = [];
        for (var session in data) {
          final date = DateTime.parse(session['startTime'] as String);
          final exercises = (session['exercises'] as List<dynamic>)
              .map((exercise) => PtLogExercise.fromJson(exercise, date: date))
              .toList();
          
          groupedExercises.add(GroupedPtLogExercise(
            date: date,
            exercises: exercises,
          ));
        }
        
        groupedExercises.sort((a, b) => b.date.compareTo(a.date));
        
        return groupedExercises;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'PT 일지 조회에 실패했습니다.');
      }
    } on SocketException {
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
