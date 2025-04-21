import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/env.dart';
import '../../models/chat_message.dart';
import '../screens/member_chat_screen.dart';

class MemberChatService {
  static String get baseUrl => Env.getServerURL();
  static final String? _authToken = dotenv.env['TRAINEE_TOKEN'];
  
  // 회원 ID (실제로는 로그인 후 저장된 값을 사용해야 함)
  String? _memberId;
  
  // 회원 ID 가져오기
  Future<String?> _getMemberId() async {
    if (_memberId != null) return _memberId;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _memberId = prefs.getString('member_id');
      
      // 임시 - 회원 ID가 없는 경우 샘플 ID 사용 (실제 앱에서는 제거 필요)
      _memberId ??= '4';
      
      return _memberId;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting member ID: $e');
      }
      // 기본 ID 반환 (실제 앱에서는 로그인으로 유도 필요)
      return 'member_5678';
    }
  }

  Future<ChatMessage> sendMessage(
    String message,
    List<ChatMessage> history,
  ) async {
    try {
      // 회원 ID 가져오기
      final memberId = await _getMemberId();
      
      if (kDebugMode) {
        print('Sending message with member ID: $memberId');
        print('Request body: ${jsonEncode({
          'content': message,
          'member_id': memberId,
        })}');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'content': message,
          'member_id': memberId,
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
            role: MemberChatConstants.assistantRole,
          );
        }
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
      // 회원 ID 가져오기
      final memberId = await _getMemberId();
      
      if (kDebugMode) {
        print('Fetching recent messages for member: $memberId');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/recent?member_id=$memberId'),
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