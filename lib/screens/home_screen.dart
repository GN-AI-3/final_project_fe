// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../member/screens/member_calendar_screen.dart';
import '../member/screens/member_chat_screen.dart';
import '../models/meeting.dart';
import '../services/auth_service.dart';
import '../trainer/screens/calendar_screen.dart';
import '../trainer/screens/pt_contract_screen.dart';
import '../trainer/screens/trainer_chat_screen.dart';
import '../trainer/services/schedule_service.dart' as trainer_schedule_service;
import '../widgets/common_bottom_navigation_bar.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_toast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _userName = "";
  bool _isTrainer = false;
  List<Meeting> _todayMeetings = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserInfo();
    await _loadTodayMeetings();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userInfo = await AuthService.getUserInfo();
      final isTrainer = await AuthService.isTrainer();

      setState(() {
        _isTrainer = isTrainer;
        _userName = userInfo?['name'] ?? (isTrainer ? '트레이너' : '회원');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('사용자 정보를 로드하는 중 오류가 발생했습니다.');
    }
  }

  Future<void> _loadTodayMeetings() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      List<Meeting> meetings;
      if (_isTrainer) {
        final service = trainer_schedule_service.TrainerScheduleService();
        final schedules = await service.getSchedules(
          startTime: startOfDay,
          endTime: endOfDay,
          status: 'SCHEDULED',
        );
        meetings =
            schedules
                .map(
                  (schedule) => Meeting(
                    '${schedule.memberName} 회원님 (${schedule.currentPtCount}회차)',
                    schedule.startTime,
                    schedule.endTime,
                    const Color(0xff28CAF7),
                    false,
                  ),
                )
                .toList();
      } else {
        final service = trainer_schedule_service.MemberScheduleService();
        final schedules = await service.getSchedules(
          startTime: startOfDay,
          endTime: endOfDay,
          status: 'SCHEDULED',
        );
        meetings =
            schedules
                .map(
                  (schedule) => Meeting(
                    schedule.trainerName,
                    schedule.startTime,
                    schedule.endTime,
                    const Color(0xff28CAF7),
                    false,
                  ),
                )
                .toList();
      }

      setState(() {
        _todayMeetings = meetings;
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog('오늘의 일정을 불러오는 중 오류가 발생했습니다.');
      }
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _showRoleSwitchDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('역할 전환'),
        content: const Text('다른 역할의 화면으로 전환하시겠습니까?'),
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
      if (_isTrainer) {
        await AuthService.login('user1@test.com', '1234', 'member');
      } else {
        await AuthService.login('trainer@example.com', '1234', 'trainer');
      }
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialog(
            title: '앗!',
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

  Widget _buildTodayScheduleCard() {
    if (_todayMeetings.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff28CAF7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color(0xff28CAF7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '오늘의 남은 일정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 47),
              const Center(
                child: Text(
                  '오늘의 일정을 모두 소화하셨어요!',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const SizedBox(height: 47),
            ],
          ),
        ),
      );
    }

    // 최대 표시할 일정 수
    const int maxVisibleMeetings = 1;
    final bool hasMoreMeetings = _todayMeetings.length > maxVisibleMeetings;
    final visibleMeetings =
        _isExpanded || !hasMoreMeetings
            ? _todayMeetings
            : _todayMeetings.sublist(0, maxVisibleMeetings);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff28CAF7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xff28CAF7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '오늘의 남은 일정',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed:
                      () => _navigateToScreen(
                        _isTrainer
                            ? const CalendarScreen()
                            : const MemberCalendarScreen(),
                      ),
                  child: const Text('전체 일정 보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...visibleMeetings
                .map(
                  (meeting) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: meeting.background.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: meeting.background,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meeting.eventName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('HH:mm').format(meeting.from)} - ${DateFormat('HH:mm').format(meeting.to)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            if (hasMoreMeetings) ...[
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xff2746f8),
                  ),
                  label: Text(
                    _isExpanded
                        ? '접기'
                        : '펼치기 (${_todayMeetings.length - maxVisibleMeetings}건)',
                    style: const TextStyle(
                      color: Color(0xff2746f8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xfff0f0f0),
      body: RefreshIndicator(
        onRefresh: _loadTodayMeetings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                const SizedBox(height: 72),
                Text(
                  '$_userName${_isTrainer ? ' 트레이너' : ' 회원'}님 환영합니다 :)',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff3B3C40),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '오늘도 건강한 하루 되세요!',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),

                // Today's schedule
                _buildTodayScheduleCard(),
                const SizedBox(height: 16),

                // Statistics card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xff2746f8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.analytics,
                                color: Color(0xff2746f8),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                '통계',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(color: Colors.grey[200], thickness: 1),
                        const SizedBox(height: 8),
                        if (_isTrainer) ...[
                          _buildStatItem(
                            icon: Icons.people,
                            title: '누적 회원',
                            value: '12명',
                            color: const Color(0xff2746f8),
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            icon: Icons.description,
                            title: '진행중인 회원',
                            value: '5명',
                            color: const Color(0xff7A8DF7),
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            icon: Icons.people_outline,
                            title: '이번 달 신규 회원',
                            value: '3명',
                            color: const Color(0xffF728A8),
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            icon: Icons.calendar_today,
                            title: '이번 달 PT 진행 횟수',
                            value: '48회',
                            color: const Color(0xff28CAF7),
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            icon: Icons.attach_money,
                            title: '이번 달 수입',
                            value: '???만 원',
                            color: const Color(0xffF72828),
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            icon: Icons.star,
                            title: '평균 만족도',
                            value: '4.8점',
                            color: const Color(0xffF7B728),
                          ),
                        ] else ...[
                          _buildStatItem(
                            icon: Icons.fitness_center,
                            title: '이번 달 운동',
                            value: '8회',
                            color: const Color(0xff2746f8),
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            icon: Icons.timer,
                            title: '총 운동 시간',
                            value: '16시간',
                            color: const Color(0xff28CAF7),
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            icon: Icons.description,
                            title: '남은 PT',
                            value: '12회',
                            color: const Color(0xff7A8DF7),
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            icon: Icons.trending_up,
                            title: '체중 변화',
                            value: '-2.5kg',
                            color: const Color(0xff8F28F7),
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            icon: Icons.speed,
                            title: '운동 강도',
                            value: '중간',
                            color: const Color(0xffF72828),
                          ),
                          const SizedBox(height: 16),
                          _buildStatItem(
                            icon: Icons.emoji_events,
                            title: '달성률',
                            value: '85%',
                            color: const Color(0xffF7B728),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CommonBottomNavigationBar(
        isTrainer: _isTrainer,
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              _navigateToScreen(
                _isTrainer
                    ? const CalendarScreen()
                    : const MemberCalendarScreen(),
              );
              break;
            case 1:
              _navigateToScreen(
                _isTrainer
                    ? const TrainerChatScreen()
                    : const MemberChatScreen(),
              );
              break;
            case 2:
              // 홈 - 현재 화면이므로 아무것도 하지 않음
              break;
            case 3:
              if (_isTrainer) {
                _navigateToScreen(const PtContractScreen());
              } else {
                CustomToast.show(
                  context: context,
                  message: '현재 준비중입니다.',
                  type: ToastType.info,
                );
              }
              break;
            case 4:
              _showRoleSwitchDialog();
              break;
          }
        },
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
