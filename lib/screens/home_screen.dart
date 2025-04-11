import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/fcm_service.dart';
import 'calendar_screen.dart';
import 'chat_screen.dart';
import 'pt_contract_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSendingNotification = false;
  String? _notificationError;

  Future<void> _sendNotification() async {
    if (_isSendingNotification) return;

    setState(() {
      _isSendingNotification = true;
      _notificationError = null;
    });

    try {
      final fcmToken = await FCMService.getFCMToken();
      if (kDebugMode) {
        print('FCM Token: $fcmToken');
      }

      final url = Uri.parse(
        'http://10.0.2.2:8000/api/notification/user/1?fcm_token=$fcmToken',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('알림이 성공적으로 전송되었습니다')));
        }
      } else {
        throw Exception('알림 전송 실패: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _notificationError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('알림 전송 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingNotification = false;
        });
      }
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('테스트'),
        backgroundColor: const Color(0xfff0f0f0),
        elevation: 0,
        foregroundColor: Colors.black87,
        forceMaterialTransparency: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureCard(
                  icon: Icons.chat,
                  title: '채팅하기',
                  description: '회원과 실시간 채팅',
                  onTap: () => _navigateToScreen(const ChatScreen()),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.calendar_today,
                  title: 'PT 스케줄',
                  description: 'PT 일정 관리 및 조회',
                  onTap: () => _navigateToScreen(const CalendarScreen()),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.description,
                  title: 'PT 계약 관리',
                  description: '회원 계약 정보 관리',
                  onTap: () => _navigateToScreen(const PtContractScreen()),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.notifications,
                  title: '알림 보내기',
                  description: '회원에게 알림 전송',
                  onTap: _sendNotification,
                  isLoading: _isSendingNotification,
                  error: _notificationError,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isLoading = false,
    String? error,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: const Color(0xff2746f8)),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (isLoading) ...[
                const SizedBox(height: 8),
                const CircularProgressIndicator(),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
