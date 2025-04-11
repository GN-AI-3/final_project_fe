import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_message.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _showCopiedToast = false;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    setState(() => _showCopiedToast = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _showCopiedToast = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Stack(
        children: [
          GestureDetector(
            onLongPress: () => _copyToClipboard(context),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xff2746f8) : Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                widget.message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          if (_showCopiedToast)
            Positioned(
              top: -30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '복사됨',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
