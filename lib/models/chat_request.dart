import 'chat_message.dart';

class ChatRequest {
  final String message;
  final List<ChatMessage> history;

  ChatRequest({required this.message, this.history = const []});

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'history': history.map((msg) => msg.toJson()).toList(),
    };
  }
}
