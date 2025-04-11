// lib/screens/chat_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_message_bubble.dart';

class ChatConstants {
  static const String userRole = 'user';
  static const String assistantRole = 'assistant';
  static const String errorMessage = '오류가 발생했습니다: ';
  static const String appTitle = '챗봇';

  static const double messagePadding = 8.0;
  static const double messageMargin = 4.0;
  static const double borderRadius = 12.0;
  static const double iconSpacing = 8.0;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ChatService _chatService = ChatService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentMessages();
  }

  Future<void> _loadRecentMessages() async {
    try {
      setState(() => _isLoading = true);
      final recentMessages = await _chatService.getRecentMessages();
      setState(() {
        _messages.addAll(recentMessages);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ChatConstants.errorMessage}$e')),
        );
      }
    }
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
        ChatMessage(content: userMessage, role: ChatConstants.userRole),
      );
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('Calling _chatService.sendMessage');
      }
      final response = await _chatService.sendMessage(userMessage, []);
      if (kDebugMode) {
        print('Received response from service: $response');
      }

      if (mounted) {
        setState(() {
          _messages.add(response);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in _sendMessage: $e');
        print('Stack trace: $stackTrace');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ChatConstants.errorMessage}$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ChatConstants.appTitle),
        forceMaterialTransparency: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                padding: const EdgeInsets.all(ChatConstants.messagePadding),
                itemBuilder: (context, index) {
                  return ChatMessageBubble(message: _messages[index]);
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
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
