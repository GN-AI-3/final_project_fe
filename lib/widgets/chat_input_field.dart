import 'package:flutter/material.dart';
import '../constants/chat_constants.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ChatConstants.messagePadding),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: ChatConstants.hintText,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: ChatConstants.iconSpacing),
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: isLoading ? null : onSend,
          ),
        ],
      ),
    );
  }
} 