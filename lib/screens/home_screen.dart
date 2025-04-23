import 'package:flutter/material.dart';

import '../member/screens/member_calendar_screen.dart';
import '../member/screens/member_chat_screen.dart';
import '../member/screens/member_profile_screen.dart';
import '../trainer/screens/calendar_screen.dart';
import '../trainer/screens/pt_contract_screen.dart';
import '../trainer/screens/training_report_screen.dart';
import '../trainer/screens/trainer_chat_screen.dart';
import '../services/auth_service.dart';
import '../widgets/custom_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _userName = "";
  bool _isTrainer = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  
  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userType = await AuthService.getUserType();
      final isTrainer = await AuthService.isTrainer();
      
      setState(() {
        _isTrainer = isTrainer;
        _userName = userType == 'trainer' ? '트레이너' : '회원';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('사용자 정보를 로드하는 중 오류가 발생했습니다.');
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

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('로그아웃 중 오류가 발생했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xfff0f0f0),
      appBar: AppBar(
        title: Text(
          _isTrainer ? '트레이너 홈' : '회원 홈',
          style: const TextStyle(
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
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
                // Welcome message
                Text(
                  '$_userName님 환영합니다',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff3B3C40),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Display appropriate features based on user type
                if (_isTrainer) ...[
                  // Trainer features
                  _buildFeatureCard(
                    icon: Icons.chat,
                    title: '채팅하기',
                    description: '회원과 채팅으로 소통하세요',
                    onTap: () => _navigateToScreen(const TrainerChatScreen()),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.calendar_today,
                    title: '캘린더',
                    description: 'PT 일정을 관리하고 확인하세요',
                    onTap: () => _navigateToScreen(const CalendarScreen()),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.description,
                    title: '계약 관리',
                    description: '회원 계약 정보 관리',
                    onTap: () => _navigateToScreen(const PtContractScreen()),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.assessment,
                    title: '트레이닝 리포트 βeta+',
                    description: '회원의 운동, 식단 보고서를 확인하세요',
                    onTap: () => _navigateToScreen(const TrainingReportScreen()),
                  ),
                ] else ...[
                  // Member features
                  _buildFeatureCard(
                    icon: Icons.chat,
                    title: '채팅하기',
                    description: '24시간 응답 가능한 챗봇',
                    onTap: () => _navigateToScreen(const MemberChatScreen()),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    icon: Icons.calendar_today,
                    title: '캘린더',
                    description: 'PT 일정 관리 및 조회',
                    onTap: () => _navigateToScreen(const MemberCalendarScreen()),
                  ),
                ],
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
