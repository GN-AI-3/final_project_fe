import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../config/env.dart';
import '../../models/member.dart';


class MemberService {
  static String get baseUrl => Env.getServerURL();
  static final String? _authToken = dotenv.env['TRAINEE_TOKEN'];
  static const String _membersEndpoint = '/api/members';
  static const String _meEndpoint = '/api/member/me';
  static const String _logoutEndpoint = '/api/member/logout';

  Future<List<Member>> getMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_membersEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Member.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '회원 목록 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getMembers: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<Member> getMember(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_membersEndpoint/$memberId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return Member.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '회원 정보 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getMember: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<Member> createMember({
    required String name,
    required String email,
    required String phone,
    required String gender,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
      };

      if (kDebugMode) {
        print('Request body: ${jsonEncode(requestBody)}');
      }

      final response = await http.post(
        Uri.parse('$baseUrl$_membersEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return Member.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '회원 생성에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in createMember: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<Member> updateMember({
    required int memberId,
    required String name,
    required String email,
    required String phone,
    required String gender,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
      };

      if (kDebugMode) {
        print('Request body: ${jsonEncode(requestBody)}');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl$_membersEndpoint/$memberId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return Member.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '회원 정보 수정에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in updateMember: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteMember(int memberId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$_membersEndpoint/$memberId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '회원 삭제에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in deleteMember: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<Member> getMyInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_meEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return Member.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '회원 정보 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getMyInfo: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<Member> updateMyInfo(Member member) async {
    try {
      if (kDebugMode) {
        print('Request body: ${jsonEncode(member.toJson())}');
      }

      final response = await http.put(
        Uri.parse('$baseUrl$_meEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode(member.toJson()),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return Member.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '회원 정보 수정에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in updateMyInfo: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<void> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$_logoutEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '로그아웃에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in logout: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }
}
