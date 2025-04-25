import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/env.dart';
import '../../models/trainer_profile.dart';

class TrainerProfileService {
  static String get baseUrl => Env.getServerURL();
  static const String _tokenKey = 'TRAINER_TOKEN';
  static const String _endpoint = '/api/trainer/me';

  // 토큰 가져오기
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('트레이너 토큰이 없습니다. 다시 로그인해주세요.');
    }
    return token;
  }

  Future<TrainerProfile> getTrainerProfile() async {
    try {
      final token = await getToken();
      
      if (kDebugMode) {
        print('Fetching trainer profile from: $baseUrl$_endpoint');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$_endpoint'),
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
        final jsonData = json.decode(response.body);
        return TrainerProfile.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else if (response.statusCode == 500) {
        final error = jsonDecode(response.body);
        if (error['errMsg']?.toString().contains('no Session') ?? false) {
          throw Exception('서버에서 데이터를 불러오는 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
        }
        throw Exception(error['errMsg'] ?? '트레이너 프로필을 불러오는데 실패했습니다.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '트레이너 프로필을 불러오는데 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getTrainerProfile: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }
} 