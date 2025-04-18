import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/env.dart';
import '../models/pt_log.dart';

class PtLogsService {
  static final String _baseUrl = Env.getServerURL();
  static const String _endpoint = '/api/trainer/chat/pt_log';
  static const String _authToken =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwYXNzd29yZCI6IiQyYSQxMCRkNEhjZUNXc1VnL2FUdzQ2am14bDV1SHVwV0h4YjdIeWpTVmUuRzlXSi5LeXdoMkRQVmVyRyIsImNhcmVlciI6Iu2XrOyKpO2KuOugiOydtOuEiCAxMOuFhCIsInBob25lIjoiMDEwMTExMTIyMjIiLCJuYW1lIjoidHJhaW5lcjEiLCJpZCI6MSwidXNlclR5cGUiOiJUUkFJTkVSIiwiY2VydGlmaWNhdGlvbnMiOlsi7IOd7Zmc7Iqk7Y-s7Lig7KeA64-E7IKsIDLquIkiLCLqsbTqsJXsmrTrj5nqtIDrpqzsgqwiXSwiZW1haWwiOiJ0cmFpbmVyQGV4YW1wbGUuY29tIiwic3BlY2lhbGl0aWVzIjpbIuyytOykkeqwkOufiSIsIuq3vOugpeqwle2ZlCIsIuyekOyEuOq1kOyglSJdLCJpYXQiOjE3NDQ2MDIzNjQsImV4cCI6MTc0NDk2MjM2NH0.EEfJFA_2oQZukZLRk8ymo6spR1I4SFh6-zh3jN0w9CqKBDuTgtZ_gitTmp7BJzYS';

  Future<PtLog> sendMessage(
    String message,
    int ptScheduleId,
  ) async {
    try {
      if (kDebugMode) {
        print('Sending message to endpoint: $_baseUrl$_endpoint');
        print('Message: $message');
        print('PT Schedule ID: $ptScheduleId');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl$_endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: json.encode({
          'message': message,
          'ptScheduleId': ptScheduleId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PtLog.fromJson(data);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in sendMessage: $e');
      }
      rethrow;
    }
  }
}
