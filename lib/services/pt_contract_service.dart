import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/pt_contract.dart';

class PtContractService {
  static String get baseUrl => Env.getServerURL();
  static final String? _authToken = dotenv.env['TRAINER_TOKEN'];
  static const String _endpoint = '/api/pt_contracts';

  Future<List<PtContract>> getContractMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$_endpoint/members'),
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
        return data.map((json) => PtContract.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '계약 멤버 조회에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in getContractMembers: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<void> updateContractStatus(int ptContractId, String status) async {
    try {
      if (kDebugMode) {
        print('Request status: $status');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl$_endpoint/$ptContractId/status?status=$status'),
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
        throw Exception(error['error'] ?? '계약 상태 업데이트에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in updateContractStatus: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }

  Future<PtContract> updateContract(
    int ptContractId, {
    required DateTime endDate,
    required String memo,
    required int totalCount,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$_endpoint/$ptContractId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'endDate': endDate.millisecondsSinceEpoch ~/ 1000,
          'memo': memo,
          'totalCount': totalCount,
        }),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PtContract.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '계약 정보 수정에 실패했습니다.');
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        print('SocketException: $e');
      }
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in updateContract: $e');
        print('Stack trace: $stackTrace');
      }
      throw Exception('Error: $e');
    }
  }
}
