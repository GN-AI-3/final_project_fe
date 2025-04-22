
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Server environment configuration
class Env {
  /// Get the base server URL from environment variables
  static String getServerURL() {
    // FETCH_SERVER_URL2 설정을 직접 사용
    String? serverUrl = dotenv.env['FETCH_SERVER_URL2'];
    
    if (serverUrl == null || serverUrl.isEmpty) {
      // Log warning if no URL is configured
      if (kDebugMode) {
        print('서버 URL이 설정되지 않았습니다. .env 파일의 FETCH_SERVER_URL2를 확인하세요.');
      }
      
      throw Exception('서버 URL이 설정되지 않았습니다. .env 파일의 FETCH_SERVER_URL2를 확인하세요.');
    }
    
    return serverUrl;
  }
  
  /// Get API key for external services
  static String? getApiKey(String key) {
    return dotenv.env[key];
  }
}
