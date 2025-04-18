import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../config/env.dart';
import '../../models/pt_log.dart';


class PtLogsService {
  static String get baseUrl => Env.getServerURL();
  static final String? _authToken = dotenv.env['TRAINER_TOKEN'];
  static const String _endpoint = '/api/trainer/chat/pt_log';

  Future<PtLog> sendMessage(
    String message,
    int ptScheduleId,
  ) async {
    try {
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
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'ptScheduleId': ptScheduleId,
        }),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

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
}
