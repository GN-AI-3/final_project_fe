import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/env.dart';
import '../models/schedule.dart';

/// 일정 관련 서비스의 기본 추상 클래스
abstract class ScheduleService {
  static String get baseUrl => Env.getServerURL();
  static const String _schedulesEndpoint = '/api/pt_schedules';

  /// 서비스에서 사용할 토큰을 반환하는 getter
  String get token;

  /// 일정 목록을 조회하는 메서드
  Future<List<Schedule>> getSchedules({
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  }) async {
    try {
      final queryParams = _buildQueryParams(startTime, endTime, status);
      final uri = Uri.parse(
        '$baseUrl$_schedulesEndpoint',
      ).replace(queryParameters: queryParams);

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
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getSchedules: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
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

      final response = await http.post(
        Uri.parse('$baseUrl$_schedulesEndpoint'),
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

      final response = await http.patch(
        Uri.parse('$baseUrl$_schedulesEndpoint/$scheduleId/cancel'),
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
      final response = await http.patch(
        Uri.parse('$baseUrl$_schedulesEndpoint/$scheduleId/change'),
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

  /// 불참 처리를 하는 메서드
  Future<Schedule> noShowSchedule({
    required int scheduleId,
    String reason = '부재중',
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$_schedulesEndpoint/$scheduleId/no_show'),
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
        return Schedule.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '불참 처리에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in noShowSchedule: $e');
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
    final params = <String, String>{};
    if (startTime != null) {
      params['startTime'] =
          (startTime.millisecondsSinceEpoch ~/ 1000).toString();
    }
    if (endTime != null) {
      params['endTime'] = (endTime.millisecondsSinceEpoch ~/ 1000).toString();
    }
    if (status != null) {
      params['status'] = status;
    }
    return params;
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
  String get token => dotenv.env['TRAINER_TOKEN']!;
}

/// 회원용 일정 서비스
class MemberScheduleService extends ScheduleService {
  // 테스트 환경에서는 환경 변수에서 토큰을 가져옴
  @override
  String get token => dotenv.env['TRAINEE_TOKEN']!;

  // 실제 배포 환경에서는 아래와 같이 사용
  /*
  final String _memberToken;

  MemberScheduleService(this._memberToken);

  @override
  String get token => _memberToken;
  */
}
