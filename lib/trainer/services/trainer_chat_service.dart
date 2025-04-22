import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/env.dart';
import '../../models/chat_message.dart';
import '../screens/trainer_chat_screen.dart';

class TrainerChatService {
  static String get baseUrl => Env.getServerURL();
  
  // 토큰을 동적으로 가져오는 메소드
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('TRAINER_TOKEN');
  }
  
  // 트레이너 ID (실제로는 로그인 후 저장된 값을 사용해야 함)
  String? _trainerId;
  
  // 트레이너 ID 가져오기
  Future<String?> _getTrainerId() async {
    if (_trainerId != null) return _trainerId;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _trainerId = prefs.getString('trainer_id');
      
      // 임시 - 트레이너 ID가 없는 경우 샘플 ID 사용 (실제 앱에서는 제거 필요)
      _trainerId ??= '1';
      
      return _trainerId;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting trainer ID: $e');
      }
      // 기본 ID 반환 (실제 앱에서는 로그인으로 유도 필요)
      return 'trainer_1234';
    }
  }

  Future<ChatMessage> sendMessage(
    String message,
    List<ChatMessage> history,
  ) async {
    try {
      // 트레이너 ID 가져오기
      final trainerId = await _getTrainerId();
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }
      
      if (kDebugMode) {
        print('Sending message with trainer ID: $trainerId');
        print('Request body: ${jsonEncode({
          'content': message,
          'trainer_id': trainerId,
        })}');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/trainer/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'content': message,
          'trainer_id': trainerId,
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
            role: TrainerChatConstants.assistantRole,
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
      // 트레이너 ID 가져오기
      final trainerId = await _getTrainerId();
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }
      
      if (kDebugMode) {
        print('Fetching recent messages for trainer: $trainerId');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/trainer/chat/recent?trainer_id=$trainerId'),
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