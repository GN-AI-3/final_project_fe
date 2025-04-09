// lib/services/chat_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ChatService {
  // 실제 기기 테스트를 위한 주소 (컴퓨터의 로컬 IP 주소로 변경 필요)
  static const String baseUrl = 'http://192.168.0.168:8081/api/anonymous-chat';
  // 에뮬레이터용 주소
  // static const String baseUrl = 'http://10.0.2.2:8081/api/anonymous-chat';

  Future<ChatMessage> sendMessage(String message, List<ChatMessage> history) async {
    try {
      print('Preparing to send message to: $baseUrl/send');
      print('Request body: ${jsonEncode({'content': message})}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'content': message,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 연결 시간이 초과되었습니다. 서버가 실행 중인지 확인해주세요.');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessage.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '메시지 전송에 실패했습니다.');
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      print('Error in sendMessage: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error: $e');
    }
  }

  Future<List<ChatMessage>> getRecentMessages() async {
    try {
      print('Fetching recent messages from: $baseUrl/recent');
      
      final response = await http.get(
        Uri.parse('$baseUrl/recent'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 연결 시간이 초과되었습니다.');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '메시지 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      print('Error in getRecentMessages: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error: $e');
    }
  }
}