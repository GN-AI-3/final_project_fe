// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/chat_message.dart';
import '../services/trainer_chat_service.dart';
import '../../widgets/chat_input_field.dart';
import '../../widgets/chat_message_bubble.dart';

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
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  padding: const EdgeInsets.all(TrainerChatConstants.messagePadding),
                  reverse: true,
                  itemBuilder: (context, index) {
                    return ChatMessageBubble(
                      message: _messages[_messages.length - 1 - index],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ChatInputField(
                  controller: _messageController,
                  onSend: _sendMessage,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
} 