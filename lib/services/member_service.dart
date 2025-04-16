import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/member.dart';

class MemberService {
  static String get baseUrl => Env.getServerURL();
  static const String _authToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwYXNzd29yZCI6IiQyYSQxMCRkNEhjZUNXc1VnL2FUdzQ2am14bDV1SHVwV0h4YjdIeWpTVmUuRzlXSi5LeXdoMkRQVmVyRyIsInBob25lIjoiMDEwMTExMTIyMjIiLCJuYW1lIjoi7J6l6re87JqwIiwiaWQiOjQsInVzZXJUeXBlIjoiTUVNQkVSIiwiZW1haWwiOiJ1c2VyMUB0ZXN0LmNvbSIsImdvYWxzIjpbIldFSUdIVF9MT1NTIl0sImlhdCI6MTc0NDc4NjAxNiwiZXhwIjoxNzQ1MTQ2MDE2fQ.K0hNJEV0TLj0qYdFGpP0KeowQHmZ7kWwzxN_c8gMekjVbb1KnvMiJ0YHhsHLYG49';

  static const String _meEndpoint = '/api/member/me';
  static const String _logoutEndpoint = '/api/member/logout';
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_authToken',
  };

  Future<Member> getMyInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_meEndpoint'),
        headers: _defaultHeaders,
      );
      _validateResponse(response);

      final json = jsonDecode(response.body);
      if (kDebugMode) {
        print('회원 정보 응답: $json');
      }
      
      final member = Member.fromJson(json);
      if (kDebugMode) {
        print('파싱된 회원 정보: $member');
      }
      
      return member;
    } catch (e) {
      _logError('회원 정보 조회 중 오류 발생', e);
      rethrow;
    }
  }

  Future<Member> updateMyInfo(Member member) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$_meEndpoint'),
        headers: _defaultHeaders,
        body: jsonEncode(member.toJson()),
      );
      _validateResponse(response);

      final json = jsonDecode(response.body);
      return Member.fromJson(json);
    } catch (e) {
      _logError('회원 정보 수정 중 오류 발생', e);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_logoutEndpoint'),
        headers: _defaultHeaders,
      );
      _validateResponse(response);
    } catch (e) {
      _logError('로그아웃 중 오류 발생', e);
      rethrow;
    }
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('API 요청 실패: ${response.statusCode}');
    }
    
    try {
      final json = jsonDecode(response.body);
      if (json is! Map) {
        throw Exception('잘못된 응답 형식: Map이 아닙니다');
      }
    } catch (e) {
      throw Exception('응답 데이터 파싱 실패: $e');
    }
  }

  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('$message: $error');
    }
  }
}
