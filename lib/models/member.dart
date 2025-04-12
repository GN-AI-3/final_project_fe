class Member {
  static const String _defaultUserType = 'MEMBER';
  static const String _defaultName = '';
  static const String _defaultEmail = '';

  final int id;
  final String email;
  final String? phone;
  final String name;
  final String? profileImage;
  final String userType;
  final List<String>? goal;
  final DateTime createdAt;
  final DateTime modifiedAt;

  Member({
    required this.id,
    required this.email,
    this.phone,
    required this.name,
    this.profileImage,
    required this.userType,
    this.goal,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? _defaultEmail,
      phone: json['phone'] as String?,
      name: json['name'] as String? ?? _defaultName,
      profileImage: json['profileImage'] as String?,
      userType: json['userType'] as String? ?? _defaultUserType,
      goal: (json['goal'] as List<dynamic>?)?.cast<String>(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      modifiedAt: json['modified_at'] != null
          ? DateTime.parse(json['modified_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'profileImage': profileImage,
      'userType': userType,
      'goal': goal,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
    };
  }

  Member copyWith({
    int? id,
    String? email,
    String? phone,
    String? name,
    String? profileImage,
    String? userType,
    List<String>? goal,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return Member(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}
