// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/chat_message.dart';
import '../services/trainer_chat_service.dart';
import '../../widgets/common_bottom_navigation_bar.dart';
import '../screens/calendar_screen.dart';
import '../screens/pt_contract_screen.dart';
import '../../screens/home_screen.dart';
import '../../widgets/chat_message_group.dart';
import '../../services/auth_service.dart';

class TrainerChatConstants {
  static const String userRole = 'user';
  static const String assistantRole = 'assistant';
  static const String errorMessage = '오류가 발생했습니다: ';
  static const String appTitle = '트레이너 채팅';
  static const String chatHistoryKey = 'trainer_chat_history';

  static const double messagePadding = 8.0;
  static const double messageMargin = 4.0;
  static const double borderRadius = 12.0;
  static const double iconSpacing = 8.0;
}

class TrainerChatScreen extends StatefulWidget {
  const TrainerChatScreen({super.key});

  @override
  State<TrainerChatScreen> createState() => TrainerChatScreenState();
}

class TrainerChatScreenState extends State<TrainerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final TrainerChatService _chatService = TrainerChatService();
  bool _isLoading = false;
  SharedPreferences? _prefs;
  bool _isPrefsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isPrefsInitialized = true;
      await _loadChatHistory();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SharedPreferences: $e');
      }
    }
  }

  Future<void> _loadChatHistory() async {
    if (!_isPrefsInitialized || _prefs == null) return;

    try {
      final chatHistory = _prefs!.getString(TrainerChatConstants.chatHistoryKey);
      if (chatHistory != null) {
        final List<dynamic> decodedMessages = json.decode(chatHistory);
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(
              decodedMessages.map(
                (msg) => ChatMessage(
                  content: msg['content'] as String,
                  role: msg['role'] as String,
                ),
              ),
            );
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading chat history: $e');
      }
    }
  }

  Future<void> _saveChatHistory() async {
    if (!_isPrefsInitialized || _prefs == null) return;

    try {
      final messagesJson = json.encode(
        _messages.map((msg) => msg.toJson()).toList(),
      );
      await _prefs!.setString(TrainerChatConstants.chatHistoryKey, messagesJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving chat history: $e');
      }
    }
  }

  void _showToast(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.8,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    if (kDebugMode) {
      print('User message: $userMessage');
    }
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(content: userMessage, role: TrainerChatConstants.userRole),
      );
      _messages.add(
        ChatMessage(
          content: '답변을 생성하는 중...',
          role: TrainerChatConstants.assistantRole,
        ),
      );
      _isLoading = true;
    });

    await _saveChatHistory();

    try {
      if (kDebugMode) {
        print('Calling _chatService.sendMessage');
      }
      final response = await _chatService.sendMessage(userMessage, []);
      if (kDebugMode) {
        print('Received response from service: ${response.content}');
      }

      if (mounted) {
        setState(() {
          _messages.removeLast(); // 로딩 메시지 제거
          _messages.add(response);
          _isLoading = false;
        });
        await _saveChatHistory();
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in _sendMessage: $e');
        print('Stack trace: $stackTrace');
      }
      if (mounted) {
        setState(() {
          _messages.removeLast(); // 로딩 메시지 제거
          _isLoading = false;
        });
        _showToast('${TrainerChatConstants.errorMessage}$e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(TrainerChatConstants.appTitle),
        forceMaterialTransparency: true,
        backgroundColor: const Color(0xfff0f0f0),
      ),
      body: SafeArea(
        child: Container(
          color: const Color(0xfff0f0f0),
          child: const Center(
            child: Text(
              '트레이너 채팅 기능은 현재 질문 대응 강화를 위한 점검중입니다.\n 정식 출시를 기대해주세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CommonBottomNavigationBar(
        isTrainer: true,
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
              break;
            case 1:
              // 현재 화면이므로 아무것도 하지 않음
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PtContractScreen()),
              );
              break;
            case 4:
              _showRoleSwitchDialog();
              break;
          }
        },
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          '메시지를 시작해보세요!',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    // 메시지 그룹화
    final groupedMessages = <List<ChatMessage>>[];
    List<ChatMessage> currentGroup = [];
    String? currentRole;

    for (final message in _messages) {
      if (currentRole == null) {
        currentRole = message.role;
        currentGroup = [message];
      } else if (message.role == currentRole) {
        currentGroup.add(message);
      } else {
        if (currentGroup.isNotEmpty) {
          groupedMessages.add(List.from(currentGroup));
        }
        currentRole = message.role;
        currentGroup = [message];
      }
    }
    if (currentGroup.isNotEmpty) {
      groupedMessages.add(currentGroup);
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: groupedMessages.length,
      itemBuilder: (context, index) {
        final messages = groupedMessages[groupedMessages.length - 1 - index];
        return ChatMessageGroup(
          messages: messages,
          isTrainer: true,
          role: TrainerChatConstants.userRole,
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
} 