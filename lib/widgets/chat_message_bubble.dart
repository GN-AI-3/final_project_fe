import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/chat_message.dart';
import 'custom_toast.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  final bool _showCopiedToast = false;

  bool _isUrl(String text) {
    final urlPattern = RegExp(r'https?://[^\s)]+', caseSensitive: false);
    return urlPattern.hasMatch(text);
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('URL을 열 수 없습니다: $url')));
      }
    }
  }

  Widget _buildMessageContent(String content) {
    final isUser = widget.message.role == 'user';
    final baseStyle = TextStyle(
      color: isUser ? Colors.white : Colors.black87,
      fontSize: 16.0,
    );

    if (!_isUrl(content)) {
      return Text(content, style: baseStyle);
    }

    final urlPattern = RegExp(r'https?://[^\s)]+', caseSensitive: false);
    final matches = urlPattern.allMatches(content);

    final spans = <TextSpan>[];
    var lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: content.substring(lastEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: baseStyle.copyWith(
            color: isUser ? Colors.white : Colors.blue,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(url),
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      spans.add(TextSpan(text: content.substring(lastEnd), style: baseStyle));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      textScaler: MediaQuery.textScalerOf(context),
    );
  }

  void _copyToClipboard(BuildContext context) {
    final textToCopy = widget.message.finalResponse ?? widget.message.content;
    Clipboard.setData(ClipboardData(text: textToCopy));
    CustomToast.show(
      context: context,
      message: '메시지가 복사되었습니다',
      type: ToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';
    final displayContent = widget.message.finalResponse ?? widget.message.content;

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
                color:
                    isUser ? const Color(0xff2746f8) : const Color(0xffe8e8e8),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: _buildMessageContent(displayContent),
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
                    color: Colors.grey.withAlpha(128),
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
