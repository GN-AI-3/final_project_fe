import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/member.dart';
import '../../widgets/custom_dialog.dart';
import '../services/member_service.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({Key? key}) : super(key: key);

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  final MemberService _memberService = MemberService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _goalController = TextEditingController();

  Member? _member;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMemberInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberInfo() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final member = await _memberService.getMyInfo();

      if (!mounted) return;

      setState(() {
        _member = member;
        _nameController.text = member.name;
        _emailController.text = member.email;
        _phoneController.text = member.phone ?? '';
        _goalController.text = member.goal?.join(', ') ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      _showErrorDialog('회원 정보를 불러오는데 실패했습니다: $e');
    }
  }

  Future<void> _saveMemberInfo() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedMember = await _memberService.updateMyInfo(
        Member(
          id: _member!.id,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text.isEmpty ? null : _phoneController.text,
          goal:
              _goalController.text.isEmpty
                  ? null
                  : _goalController.text
                      .split(',')
                      .map((e) => e.trim())
                      .toList(),
          profileImage: _member!.profileImage,
          userType: _member!.userType,
          createdAt: _member!.createdAt,
          modifiedAt: _member!.modifiedAt,
        ),
      );

      if (!mounted) return;

      setState(() {
        _member = updatedMember;
        _isLoading = false;
      });

      if (!mounted) return;

      _showConfirmDialog('성공', '회원 정보가 성공적으로 수정되었습니다', () {
        Navigator.pop(context);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      _showErrorDialog('회원 정보 수정에 실패했습니다: $e');
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _memberService.logout();
    } catch (e) {
      // 로그아웃 API 호출 실패는 무시하고 진행
      if (kDebugMode) {
        print('로그아웃 API 호출 실패: $e');
      }
    } finally {
      if (mounted) {
        Navigator.pop(context); // 프로필 화면 닫기
        Navigator.pop(context); // 홈 화면 닫기
      }
    }
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

  void _showConfirmDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => CustomDialog(
            title: title,
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필'), forceMaterialTransparency: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_member?.profileImage != null)
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(_member!.profileImage!),
                        )
                      else
                        const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 50),
                        ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '이름',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이름을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이메일을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: '전화번호',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _goalController,
                        decoration: const InputDecoration(
                          labelText: '목표',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: _isLoading ? null : _saveMemberInfo,
                        child: const Text('저장'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading ? null : _logout,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text(
                              '로그아웃',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
