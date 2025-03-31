import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;  // 서버 호출 용

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  '중요 알림',
  description: '중요한 알림을 위한 채널',
  importance: Importance.high,
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('백그라운드 메시지 수신: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 알림 권한 요청(안드로이드 13+ 등)
  await FirebaseMessaging.instance.requestPermission();

  // flutter_local_notifications 초기화
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 알림 채널 등록
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 포그라운드 메시지 수신 리스너 → 직접 알림 표시
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('포그라운드 메시지 수신: ${message.data}');

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
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('FCM Test')),
        body: const Center(child: APITestWidget()),
      ),
    );
  }
}

class APITestWidget extends StatefulWidget {
  const APITestWidget({Key? key}) : super(key: key);

  @override
  State<APITestWidget> createState() => _APITestWidgetState();
}

class _APITestWidgetState extends State<APITestWidget> {
  String _status = '대기 중';

  Future<void> _callServer() async {
    try {
      // FCM 토큰 가져오기
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $fcmToken');

      // 서버 요청에 FCM 토큰 추가
      final url = Uri.parse('http://10.0.2.2:8000/api/notification/user/1?fcm_token=$fcmToken');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _status = '알림 전송 요청 성공(서버 응답 200)';
        });
      } else {
        setState(() {
          _status = '오류: ${response.statusCode} => ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _status = '예외 발생: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(_status),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _callServer,
          child: const Text('Send Custom Notification'),
        ),
      ],
    );
  }
}
