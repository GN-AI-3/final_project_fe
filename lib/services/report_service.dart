import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report.dart';
import '../config/env.dart';
import 'auth_service.dart';

class ReportService {
  static String get baseUrl => Env.getServerURL();

  static Future<List<Report>> getLatestReports(int ptContractId) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('인증 토큰이 없습니다.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/reports/latest/$ptContractId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isEmpty) {
        throw Exception('리포트가 없습니다.');
      }
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception('리포트를 불러오는데 실패했습니다: ${response.statusCode}');
    }
  }
} 