import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/env.dart';
import '../../models/chat_message.dart';
import '../../models/exercise_record.dart';
import '../../services/auth_service.dart';

class MemberPersonalExerciseService {
  static String get baseUrl => Env.getServerURL();
  static const String _tokenKey = 'TRAINEE_TOKEN';

  // 토큰 가져오기
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('회원 토큰이 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }

  Future<String> getTokenForReport() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('TRAINER_TOKEN');
    if (token == null || token.isEmpty) {
      throw Exception('트레이너 토큰이 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }

  // 회원 ID 가져오기
  Future<int> getMemberId() async {
    try {
      // 1. 먼저 SharedPreferences에서 저장된 ID를 확인
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getString('member_id');
      
      if (memberId != null) {
        if (kDebugMode) {
          print('Retrieved member ID from preferences: $memberId');
        }
        return int.parse(memberId);
      }
      
      // 2. 저장된 ID가 없으면 JWT 토큰에서 추출 시도
      final token = await getToken();
      final tokenParts = token.split('.');
      if (tokenParts.length == 3) {
        try {
          final payload = jsonDecode(
            utf8.decode(
              base64Url.decode(
                base64Url.normalize(tokenParts[1])
              )
            )
          );
          if (kDebugMode) {
            print('JWT Token payload: $payload');
          }
          if (payload['id'] != null) {
            final id = payload['id'].toString();
            await prefs.setString('member_id', id);
            if (kDebugMode) {
              print('Retrieved member ID from token: $id');
            }
            return int.parse(id);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error decoding token: $e');
          }
        }
      }
      
      // 3. 기존 방식 (AuthService 사용) 시도
      final userIdFromAuth = await AuthService.getUserId();
      if (userIdFromAuth != null) {
        await prefs.setString('member_id', userIdFromAuth.toString());
        return userIdFromAuth;
      }
      
      throw Exception('멤버 ID를 찾을 수 없습니다. 다시 로그인해주세요.');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting memberId: $e');
      }
      throw Exception('멤버 ID를 가져오는 데 실패했습니다: $e');
    }
  }

  Future<ChatMessage> sendMessage(String message, DateTime date) async {
    try {
      final memberId = await getMemberId();
      final token = await getToken();

      if (kDebugMode) {
        print(
          'Request body: ${jsonEncode({'message': message, 'memberId': memberId, 'date': date.toIso8601String()})}',
        );
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/chat/workout_log'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
          return ChatMessage(content: data['error'], role: 'assistant');
        }
        
        // finalResponse 필드가 있는 경우 이를 content와 finalResponse로 설정
        if (data['finalResponse'] != null) {
          return ChatMessage(
            content: data['finalResponse'],
            role: 'assistant',
            finalResponse: data['finalResponse'],
          );
        }
        
        return ChatMessage(content: data['content'] ?? '응답이 없습니다.', role: 'assistant');
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
      final memberId = await getMemberId();
      final token = await getToken();

      if (kDebugMode) {
        print('Fetching recent messages from: $baseUrl/api/chat/workout_log');
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/chat/workout_log?memberId=$memberId&date=${date.toIso8601String()}',
        ),
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
        return data
            .map(
              (json) => ChatMessage(
                content: json['finalResponse'],
                role: 'assistant',
              ),
            )
            .toList();
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

  Future<List<GroupedExerciseRecord>> getExerciseRecords(
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final memberId = await getMemberId();
      final token = await getToken();

      if (kDebugMode) {
        print(
          'Fetching exercise records from: $baseUrl/api/exercise_records/grouped',
        );
        print('Date range: ${startTime.toString()} to ${endTime.toString()}');
      }

      // 날짜 형식을 yyyy-MM-dd로 변환
      final startDate =
          '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';
      final endDate =
          '${endTime.year}-${endTime.month.toString().padLeft(2, '0')}-${endTime.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/exercise_records/grouped?memberId=$memberId&startTime=$startDate&endTime=$endDate',
        ),
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
        return data
            .map((json) => GroupedExerciseRecord.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '운동 기록 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getExerciseRecords: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<List<GroupedExerciseRecord>> getExerciseRecordsForReport(
    int ptContractId,
  ) async {
    try {
      final token = await getTokenForReport();

      if (kDebugMode) {
        print(
          'Fetching exercise records from: $baseUrl/api/exercise_records/pt_contract/$ptContractId',
        );
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/exercise_records/pt_contract/$ptContractId'),
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
        return data
            .map((json) => GroupedExerciseRecord.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '운동 기록 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getExerciseRecordsForReport: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<ExerciseRecord> updateExerciseRecord({
    required int memberId,
    required int exerciseId,
    required DateTime date,
    required Map<String, dynamic> recordData,
    required Map<String, dynamic> memoData,
  }) async {
    try {
      final token = await getToken();

      if (kDebugMode) {
        print('Updating exercise record...');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/api/exercise_records'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'memberId': memberId,
          'exerciseId': exerciseId,
          'date': date.toIso8601String().split('T')[0],
          'recordData': recordData,
          'memoData': memoData,
        }),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ExerciseRecord.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '운동 기록 수정에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in updateExerciseRecord: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }
}
