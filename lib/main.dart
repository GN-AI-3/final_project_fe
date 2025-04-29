import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:gymggun/trainer/screens/calendar_screen.dart';
import 'package:gymggun/member/screens/member_calendar_screen.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/fcm_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FCMService.initialize();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: FCMService.navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        SfGlobalLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('zh'),
        Locale('ar'),
        Locale('ja'),
      ],
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      title: 'GYMGGUN',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xff2746f8),
        ),
        scaffoldBackgroundColor: const Color(0xfff0f0f0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff0f0f0),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xfff0f0f0),
            foregroundColor: Colors.black,
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: const TextStyle(color: Colors.black),
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0xfff0f0f0)),
          ),
        ),
      ),
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _isLoggedIn
              ? const HomeScreen()
              : const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/trainer_calendar': (context) => const CalendarScreen(),
        '/member_calendar': (context) => const MemberCalendarScreen(),
      },
    );
  }
}
