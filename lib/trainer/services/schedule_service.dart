import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/env.dart';
import '../../models/schedule.dart';

/// 일정 관련 서비스의 기본 추상 클래스
abstract class ScheduleService {
  static String get baseUrl => Env.getServerURL();
  static const String _schedulesEndpoint = '/api/pt_schedules';

  /// 서비스에서 사용할 토큰을 반환하는 getter
  Future<String> getToken();

  /// 일정 목록을 조회하는 메서드
  Future<List<Schedule>> getSchedules({
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  });

  /// 일정 상세 조회
  Future<Schedule> getScheduleDetail(int scheduleId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('${ScheduleService.baseUrl}${ScheduleService._schedulesEndpoint}/$scheduleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Schedule.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '일정 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e) {
      if (kDebugMode) {
        print('Error in getScheduleDetail: $e');
      }
      rethrow;
    }
  }

  /// 일정을 생성하는 메서드
  Future<Schedule> createSchedule({
    required int ptContractId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final requestBody = _buildScheduleRequestBody(
        ptContractId: ptContractId,
        startTime: startTime,
        endTime: endTime,
      );

      if (kDebugMode) {
        print('Request body: ${jsonEncode(requestBody)}');
      }

      final token = await getToken();
      final response = await http.post(
        Uri.parse('${ScheduleService.baseUrl}${ScheduleService._schedulesEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return Schedule.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '일정 생성에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in createSchedule: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  /// 일정을 취소하는 메서드
  Future<Schedule> cancelSchedule({
    required int scheduleId,
    String reason = '트레이너와 협의',
  }) async {
    try {
      if (kDebugMode) {
        print('Request body: ${jsonEncode({'reason': reason})}');
      }

      final token = await getToken();
      final response = await http.patch(
        Uri.parse('${ScheduleService.baseUrl}${ScheduleService._schedulesEndpoint}/$scheduleId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['currentPtCount'] == null) {
          json['currentPtCount'] = 0;
        }
        return Schedule.fromJson(json);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '일정 취소에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in cancelSchedule: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  /// 일정을 변경하는 메서드
  Future<Map<String, dynamic>> changeSchedule({
    required int scheduleId,
    required DateTime startTime,
    required DateTime endTime,
    required String reason,
  }) async {
    try {
      final token = await getToken();
      final response = await http.patch(
        Uri.parse('${ScheduleService.baseUrl}${ScheduleService._schedulesEndpoint}/$scheduleId/change'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'startTime': startTime.millisecondsSinceEpoch ~/ 1000,
          'endTime': endTime.millisecondsSinceEpoch ~/ 1000,
          'reason': reason,
        }),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '일정 변경에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in changeSchedule: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  /// 일정을 불참으로 표시하는 메서드
  Future<Schedule> markNoShow({
    required int scheduleId,
    required String reason,
  }) async {
    try {
      if (kDebugMode) {
        print('Request body: ${jsonEncode({'reason': reason})}');
      }

      final token = await getToken();
      final response = await http.patch(
        Uri.parse('${ScheduleService.baseUrl}${ScheduleService._schedulesEndpoint}/$scheduleId/no_show'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['currentPtCount'] == null) {
          json['currentPtCount'] = 0;
        }
        return Schedule.fromJson(json);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '일정 불참 처리에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in markNoShow: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Map<String, String> _buildQueryParams(
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  ) {
    final queryParams = <String, String>{};
    if (startTime != null) {
      queryParams['startTime'] = (startTime.millisecondsSinceEpoch ~/ 1000).toString();
    }
    if (endTime != null) {
      queryParams['endTime'] = (endTime.millisecondsSinceEpoch ~/ 1000).toString();
    }
    if (status != null) {
      queryParams['status'] = status;
    }
    return queryParams;
  }

  Map<String, dynamic> _buildScheduleRequestBody({
    required int ptContractId,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return {
      'ptContractId': ptContractId,
      'startTime': startTime.millisecondsSinceEpoch ~/ 1000,
      'endTime': endTime.millisecondsSinceEpoch ~/ 1000,
    };
  }
}

/// 트레이너용 일정 서비스
class TrainerScheduleService extends ScheduleService {
  @override
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('TRAINER_TOKEN');
    if (token == null || token.isEmpty) {
      throw Exception('트레이너 토큰이 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }
  
  // 트레이너 ID 가져오기
  Future<String?> _getTrainerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? trainerId = prefs.getString('trainer_id');
      
      if (trainerId == null) {
        // JWT 토큰에서 트레이너 ID 추출 시도
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
            if (payload['id'] != null) {
              trainerId = payload['id'].toString();
              await prefs.setString('trainer_id', trainerId);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error decoding token: $e');
            }
          }
        }
      }
      
      return trainerId;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting trainer ID: $e');
      }
      return null;
    }
  }
  
  @override
  Future<List<Schedule>> getSchedules({
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  }) async {
    try {
      final trainerId = await _getTrainerId();
      
      if (trainerId == null) {
        throw Exception('트레이너 ID를 찾을 수 없습니다. 다시 로그인해주세요.');
      }
      
      final queryParams = _buildQueryParams(startTime, endTime, status);
      queryParams['trainerId'] = int.parse(trainerId).toString();
      
      final uri = Uri.parse(
        '${ScheduleService.baseUrl}${ScheduleService._schedulesEndpoint}',
      ).replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('Requesting schedules with trainerId: ${queryParams['trainerId']}');
        print('Request URI: ${uri.toString()}');
      }

      final token = await getToken();
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Schedule.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '일정 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e) {
      if (kDebugMode) {
        print('Error in getSchedules: $e');
      }
      rethrow;
    }
  }
}

/// 회원용 일정 서비스
class MemberScheduleService extends ScheduleService {
  @override
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('TRAINEE_TOKEN');
    if (token == null || token.isEmpty) {
      throw Exception('회원 토큰이 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }
  
  // 회원 ID 가져오기
  Future<String?> _getMemberId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? memberId = prefs.getString('member_id');
      
      if (memberId == null) {
        // JWT 토큰에서 회원 ID 추출 시도
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
            if (payload['id'] != null) {
              memberId = payload['id'].toString();
              await prefs.setString('member_id', memberId);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error decoding token: $e');
            }
          }
        }
      }
      
      return memberId;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting member ID: $e');
      }
      return null;
    }
  }
  
  @override
  Future<List<Schedule>> getSchedules({
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  }) async {
    try {
      final memberId = await _getMemberId();
      
      if (memberId == null) {
        throw Exception('회원 ID를 찾을 수 없습니다. 다시 로그인해주세요.');
      }
      
      final queryParams = _buildQueryParams(startTime, endTime, status);
      queryParams['memberId'] = int.parse(memberId).toString();
      
      final uri = Uri.parse(
        '${ScheduleService.baseUrl}${ScheduleService._schedulesEndpoint}',
      ).replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('Requesting schedules with memberId: ${queryParams['memberId']}');
        print('Request URI: ${uri.toString()}');
      }

      final token = await getToken();
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Schedule.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '일정 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e) {
      if (kDebugMode) {
        print('Error in getSchedules: $e');
      }
      rethrow;
    }
  }
}
