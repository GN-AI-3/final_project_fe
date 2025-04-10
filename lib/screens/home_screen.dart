import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'calendar_screen.dart';
import 'pt_contract_screen.dart';
import '../services/fcm_service.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Future<void> _sendNotification() async {
    try {
      final fcmToken = await FCMService.getFCMToken();
      if (kDebugMode) {
        print('FCM Token: $fcmToken');
      }

      final url = Uri.parse('http://10.0.2.2:8000/api/notification/user/1?fcm_token=$fcmToken');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
        });
      } else {
        setState(() {
        });
      }
    } catch (e) {
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('테스트 화면'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('채팅하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('PT 스케줄'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PtContractScreen()),
                );
              },
              icon: const Icon(Icons.description),
              label: const Text('PT 계약 관리'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _sendNotification,
              icon: const Icon(Icons.notifications),
              label: const Text('알림 보내기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 