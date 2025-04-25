class ChatMessage {
  final int? id;
  final String content;
  final String role;
  final DateTime timestamp;
  final String? finalResponse;

  ChatMessage({
    this.id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.finalResponse,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'role': role,
      'finalResponse': finalResponse,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] != null ? json['id'] as int : null,
      content: json['content'] as String,
      role: json['role'] as String,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      finalResponse: json['finalResponse'] as String?,
    );
  }
}
