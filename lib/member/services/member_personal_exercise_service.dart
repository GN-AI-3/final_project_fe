import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../config/env.dart';
import '../../models/chat_message.dart';
import '../../utils/jwt_decoder.dart';

class MemberPersonalExerciseService {
  static String get baseUrl => Env.getServerURL();
  static final String? _authToken = dotenv.env['TRAINEE_TOKEN'];

  int? get _memberId {
    if (_authToken == null) return null;
    return JwtDecoder.getMemberId(_authToken!);
  }

  Future<ChatMessage> sendMessage(
    String message,
    DateTime date,
  ) async {
    try {
      final memberId = _memberId;
      if (memberId == null) {
        throw Exception('멤버 ID를 찾을 수 없습니다. 토큰을 확인해주세요.');
      }

      if (kDebugMode) {
        print('Request body: ${jsonEncode({
          'message': message,
          'memberId': memberId,
          'date': date.toIso8601String(),
        })}');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/workout_log'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'memberId': memberId,
          'date': date.toIso8601String(),
        }),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) {
          return ChatMessage(
            content: data['error'],
            role: 'assistant',
          );
        }
        return ChatMessage(
          content: data['finalResponse'],
          role: 'assistant',
        );
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

  Future<List<ChatMessage>> getRecentMessages(DateTime date) async {
    try {
      final memberId = _memberId;
      if (memberId == null) {
        throw Exception('멤버 ID를 찾을 수 없습니다. 토큰을 확인해주세요.');
      }

      if (kDebugMode) {
        print('Fetching recent messages from: $baseUrl/api/chat/workout_log');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/workout_log?memberId=$memberId&date=${date.toIso8601String()}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessage(
          content: json['finalResponse'],
          role: 'assistant',
        )).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '메시지 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getRecentMessages: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }
} 