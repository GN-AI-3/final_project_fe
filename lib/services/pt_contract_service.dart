import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/pt_contract.dart';

class PtContractService {
  static String get baseUrl => Env.getServerURL();
  static const String _authToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzM4NCJ9.eyJwYXNzd29yZCI6IiQyYSQxMCRkNEhjZUNXc1VnL2FUdzQ2am14bDV1SHVwV0h4YjdIeWpTVmUuRzlXSi5LeXdoMkRQVmVyRyIsImNhcmVlciI6Iu2XrOyKpO2KuOugiOydtOuEiCAxMOuFhCIsInBob25lIjoiMDEwMTExMTIyMjIiLCJuYW1lIjoidHJhaW5lcjEiLCJpZCI6MSwidXNlclR5cGUiOiJUUkFJTkVSIiwiY2VydGlmaWNhdGlvbnMiOlsi7IOd7Zmc7Iqk7Y-s7Lig7KeA64-E7IKsIDLquIkiLCLqsbTqsJXsmrTrj5nqtIDrpqzsgqwiXSwiZW1haWwiOiJ0cmFpbmVyQGV4YW1wbGUuY29tIiwic3BlY2lhbGl0aWVzIjpbIuyytOykkeqwkOufiSIsIuq3vOugpeqwle2ZlCIsIuyekOyEuOq1kOyglSJdLCJpYXQiOjE3NDQyNzI1NzYsImV4cCI6MTc0NDYzMjU3Nn0.9vRLk0KMPz6MKAbe3KZOpHTXkQqSkFWVgn_oH1Iz297Oq6IAXOeheeTAvXHVabFA';

  Future<List<PtContract>> getContractMembers([String? status]) async {
    final queryParams = status != null ? {'status': status} : null;
    final uri = Uri.parse('$baseUrl/api/pt_contracts/members').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => PtContract.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load contract members: ${response.statusCode}');
    }
  }
} 