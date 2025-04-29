import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:gymggun/services/auth_service.dart';

class FCMService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String fcmTokenKey = 'fcm_token';

  // 알림 채널 ID
  static const String channelId = 'high_importance_channel';
  static const String channelName = '중요 알림';
  static const String channelDescription = '중요한 알림을 위한 채널';
  
  // 추가 채널 (그룹화 알림용)
  static const String groupChannelId = 'grouped_channel';
  static const String groupChannelName = '그룹 알림';
  static const String groupChannelDescription = '여러 알림을 그룹화하는 채널';
  
  // 알림 그룹 키
  static const String notificationGroupKey = 'com.example.gymggun.NOTIFICATION_GROUP';

  // 알림 채널 정의
  static final channels = <AndroidNotificationChannel>[
    const AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.blue,
    ),
    const AndroidNotificationChannel(
      groupChannelId,
      groupChannelName,
      description: groupChannelDescription,
      importance: Importance.high,
    ),
  ];

  // 다양한 스타일의 알림 타입
  static const String notificationTypeDefault = 'default';
  static const String notificationTypeImage = 'image';
  static const String notificationTypeChat = 'chat';
  static const String notificationTypeProgress = 'progress';
  static const String notificationTypeMedia = 'media';
  static const String notificationTypePtSchedule = 'pt_schedule'; // PT 일정 알림 타입 추가
  
  // 미디어 컨트롤 액션 ID
  static const String _actionPause = 'pause';
  static const String _actionResume = 'resume';
  static const String _actionStop = 'stop';

  // 정적 네비게이터 키 추가
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    // FCM 디버그 로그 활성화
    if (kDebugMode) {
      print('FCM 서비스 초기화 시작');
    }
    
    // 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 알림 권한 요청
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (kDebugMode) {
      print('FCM 알림 권한 상태: ${settings.authorizationStatus}');
    }

    // flutter_local_notifications 초기화
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    
    // 알림 초기화 (알림 클릭 이벤트 처리 포함)
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알림 탭 처리
        if (kDebugMode) {
          print('알림 탭: ${response.payload}');
        }
        _handleNotificationResponse(response);
      },
    );

    // 알림 채널들 등록
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidPlugin != null) {
      for (var channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
        if (kDebugMode) {
          print('채널 생성 완료: ${channel.id}');
        }
      }
    }

    // 포그라운드 메시지 수신 리스너
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('포그라운드 메시지 수신: ${message.data}');
        print('알림 제목: ${message.notification?.title}');
        print('알림 내용: ${message.notification?.body}');
      }
      
      // 즉시 알림 표시
      _handleForegroundMessage(message);
    });

    // FCM 토큰 가져오기 및 저장
    await refreshAndSaveFCMToken();

    // 토큰 갱신 이벤트 리스너 등록
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      saveFCMToken(token);
      if (kDebugMode) {
        print('FCM 토큰 갱신됨: $token');
      }
    });
    
    if (kDebugMode) {
      print('FCM 서비스 초기화 완료');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    if (kDebugMode) {
      print('백그라운드 메시지 수신: ${message.notification?.title}');
    }
    
    // 앱이 백그라운드에서도 알림을 표시하기 위해 직접 알림 표시
    final notification = message.notification;
    if (notification != null) {
      // PT 일정 알림인지 확인
      String? payload = null;
      String title = notification.title ?? '새 알림';
      
      // 제목에 'PT 일정'이 포함되어 있으면 PT 일정 알림으로 처리
      if (title.contains('PT 일정') || title.contains('PT 회원 명단')) {
        payload = 'pt_schedule';
      }
      
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        title,
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channels[0].id,
            channels[0].name,
            channelDescription: channels[0].description,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: payload, // 페이로드 추가
      );
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('포그라운드 메시지 처리 시작');
    }

    // 직접 알림 표시 (먼저 기본 알림부터 표시)
    final notification = message.notification;
    if (notification != null) {
      // PT 일정 알림인지 확인
      String? payload = null;
      String title = notification.title ?? '새 알림';
      
      // 제목에 'PT 일정'이 포함되어 있으면 PT 일정 알림으로 처리
      if (title.contains('PT 일정') || title.contains('PT 회원 명단')) {
        payload = 'pt_schedule';
      }
      
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        title,
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channels[0].id,
            channels[0].name,
            channelDescription: channels[0].description,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: payload, // 페이로드 추가
      );
      
      // 추가적으로 커스텀 알림 표시 시도
      try {
        showCustomNotification(message);
      } catch (e) {
        if (kDebugMode) {
          print('커스텀 알림 표시 오류: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('알림 데이터가 없는 메시지: ${message.data}');
      }
    }
  }

  static void _handleNotificationResponse(NotificationResponse response) async {
    if (kDebugMode) {
      print('알림 탭 감지: ${response.payload}');
      print('NavigatorKey 상태: ${navigatorKey.currentState != null}');
    }
    
    // 알림 페이로드 확인
    final payload = response.payload;
    
    if (payload == null || payload.isEmpty) {
      if (kDebugMode) {
        print('페이로드가 없는 알림입니다.');
      }
      return;
    }
    
    // 알림 유형에 따라 처리
    switch (payload) {
      case 'pt_schedule':
        await _handlePtScheduleNotification();
        break;
      case 'chat_notification':
        if (kDebugMode) {
          print('채팅 알림 탭 - 채팅 화면으로 이동 예정');
        }
        // TODO: 채팅 화면으로 이동 로직 구현
        break;
      case 'image_notification':
      case 'media_notification':
      case 'progress_notification':
      case 'default_notification':
      default:
        if (kDebugMode) {
          print('일반 알림 탭: $payload');
        }
        // 일반 알림은 현재 특별한 처리 없음
        break;
    }
  }
  
  // PT 일정 알림 처리 메소드 분리
  static Future<void> _handlePtScheduleNotification() async {
    if (kDebugMode) {
      print('PT 일정 알림 탭 - 캘린더 화면으로 이동 시도');
    }
    
    // 사용자 유형 확인 (AuthService 사용)
    try {
      final isTrainer = await AuthService.isTrainer();
      
      if (kDebugMode) {
        print('사용자 유형: ${isTrainer ? "트레이너" : "회원"}');
        print('네비게이터 키 사용 가능: ${navigatorKey.currentState != null}');
      }
      
      // 사용자 유형에 따라 적절한 캘린더 화면으로 이동
      if (navigatorKey.currentState != null) {
        if (isTrainer) {
          if (kDebugMode) {
            print('트레이너 캘린더 화면으로 이동 시작: /trainer_calendar');
          }
          navigatorKey.currentState!.pushNamed('/trainer_calendar');
          if (kDebugMode) {
            print('트레이너 캘린더 화면으로 이동 완료');
          }
        } else {
          if (kDebugMode) {
            print('회원 캘린더 화면으로 이동 시작: /member_calendar');
          }
          navigatorKey.currentState!.pushNamed('/member_calendar');
          if (kDebugMode) {
            print('회원 캘린더 화면으로 이동 완료');
          }
        }
      } else {
        if (kDebugMode) {
          print('네비게이터 상태가 null입니다. 이동 실패.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('캘린더 화면 이동 중 오류 발생: $e');
      }
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

  // FCM 메시지 포맷에 기반한 커스텀 알림 표시

  static Future<void> showCustomNotification(RemoteMessage message) async {
    if (kDebugMode) {
      print('커스텀 알림 표시 시작');
    }
    
    final notification = message.notification;
    final data = message.data;
    
    if (notification == null) {
      if (kDebugMode) {
        print('알림 데이터 없음, 처리 중단');
      }
      return;
    }
    
    int id = notification.hashCode;
    String title = notification.title ?? '새 알림';
    String body = notification.body ?? '';
    
    // PT 일정 알림인 경우 바로 테스트 메소드로 처리
    if (title.contains('PT 일정') || title.contains('PT 회원 명단')) {
      try {
        // 스타일 정보 생성 - 확장 가능한 텍스트 형식
        final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
          summaryText: '펼쳐서 전체 내용 보기',
          htmlFormatSummaryText: false,
        );

        await flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channels[0].id,
              channels[0].name,
              channelDescription: channels[0].description,
              importance: Importance.max,
              priority: Priority.high,
              styleInformation: bigTextStyleInformation,
              ongoing: false,
              autoCancel: true,
              showWhen: true,
              visibility: NotificationVisibility.public,
              playSound: true,
              fullScreenIntent: true,
              largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          payload: 'pt_schedule', // 페이로드 추가
        );
        
        if (kDebugMode) {
          print('PT 일정 알림 표시 성공');
        }
        return;
      } catch (e) {
        if (kDebugMode) {
          print('PT 일정 알림 표시 실패: $e');
        }
        // 실패 시 기본 알림으로 대체
        await _showDefaultNotification(id, title, body);
        return;
      }
    }
    
    // 나머지 알림 타입 처리
    // 알림 타입 확인 (PT 일정 알림 특별 처리)
    String? notificationType;
    
    // 제목에 "PT 일정" 또는 "PT 회원 명단"이 포함되어 있으면 PT 일정 알림으로 처리
    if (title.contains('PT 일정') || title.contains('PT 회원 명단')) {
      notificationType = notificationTypePtSchedule;
      if (kDebugMode) {
        print('PT 일정 알림 감지: $title');
      }
    } else {
      notificationType = data['type'] ?? notificationTypeDefault;
      if (kDebugMode) {
        print('일반 알림 타입: $notificationType');
      }
    }
    
    try {
      // 알림 타입에 따라 다른 스타일 적용
      switch (notificationType) {
        case notificationTypePtSchedule:
          await _showPtScheduleNotification(id, title, body);
          break;
        case notificationTypeImage:
          if (data.containsKey('image_url')) {
            await _showImageNotification(id, title, body);
          } else {
            await _showDefaultNotification(id, title, body);
          }
          break;
        case notificationTypeChat:
          await _showChatNotification(id, title, body);
          break;
        case notificationTypeProgress:
          await _showProgressNotification(id, title, body);
          break;
        case notificationTypeMedia:
          await _showMediaNotification(id, title, body);
          break;
        default:
          await _showDefaultNotification(id, title, body);
      }
      
      if (kDebugMode) {
        print('알림 표시 완료: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('알림 표시 중 오류: $e');
      }
      // 오류 발생 시 기본 알림으로 폴백
      await _showDefaultNotification(id, title, body);
    }
  }
  
  // PT 일정 알림 스타일
  static Future<void> _showPtScheduleNotification(int id, String title, String body) async {
    // 알림 스타일 설정 (BigTextStyle 사용)
    final bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
      contentTitle: title,
      htmlFormatContentTitle: false,
      summaryText: '펼쳐서 전체 일정 보기',
      htmlFormatSummaryText: false,
    );
    
    // 알림 레이아웃 설정 
    final androidDetails = AndroidNotificationDetails(
      channels[0].id, 
      channels[0].name,
      channelDescription: channels[0].description,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigTextStyleInformation,
      icon: '@mipmap/ic_launcher',
      groupKey: 'pt_schedule',
      autoCancel: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      showWhen: true,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'pt_schedule',
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'ptScheduleCategory',
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: 'pt_schedule',
    );
  }

  // 테스트용 알림 전송 메소드
  static Future<void> showTestNotification({String type = notificationTypeDefault}) async {
    final int id = Random().nextInt(1000);
    String title = '테스트 알림';
    String body = '이것은 테스트 알림입니다.';
    
    try {
      if (kDebugMode) {
        print('테스트 알림 시작 - 타입: $type');
      }
      
      switch (type) {
        case notificationTypePtSchedule:
          await _showPtScheduleTestNotification();
          break;
        default:
          await _showDefaultNotification(id, title, body);
      }
      
      if (kDebugMode) {
        print('테스트 알림 성공');
      }
    } catch (e) {
      if (kDebugMode) {
        print('테스트 알림 실패: $e');
      }
      // 실패 시 가장 기본적인 알림 시도
      try {
        await flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'basic_channel',
              '기본 알림',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      } catch (e2) {
        if (kDebugMode) {
          print('최후의 알림 표시 실패: $e2');
        }
      }
    }
  }
  
  // PT 일정 알림 테스트용 메소드
  static Future<void> _showPtScheduleTestNotification() async {
    try {
      final int id = Random().nextInt(1000);
      const String title = "📋 내일 PT 회원 명단";
      const String body = """2023년 05월 15일 PT 일정 명단입니다.

• 09:00~10:00 : 김민수
• 10:30~11:30 : 이지은
• 13:00~14:00 : 박준혁
• 15:30~16:30 : 최유진
• 17:00~18:00 : 정다은""";

      // 스타일 정보 생성 - 확장 가능한 텍스트 형식
      const BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        htmlFormatContentTitle: false,
        summaryText: '펼쳐서 전체 일정 보기',
        htmlFormatSummaryText: false,
      );

      // 간단한 방식으로 먼저 시도
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channels[0].id,
            channels[0].name,
            channelDescription: channels[0].description,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: bigTextStyleInformation,
            ongoing: false,
            autoCancel: true,
            showWhen: true,
            visibility: NotificationVisibility.public,
            playSound: true,
            fullScreenIntent: true,
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
      
      if (kDebugMode) {
        print('PT 일정 테스트 알림 성공');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PT 일정 테스트 알림 실패: $e');
      }
    }
  }

  // 기본 알림
  static Future<void> _showDefaultNotification(int id, String title, String body) async {
    try {
      // 알림 내용이 길 경우를 대비해 BigTextStyle 적용
      final bigTextStyleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        htmlFormatContentTitle: false,
        summaryText: '펼쳐서 더 보기',
        htmlFormatSummaryText: false,
      );
      
      final androidDetails = AndroidNotificationDetails(
        channels[0].id,
        channels[0].name,
        channelDescription: channels[0].description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: bigTextStyleInformation,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        visibility: NotificationVisibility.public,
        autoCancel: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      await flutterLocalNotificationsPlugin.show(
        id, 
        title, 
        body, 
        details,
        payload: 'default_notification', // 기본 페이로드 추가
      );
      
      if (kDebugMode) {
        print('기본 알림 표시 성공: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('기본 알림 표시 실패: $e');
      }
    }
  }
  
  // 채팅 스타일 알림
  static Future<void> _showChatNotification(int id, String title, String body) async {
    // 메시지 스타일 알림 대신 BigTextStyle 사용
    final bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
      contentTitle: title,
      htmlFormatContentTitle: false,
      summaryText: '새로운 메시지',
      htmlFormatSummaryText: false,
    );
    
    final androidDetails = AndroidNotificationDetails(
      channels[0].id,
      channels[0].name,
      channelDescription: channels[0].description,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: bigTextStyleInformation,
      category: AndroidNotificationCategory.message,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      visibility: NotificationVisibility.public,
      autoCancel: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'chat-thread',
    );
    
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await flutterLocalNotificationsPlugin.show(
      id, 
      title, 
      body, 
      details,
      payload: 'chat_notification',
    );
  }
  
  // 이미지가 포함된 알림
  static Future<void> _showImageNotification(int id, String title, String body) async {
    // 이미지 스타일 정보 설정
    final bigPictureStyleInformation = BigPictureStyleInformation(
      const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      contentTitle: title,
      summaryText: body,
      hideExpandedLargeIcon: false,
    );
    
    final androidDetails = AndroidNotificationDetails(
      channels[0].id,
      channels[0].name,
      channelDescription: channels[0].description,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: bigPictureStyleInformation,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await flutterLocalNotificationsPlugin.show(
      id, 
      title, 
      body, 
      details,
      payload: 'image_notification',
    );
  }
  
  // 미디어 컨트롤이 있는 알림
  static Future<void> _showMediaNotification(int id, String title, String body) async {
    final List<AndroidNotificationAction> actions = [
      const AndroidNotificationAction(
        _actionPause,
        '일시정지',
        icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        showsUserInterface: true,
      ),
      const AndroidNotificationAction(
        _actionResume,
        '재생',
        icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ),
      const AndroidNotificationAction(
        _actionStop,
        '중지',
        icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      ),
    ];
    
    final androidDetails = AndroidNotificationDetails(
      channels[0].id,
      channels[0].name,
      channelDescription: channels[0].description,
      importance: Importance.high,
      priority: Priority.high,
      actions: actions,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      category: AndroidNotificationCategory.transport,
      showWhen: false,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );
    
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await flutterLocalNotificationsPlugin.show(
      id, 
      title, 
      body, 
      details,
      payload: 'media_notification',
    );
  }
  
  // 진행 상태를 보여주는 알림
  static Future<void> _showProgressNotification(int id, String title, String body) async {
    // 진행률 표시 알림
    final androidDetails = AndroidNotificationDetails(
      channels[0].id,
      channels[0].name,
      channelDescription: channels[0].description,
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: 50, // 기본 50% 표시
      channelShowBadge: false,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );
    
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await flutterLocalNotificationsPlugin.show(
      id, 
      title, 
      body, 
      details,
      payload: 'progress_notification',
    );
  }
}
