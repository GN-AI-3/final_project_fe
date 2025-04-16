import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message.dart';

class PtLogsService {
  static const String _baseUrl = 'http://localhost:8080/api/v1';
  static const String _endpoint = '/chat/completions';

  Future<ChatMessage> sendMessage(String message, List<ChatMessage> history) async {
    try {
      if (kDebugMode) {
        print('Sending message to endpoint: $_baseUrl$_endpoint');
        print('Message: $message');
        print('History: $history');
      }

      // 실제 API 호출을 비활성화하고 더미 응답 반환
      return ChatMessage(
        content: 'PT 일지가 저장되었습니다.',
        role: 'assistant',
      );

      // 실제 API 호출 코드 (현재는 비활성화)
      /*
      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'messages': [
            ...history.map((msg) => msg.toJson()),
            {'role': 'user', 'content': message},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChatMessage(
          content: data['choices'][0]['message']['content'],
          role: 'assistant',
        );
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
      */
    } catch (e) {
      if (kDebugMode) {
        print('Error in sendMessage: $e');
      }
      rethrow;
    }
  }
} 