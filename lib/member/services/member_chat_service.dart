import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/env.dart';
import '../../models/chat_message.dart';
import '../screens/member_chat_screen.dart';

class MemberChatService {
  static String get baseUrl => Env.getServerURL();
  
  // 토큰을 동적으로 가져오는 메소드
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('TRAINEE_TOKEN');
  }
  
  // 회원 ID (실제로는 로그인 후 저장된 값을 사용해야 함)
  String? _memberId;
  
  // 회원 ID 가져오기
  Future<String?> _getMemberId() async {
    if (_memberId != null) return _memberId;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _memberId = prefs.getString('member_id');
      
      if (_memberId == null) {
        // 토큰으로부터 회원 정보 가져오기 시도
        final token = await _getAuthToken();
        if (token != null) {
          try {
            final response = await http.get(
              Uri.parse('$baseUrl/api/member/me'),
              headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            );
            
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              _memberId = data['id'].toString();
              // 회원 ID 저장
              await prefs.setString('member_id', _memberId!);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching member info: $e');
            }
          }
        }
      }
      
      return _memberId;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting member ID: $e');
      }
      return null;
    }
  }

  Future<ChatMessage> sendMessage(
    String message,
    List<ChatMessage> history,
  ) async {
    try {
      // 회원 ID 가져오기
      final memberId = await _getMemberId();
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }
      
      if (kDebugMode) {
        print('Sending message with member ID: $memberId');
        if (memberId == null) {
          throw Exception('회원 ID를 찾을 수 없습니다. 다시 로그인해주세요.');
        }
        final requestBody = {
          'content': message,
          'role': 'member',
          'memberId': int.parse(memberId),
        };
        print('Request body: ${jsonEncode(requestBody)}');
        print('Request body type: ${requestBody.runtimeType}');
        print('memberId type: ${requestBody['memberId'].runtimeType}');
      }

      if (memberId == null) {
        throw Exception('회원 ID를 찾을 수 없습니다. 다시 로그인해주세요.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'content': message,
          'role': 'member',
          'memberId': int.parse(memberId),
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
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }
      
      if (kDebugMode) {
        print('Fetching recent messages for member: $memberId');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/recent?member_id=$memberId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
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