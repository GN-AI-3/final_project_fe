// lib/services/chat_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/chat_message.dart';

class ChatService {
  static String get baseUrl => Env.getServerURL();
  static const String _authToken =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwYXNzd29yZCI6IiQyYSQxMCRkNEhjZUNXc1VnL2FUdzQ2am14bDV1SHVwV0h4YjdIeWpTVmUuRzlXSi5LeXdoMkRQVmVyRyIsInBob25lIjoiMDEwMTExMTIyMjIiLCJuYW1lIjoi7J6l6re87JqwIiwiaWQiOjQsInVzZXJUeXBlIjoiTUVNQkVSIiwiZW1haWwiOiJ1c2VyMUB0ZXN0LmNvbSIsImdvYWxzIjpbIldFSUdIVF9MT1NTIl0sImlhdCI6MTc0NDI1MzgwNywiZXhwIjoxNzQ0NjEzODA3fQ.ZwSyytMdjDAQXhoZpE0UQZLbE72Vfkp4HH1MYj84PkYA2bUfAF8u11np6pA_cBcE';

  Future<ChatMessage> sendMessage(
    String message,
    List<ChatMessage> history,
  ) async {
    try {
      if (kDebugMode) {
        print('Preparing to send message to: $baseUrl/api/anonymous-chat/send');
        print('Request body: ${jsonEncode({'content': message})}');
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/anonymous-chat/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
              'Accept': 'application/json',
            },
            body: jsonEncode({'content': message}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('서버 연결 시간이 초과되었습니다. 서버가 실행 중인지 확인해주세요.');
            },
          );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessage.fromJson(data);
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

  Future<List<ChatMessage>> getRecentMessages() async {
    try {
      if (kDebugMode) {
        print('Fetching recent messages from: $baseUrl/api');
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/recent'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('서버 연결 시간이 초과되었습니다.');
            },
          );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
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
