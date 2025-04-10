import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../constants/chat_constants.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatConstants.userRole;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: ChatConstants.messageMargin),
        padding: const EdgeInsets.all(ChatConstants.messagePadding),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(ChatConstants.borderRadius),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.black87 : Colors.black54,
          ),
        ),
      ),
    );
  }
} 