import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/fcm_service.dart';
import '../widgets/custom_dialog.dart';
import 'calendar_screen.dart';
import 'chat_screen.dart';
import 'member_calendar_screen.dart';
import 'member_profile_screen.dart';
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
      if (fcmToken == null) return;

      final url = Uri.parse('http://localhost:8080/api/notification/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: '''
        {
          "token": "$fcmToken",
          "title": "테스트 알림",
          "body": "이것은 테스트 알림입니다."
        }
        ''',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send notification');
      }

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => CustomDialog(
                title: '알림',
                content: const Text('알림이 성공적으로 전송되었습니다'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      setState(() {
        _notificationError = e.toString();
      });
      if (mounted) {
        _showErrorDialog(e.toString());
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

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialog(
            title: '오류',
            content: Text(error),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f0f0),
      appBar: AppBar(
        title: const Text(
          '홈',
          style: TextStyle(
            color: Color(0xff3B3C40),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xfff0f0f0),
        foregroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff3B3C40)),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MemberProfileScreen(),
                ),
              );
            },
            tooltip: '프로필',
          ),
        ],
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
                  title: '채팅하기(회원용)',
                  description: '24시간 응답 가능한 챗봇',
                  onTap: () => _navigateToScreen(const ChatScreen()),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.calendar_today,
                  title: '캘린더(트레이너용)',
                  description: 'PT 일정 관리 및 조회',
                  onTap: () => _navigateToScreen(const CalendarScreen()),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.calendar_today,
                  title: '캘린더(회원용)',
                  description: 'PT 일정 관리 및 조회',
                  onTap: () => _navigateToScreen(const MemberCalendarScreen()),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.description,
                  title: '계약 관리(트레이너용)',
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
        child: Container(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: const Color(0xff2746f8)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              if (isLoading) ...[
                const SizedBox(height: 4),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 4),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
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
