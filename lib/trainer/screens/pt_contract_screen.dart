// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/pt_contract.dart';
import '../../utils/date_formatter.dart';
import '../../utils/korean_postposition.dart';
import '../../widgets/custom_dialog.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/common_bottom_navigation_bar.dart';
import '../services/pt_contract_service.dart';
import '../screens/calendar_screen.dart';
import '../screens/trainer_chat_screen.dart';
import '../../screens/home_screen.dart';
import '../../services/auth_service.dart';

class PtContractScreen extends StatefulWidget {
  const PtContractScreen({Key? key}) : super(key: key);

  @override
  PtContractScreenState createState() => PtContractScreenState();
}

class PtContractScreenState extends State<PtContractScreen> {
  final PtContractService _ptContractService = PtContractService();
  List<PtContract> _contracts = [];
  List<PtContract> _filteredContracts = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;

  // 색상 상수 정의
  static const Color primaryColor = Color(0xff2746F8);
  static const Color secondaryColor1 = Color(0xff28CAF7);
  static const Color secondaryColor2 = Color(0xff8F28F7);
  static const Color secondaryColor3 = Color(0xff7A8DF7);
  static const Color secondaryColor4 = Color(0xff2888F7);
  static const Color textColor = Color(0xff3B3C40);
  static const Color backgroundColor = Color(0xffF8F9FA);

  @override
  void initState() {
    super.initState();
    _loadContracts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContracts = _contracts.where((contract) {
        final matchesSearch = contract.memberName.toLowerCase().contains(query);
        final matchesStatus = _selectedStatus == null || contract.status == _selectedStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _showFilterMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1, 80, 0, 0),
      items: [
        const PopupMenuItem<String>(value: 'RESET', child: Text('전체')),
        const PopupMenuItem<String>(value: 'ACTIVE', child: Text('진행중')),
        const PopupMenuItem<String>(value: 'COMPLETED', child: Text('완료')),
        const PopupMenuItem<String>(value: 'CANCELLED', child: Text('취소')),
        const PopupMenuItem<String>(value: 'SUSPENDED', child: Text('일시중지')),
        const PopupMenuItem<String>(value: 'EXPIRED', child: Text('만료')),
      ],
    ).then((value) {
      if (value == null) return;
      
      setState(() {
        _selectedStatus = value == 'RESET' ? null : value;
        _filterContracts();
      });
    });
  }

