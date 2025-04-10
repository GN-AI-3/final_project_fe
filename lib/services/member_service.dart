import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';

class Member {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final String userType = 'MEMBER';
  final String? goal;
  final DateTime createdAt;
  final DateTime modifiedAt;

  Member({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    this.goal,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImage: json['profile_image'] as String?,
      goal: json['goal'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      modifiedAt: DateTime.parse(json['modified_at'] as String),
    );
  }
}

class MemberService {
  final String baseUrl = Env.getServerURL();

  Future<List<Member>> getMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/pt_contracts/members'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Member.fromJson(json)).toList();
      } else {
        throw Exception('회원 목록을 불러오는데 실패했습니다: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('회원 목록 조회 중 오류 발생: $e');
      }
      rethrow;
    }
  }
} 