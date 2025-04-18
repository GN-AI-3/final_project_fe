import 'dart:convert';

class JwtDecoder {
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      return payloadMap;
    } catch (e) {
      return null;
    }
  }

  static int? getMemberId(String token) {
    final decoded = decode(token);
    if (decoded == null) return null;
    return decoded['id'] as int?;
  }
} 