  void _filterContracts() {
    setState(() {
      _filteredContracts = _contracts.where((contract) {
        final matchesSearch = _searchController.text.isEmpty || 
            contract.memberName.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesStatus = _selectedStatus == null || contract.status == _selectedStatus;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _loadContracts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final contracts = await _ptContractService.getContractMembers();
      if (!mounted) return;

      setState(() {
        _contracts = contracts;
        _filterContracts();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      _showErrorDialog('계약 목록을 불러오는데 실패했습니다: $e');
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

  void _showStatusChangeDialog(PtContract contract) {
    final allowedStatuses = _getAllowedStatuses(contract.status);

    showDialog(
      context: context,
      builder:
          (context) => CustomDialog(
            title: '계약 상태 변경',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  '${contract.memberName} 회원님의 계약 상태 변경',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '현재 상태: ${_getStatusInfo(contract.status).$2}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      allowedStatuses.map((status) {
                        final (color, text) = _getStatusInfo(status);
                        return SizedBox(
                          width: 120,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showConfirmDialog(contract.id, status, text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: color,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: color, width: 2),
                              ),
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          ),
    );
  }

  void _showConfirmDialog(int contractId, String newStatus, String statusText) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialog(
            title: '상태 변경 확인',
            content: Text(
              '상태를 $statusText${KoreanPostposition.getPostposition(statusText)} 변경하시겠습니까?',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateContractStatus(contractId, newStatus);
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateContractStatus(int contractId, String status) async {
    if (!mounted) return;

    try {
      await _ptContractService.updateContractStatus(contractId, status);
      if (!mounted) return;

      await _loadContracts();
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        print('Error updating contract status: $e');
      }

      if (mounted) {
        CustomToast.show(
          context: context,
          message: '계약 상태 업데이트 실패: $e',
          type: ToastType.error,
        );
      }
    }
  }

  List<String> _getAllowedStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'ACTIVE':
        return ['SUSPENDED', 'CANCELLED'];
      case 'SUSPENDED':
        return ['ACTIVE', 'CANCELLED'];
      case 'CANCELLED':
        return ['ACTIVE', 'SUSPENDED'];
      default:
        return [currentStatus];
    }
  }

  void _showEditContractDialog(PtContract contract) {
    final TextEditingController endDateController = TextEditingController(
      text: DateFormatter.formatDate(contract.endDate),
    );
    final TextEditingController memoController = TextEditingController(
      text: contract.memo,
    );
    final TextEditingController totalCountController = TextEditingController(
      text: contract.totalCount.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => CustomDialog(
            title: '계약 정보 수정',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  '${contract.memberName} 회원님의 계약 정보',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                    labelText: '종료일',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: contract.endDate,
                      firstDate: contract.startDate,
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && mounted) {
                      endDateController.text = DateFormatter.formatDate(picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: memoController,
                  decoration: const InputDecoration(
                    labelText: '메모',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: totalCountController,
                  decoration: const InputDecoration(
                    labelText: '총 PT 횟수',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                if (_getAllowedStatuses(contract.status).length > 1)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (mounted) {
                          _showStatusChangeDialog(contract);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _getStatusInfo(contract.status).$1,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _getStatusInfo(contract.status).$1,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        '상태 변경하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getStatusInfo(contract.status).$1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final endDate = DateFormatter.parseDate(
                      endDateController.text,
                    );
                    final totalCount = int.parse(totalCountController.text);

                    if (totalCount < contract.usedCount) {
                      throw Exception(
                        '총 PT 횟수는 사용한 횟수(${contract.usedCount}회)보다 작을 수 없습니다.',
                      );
                    }

                    await _ptContractService.updateContract(
                      contract.id,
                      endDate: endDate,
                      memo: memoController.text,
                      totalCount: totalCount,
                    );

                    if (!mounted) return;

                    // 다이얼로그를 닫기 전에 토스트 메시지를 표시
                    if (mounted) {
                      CustomToast.show(
                        context: context,
                        message: '계약 정보가 수정되었습니다.',
                        type: ToastType.success,
                      );
                    }

                    // 다이얼로그를 닫고 목록을 갱신
                    Navigator.pop(context);
                    if (mounted) {
                      await _loadContracts();
                    }
                  } catch (e) {
                    if (!mounted) return;
                    if (mounted) {
                      _showErrorDialog('계약 정보 수정 실패: $e');
                    }
                  }
                },
                child: const Text('수정'),
              ),
            ],
          ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'PT 계약 관리',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        forceMaterialTransparency: true,
        actions: [
          SizedBox(
            width: 150,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '이름으로 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
            tooltip: '필터',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _filteredContracts.length,
                itemBuilder: (context, index) {
                  final contract = _filteredContracts[index];
                  return GestureDetector(
                    onLongPress: () => _showEditContractDialog(contract),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      _getStatusInfo(contract.status).$1,
                                  child: Text(
                                    contract.memberName[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${contract.memberName} 회원님',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '계약 기간: ${_buildDateRange('계약 기간', contract.startDate, contract.endDate)}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusChip(contract.status),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey[200]),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  '연락처',
                                  contract.phone,
                                  Icons.phone,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                  '이메일',
                                  contract.email,
                                  Icons.email,
                                ),
                                const SizedBox(height: 10),
                                _buildInfoRow(
                                  '성별',
                                  contract.gender,
                                  Icons.person,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildProgressCard(
                                        '총 횟수',
                                        '${contract.totalCount}회',
                                        secondaryColor2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildProgressCard(
                                        '사용 횟수',
                                        '${contract.usedCount}회',
                                        secondaryColor3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildProgressCard(
                                        '남은 횟수',
                                        '${contract.remainingCount}회',
                                        secondaryColor4,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: CommonBottomNavigationBar(
        isTrainer: true,
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrainerChatScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              break;
            case 3:
              // 현재 화면이므로 아무것도 하지 않음
              break;
            case 4:
              _showRoleSwitchDialog();
              break;
          }
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return GestureDetector(
      onTap: () async {
        if (label == '연락처') {
          final Uri phoneUri = Uri(scheme: 'tel', path: value);
          if (await canLaunchUrl(phoneUri)) {
            await launchUrl(phoneUri);
          } else {
            if (mounted) {
              _showErrorDialog('전화를 걸 수 없습니다.');
            }
          }
        }
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(color: Colors.grey[800], fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _buildDateRange(String label, DateTime start, DateTime end) {
    return DateFormatter.formatDateRange(start, end);
  }

  Widget _buildStatusChip(String status) {
    final (color, text) = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(String status) {
    switch (status) {
      case 'ACTIVE':
        return (primaryColor, '진행중');
      case 'COMPLETED':
        return (const Color(0xff4CAF50), '완료');
      case 'CANCELLED':
        return (Colors.red, '취소');
      case 'SUSPENDED':
        return (const Color(0xffFF9800), '일시중지');
      case 'EXPIRED':
        return (textColor, '만료');
      default:
        return (textColor, status);
    }
  }
}

class GlowingBorderPainter extends CustomPainter {
  final Color color;
  final double progress;

  GlowingBorderPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(12),
          ),
        );

    final dashPattern = [4.0, 4.0];
    final dashLength = dashPattern.reduce((a, b) => a + b);
    final dashOffset = progress * dashLength;

    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;
    var currentLength = 0.0;

    while (currentLength < totalLength) {
      final isDash = (currentLength / dashLength).floor() % 2 == 0;
      final dashSize =
          dashPattern[(currentLength / dashLength).floor() %
              dashPattern.length];
      final nextLength = currentLength + dashSize;

      if (isDash) {
        final extractPath = pathMetrics.extractPath(
          currentLength - dashOffset,
          nextLength - dashOffset,
        );
        canvas.drawPath(extractPath, paint);
      }

      currentLength = nextLength;
    }
  }

  @override
  bool shouldRepaint(covariant GlowingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
