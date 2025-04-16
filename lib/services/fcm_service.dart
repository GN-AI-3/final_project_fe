import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String fcmTokenKey = 'fcm_token';

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    '중요 알림',
    description: '중요한 알림을 위한 채널',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    // 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 알림 권한 요청
    await FirebaseMessaging.instance.requestPermission();

    // flutter_local_notifications 초기화
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // 알림 채널 등록
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 포그라운드 메시지 수신 리스너
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // FCM 토큰 가져오기 및 저장
    await refreshAndSaveFCMToken();

    // 토큰 갱신 이벤트 리스너 등록
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      saveFCMToken(token);
      if (kDebugMode) {
        print('FCM 토큰 갱신됨: $token');
      }
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    if (kDebugMode) {
      print('백그라운드 메시지 수신: ${message.notification?.title}');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('포그라운드 메시지 수신: ${message.data}');
    }

    final notification = message.notification;
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title ?? '',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  static Future<String?> getFCMToken() async {
    try {
      // 먼저 저장된 토큰을 확인
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(fcmTokenKey);

      // 저장된 토큰이 있으면 반환
      if (savedToken != null && savedToken.isNotEmpty) {
        return savedToken;
      }

      // 없으면 새로 발급받아 저장 후 반환
      return await refreshAndSaveFCMToken();
    } catch (e) {
      if (kDebugMode) {
        print('FCM 토큰 가져오기 실패: $e');
      }
      return null;
    }
  }

  static Future<String?> refreshAndSaveFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await saveFCMToken(token);
        if (kDebugMode) {
          print('FCM 토큰 발급 및 저장 완료: $token');
        }
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('FCM 토큰 발급 및 저장 실패: $e');
      }
      return null;
    }
  }

  static Future<void> saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(fcmTokenKey, token);
    } catch (e) {
      if (kDebugMode) {
        print('FCM 토큰 저장 실패: $e');
      }
    }
  }
}
