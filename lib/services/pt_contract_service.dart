import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/pt_contract.dart';

class PtContractService {
  static String get baseUrl => Env.getServerURL();
  static const String _authToken =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwYXNzd29yZCI6IiQyYSQxMCRkNEhjZUNXc1VnL2FUdzQ2am14bDV1SHVwV0h4YjdIeWpTVmUuRzlXSi5LeXdoMkRQVmVyRyIsImNhcmVlciI6Iu2XrOyKpO2KuOugiOydtOuEiCAxMOuFhCIsInBob25lIjoiMDEwMTExMTIyMjIiLCJuYW1lIjoidHJhaW5lcjEiLCJpZCI6MSwidXNlclR5cGUiOiJUUkFJTkVSIiwiY2VydGlmaWNhdGlvbnMiOlsi7IOd7Zmc7Iqk7Y-s7Lig7KeA64-E7IKsIDLquIkiLCLqsbTqsJXsmrTrj5nqtIDrpqzsgqwiXSwiZW1haWwiOiJ0cmFpbmVyQGV4YW1wbGUuY29tIiwic3BlY2lhbGl0aWVzIjpbIuyytOykkeqwkOufiSIsIuq3vOugpeqwle2ZlCIsIuyekOyEuOq1kOyglSJdLCJpYXQiOjE3NDQ2MDIzNjQsImV4cCI6MTc0NDk2MjM2NH0.EEfJFA_2oQZukZLRk8ymo6spR1I4SFh6-zh3jN0w9CqKBDuTgtZ_gitTmp7BJzYS';

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

      final contracts =
          jsonList.map((json) {
            return PtContract.fromJson(json);
          }).toList();

      return contracts;
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

    try {
      final json = jsonDecode(response.body);
      if (json is! List) {
        throw Exception('잘못된 응답 형식: List가 아닙니다');
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

  Future<PtContract> updateContractStatus(
    int contractId, {
    required String status,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/pt_contracts/$contractId/status',
    ).replace(queryParameters: {'status': status});

    final response = await http.patch(uri, headers: _defaultHeaders);

    if (response.statusCode == 200) {
      return PtContract.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update contract status: ${response.body}');
    }
  }
}
