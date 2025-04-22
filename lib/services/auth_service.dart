import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../utils/jwt_decoder.dart';
import '../config/env.dart';
import 'fcm_service.dart';

class AuthService {
  static const String _userTokenKey = 'user_token';
  static const String _userTypeKey = 'user_type';
  static const String _memberType = 'member';
  static const String _trainerType = 'trainer';
  
  static String get baseUrl => Env.getServerURL();
  
  // Login method
  static Future<bool> login(String email, String password, String userType) async {
    try {
      // FCM 토큰 가져오기 시도
      String? fcmToken;
      try {
        fcmToken = await FCMService.getFCMToken();
        if (kDebugMode) {
          print('FCM 토큰: $fcmToken');
        }
      } catch (e) {
        // FCM 토큰을 가져오는데 실패해도 로그인은 계속 진행
        if (kDebugMode) {
          print('FCM 토큰 가져오기 실패: $e');
        }
      }
      
      // 로그인 엔드포인트 설정
      final loginEndpoint = userType == _memberType 
          ? '/api/member/login' 
          : '/api/trainer/login';
          
      // 로그인 요청 데이터 구성
      final requestBody = {
        'email': email,
        'password': password,
      };
      
      // FCM 토큰이 있으면 요청에 포함
      if (fcmToken != null && fcmToken.isNotEmpty) {
        requestBody['fcmToken'] = fcmToken;
      }
      
      if (kDebugMode) {
        print('로그인 요청: $requestBody');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl$loginEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      if (kDebugMode) {
        print('Login response status: ${response.statusCode}');
        print('Login response body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['accessToken']; // 'accessToken'으로 변경
        
        if (token != null) {
          // Save token and user type to shared preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userTokenKey, token);
          await prefs.setString(_userTypeKey, userType);
          
          // 환경 변수에 직접 쓰기 대신 SharedPreferences만 사용
          if (userType == _memberType) {
            // TRAINEE_TOKEN 저장
            await prefs.setString('TRAINEE_TOKEN', token);
          } else {
            // TRAINER_TOKEN 저장
            await prefs.setString('TRAINER_TOKEN', token);
          }
          
          return true;
        }
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      return false;
    }
  }
  
  // Logout method
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString(_userTypeKey);
      final token = prefs.getString(_userTokenKey);
      
      if (token == null) {
        return true; // Already logged out
      }
      
      final logoutEndpoint = userType == _memberType 
          ? '/api/member/logout' 
          : '/api/trainer/logout';
          
      await http.post(
        Uri.parse('$baseUrl$logoutEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      // Clear stored tokens regardless of server response
      await prefs.remove(_userTokenKey);
      await prefs.remove(_userTypeKey);
      
      // DotEnv write 사용하지 않고 SharedPreferences만 사용
      if (userType == _memberType) {
        await prefs.remove('TRAINEE_TOKEN');
      } else {
        await prefs.remove('TRAINER_TOKEN');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
      
      // Still clear local tokens on error
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userTokenKey);
      await prefs.remove(_userTypeKey);
      
      return true;
    }
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_userTokenKey);
    return token != null && token.isNotEmpty;
  }
  
  // Get current user type
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }
  
  // Check if user is a trainer
  static Future<bool> isTrainer() async {
    final userType = await getUserType();
    return userType == _trainerType;
  }
  
  // Get user token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTokenKey);
  }
  
  // Get user ID from token
  static Future<int?> getUserId() async {
    final token = await getToken();
    if (token == null) return null;
    return JwtDecoder.getMemberId(token);
  }
} 