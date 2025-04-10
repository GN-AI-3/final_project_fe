class Member {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? fcmToken;
  final String? profileImage;
  final String userType;
  final String? goal;
  final DateTime createdAt;
  final DateTime modifiedAt;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.fcmToken,
    this.profileImage,
    required this.userType,
    this.goal,
    required this.createdAt,
    required this.modifiedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fcmToken: json['fcm_token'] as String?,
      profileImage: json['profile_image'] as String?,
      userType: json['user_type'] as String? ?? 'MEMBER',
      goal: json['goal'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      modifiedAt: json['modified_at'] != null 
          ? DateTime.parse(json['modified_at'] as String)
          : DateTime.now(),
    );
  }
} 