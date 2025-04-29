// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';

class ChatMessageGroup extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isTrainer;
  final String role;

  const ChatMessageGroup({
    super.key,
    required this.messages,
    required this.isTrainer,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();

    final isUserMessage = messages.first.role == role;
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUserMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xff2746f8).withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Color(0xff2746f8),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                ...messages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final message = entry.value;
                  final isLastInGroup = index == messages.length - 1;
                  
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: isLastInGroup ? 4.0 : 2.0,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.55,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isUserMessage
                            ? const Color(0xff2746f8)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }),
                if (messages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      timeFormat.format(messages.last.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUserMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xff2746f8).withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Color(0xff2746f8),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 