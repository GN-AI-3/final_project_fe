import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../member/screens/member_calendar_screen.dart';
import '../member/screens/member_chat_screen.dart';
import '../member/screens/member_profile_screen.dart';
import '../trainer/screens/calendar_screen.dart';
import '../trainer/screens/pt_contract_screen.dart';
import '../trainer/screens/trainer_chat_screen.dart';
import '../widgets/custom_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xff2746f8),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xff2746f8),
          tabs: const [
            Tab(text: '회원'),
            Tab(text: '트레이너'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 회원 탭 화면
          _buildMemberTab(),
          // 트레이너 탭 화면
          _buildTrainerTab(),
        ],
      ),
    );
  }
  
  // 회원 탭 내용
  Widget _buildMemberTab() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
          ),
        ),
      ),
    );
  }
  
  // 트레이너 탭 내용
  Widget _buildTrainerTab() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureCard(
                icon: Icons.chat,
                title: '채팅하기',
                description: '24시간 응답 가능한 챗봇',
                onTap: () => _navigateToScreen(const TrainerChatScreen()),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                icon: Icons.calendar_today,
                title: '캘린더',
                description: 'PT 일정 관리 및 조회',
                onTap: () => _navigateToScreen(const CalendarScreen()),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                icon: Icons.description,
                title: '계약 관리',
                description: '회원 계약 정보 관리',
                onTap: () => _navigateToScreen(const PtContractScreen()),
              ),
            ],
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
