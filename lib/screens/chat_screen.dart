// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../constants/chat_constants.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input_field.dart';

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
    print('User message: $userMessage');
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        content: userMessage,
        role: ChatConstants.userRole,
      ));
      _isLoading = true;
    });

    try {
      print('Calling _chatService.sendMessage');
      final response = await _chatService.sendMessage(userMessage, []);
      print('Received response from service: $response');

      if (mounted) {
        setState(() {
          _messages.add(response);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error in _sendMessage: $e');
      print('Stack trace: $stackTrace');
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
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              padding: EdgeInsets.all(ChatConstants.messagePadding),
              itemBuilder: (context, index) {
                return ChatMessageBubble(message: _messages[index]);
              },
            ),
          ),
          ChatInputField(
            controller: _messageController,
            onSend: _sendMessage,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}