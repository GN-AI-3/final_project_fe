import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/pt_contract.dart';

class PtContractService {
  static String get baseUrl => Env.getServerURL();
  static const String _authToken =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwYXNzd29yZCI6IiQyYSQxMCRkNEhjZUNXc1VnL2FUdzQ2am14bDV1SHVwV0h4YjdIeWpTVmUuRzlXSi5LeXdoMkRQVmVyRyIsImNhcmVlciI6Iu2XrOyKpO2KuOugiOydtOuEiCAxMOuFhCIsInBob25lIjoiMDEwMTExMTIyMjIiLCJuYW1lIjoidHJhaW5lcjEiLCJpZCI6MSwidXNlclR5cGUiOiJUUkFJTkVSIiwiY2VydGlmaWNhdGlvbnMiOlsi7IOd7Zmc7Iqk7Y-s7Lig7KeA64-E7IKsIDLquIkiLCLqsbTqsJXsmrTrj5nqtIDrpqzsgqwiXSwiZW1haWwiOiJ0cmFpbmVyQGV4YW1wbGUuY29tIiwic3BlY2lhbGl0aWVzIjpbIuyytOykkeqwkOufiSIsIuq3vOugpeqwle2ZlCIsIuyekOyEuOq1kOyglSJdLCJpYXQiOjE3NDQyNzI1NzYsImV4cCI6MTc0NDYzMjU3Nn0.9vRLk0KMPz6MKAbe3KZOpHTXkQqSkFWVgn_oH1Iz297Oq6IAXOeheeTAvXHVabFA';

  static const String _membersEndpoint = '/api/pt_contracts/members';
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_authToken',
  };

  Future<List<PtContract>> getContractMembers([String? status]) async {
    try {
      final queryParams = _buildQueryParams(status);
      final uri = Uri.parse(
        '$baseUrl$_membersEndpoint',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _defaultHeaders);
      _validateResponse(response);

      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => PtContract.fromJson(json)).toList();
    } catch (e) {
      _logError('PT 계약 회원 목록 조회 중 오류 발생', e);
      rethrow;
    }
  }

  Map<String, String> _buildQueryParams(String? status) {
    final params = <String, String>{};
    if (status != null) {
      params['status'] = status;
    }
    return params;
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('API 요청 실패: ${response.statusCode}');
    }
  }

  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      print('$message: $error');
    }
  }
}
