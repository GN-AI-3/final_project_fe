// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/trainer_profile.dart';
import '../services/trainer_profile_service.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/common_bottom_navigation_bar.dart';
import '../screens/calendar_screen.dart';
import '../screens/trainer_chat_screen.dart';
import '../screens/pt_contract_screen.dart';
import '../../screens/home_screen.dart';
import '../../services/auth_service.dart';

class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({super.key});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  final _trainerProfileService = TrainerProfileService();
  TrainerProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _trainerProfileService.getTrainerProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorDialog('프로필을 불러오는데 실패했습니다.');
      }
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('로그아웃 중 오류가 발생했습니다.');
      }
    }
  }

  Future<void> _showRoleSwitchDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('역할 전환'),
        content: const Text('멤버 화면으로 전환하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (result == true) {
      await AuthService.login('user1@test.com', '1234', 'member');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: '오류',
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
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

    if (_profile == null) {
      return const Scaffold(
        body: Center(
          child: Text('프로필을 불러올 수 없습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: 프로필 수정 화면으로 이동
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout();
            },
          ),
        ],
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profile!.profileImage.isNotEmpty
                      ? NetworkImage(_profile!.profileImage)
                      : null,
                  child: _profile!.profileImage.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              _buildProfileSection('기본 정보', [
                _buildProfileItem('이름', _profile!.name),
                _buildProfileItem('이메일', _profile!.email),
                _buildProfileItem('전화번호', _profile!.phone),
              ]),
              const SizedBox(height: 16),
              _buildProfileSection('전문 정보', [
                _buildProfileItem('경력', _profile!.career),
                _buildProfileItem('소개', _profile!.introduction),
              ]),
              const SizedBox(height: 16),
              _buildProfileSection('자격증', _profile!.certifications),
              const SizedBox(height: 16),
              _buildProfileSection('전문 분야', _profile!.specialities),
              const SizedBox(height: 16),
              _buildProfileSection('구독 정보', [
                _buildProfileItem('구독명', _profile!.subscribe.name),
                _buildProfileItem('가격', _profile!.subscribe.price),
                _buildProfileItem('관리 인원', _profile!.subscribe.managementPerson),
                _buildProfileItem('시작일', _formatDate(_profile!.subscribe.startDate)),
                _buildProfileItem('종료일', _formatDate(_profile!.subscribe.endDate)),
                _buildProfileItem('상태', _profile!.subscribe.status),
              ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CommonBottomNavigationBar(
        isTrainer: true,
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              _navigateToScreen(const CalendarScreen());
              break;
            case 1:
              _navigateToScreen(const TrainerChatScreen());
              break;
            case 2:
              _navigateToScreen(const HomeScreen());
              break;
            case 3:
              _navigateToScreen(const PtContractScreen());
              break;
            case 4:
              _showRoleSwitchDialog();
              break;
          }
        },
      ),
    );
  }

  Widget _buildProfileSection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (items is List<String>)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => Chip(
              label: Text(item),
              backgroundColor: const Color(0xff28CAF7).withOpacity(0.1),
            )).toList(),
          )
        else
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: item,
          )).toList(),
      ],
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 