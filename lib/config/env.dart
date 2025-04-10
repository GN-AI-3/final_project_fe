import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String getServerURL() {
    if (Platform.isAndroid) {
      // Android 에뮬레이터인 경우
      if (Platform.environment.containsKey('ANDROID_EMU')) {
        return dotenv.env['FETCH_SERVER_URL']!;
      }
      // 실제 Android 기기인 경우
      return dotenv.env['FETCH_SERVER_URL2']!;
    }
    // iOS나 다른 플랫폼의 경우
    return dotenv.env['FETCH_SERVER_URL2']!;
  }
} 