class ChatMessage {
  final int? id;
  final String content;
  final String role;
  final DateTime? createdAt;

  ChatMessage({
    this.id,
    required this.content,
    required this.role,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'role': role,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] != null ? json['id'] as int : null,
      content: json['content'] as String,
      role: json['role'] as String,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : null,
    );
  }
}