class TrainerProfile {
  final int id;
  final String email;
  final String name;
  final String profileImage;
  final String phone;
  final String userType;
  final String career;
  final List<String> certifications;
  final String introduction;
  final List<String> specialities;
  final Subscribe subscribe;

  TrainerProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.profileImage,
    required this.phone,
    required this.userType,
    required this.career,
    required this.certifications,
    required this.introduction,
    required this.specialities,
    required this.subscribe,
  });

  factory TrainerProfile.fromJson(Map<String, dynamic> json) {
    return TrainerProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      profileImage: json['profileImage'] as String,
      phone: json['phone'] as String,
      userType: json['userType'] as String,
      career: json['career'] as String,
      certifications: List<String>.from(json['certifications'] as List),
      introduction: json['introduction'] as String,
      specialities: List<String>.from(json['specialities'] as List),
      subscribe: json['subscribe'] != null 
          ? Subscribe.fromJson(json['subscribe'] as Map<String, dynamic>)
          : Subscribe(
              id: 0,
              name: '구독 정보 없음',
              price: '-',
              managementPerson: '-',
              startDate: DateTime.now(),
              endDate: DateTime.now(),
              createdAt: DateTime.now(),
              modifiedAt: DateTime.now(),
              status: 'NONE',
            ),
    );
  }
}

class Subscribe {
  final int id;
  final String name;
  final String price;
  final String managementPerson;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String status;

  Subscribe({
    required this.id,
    required this.name,
    required this.price,
    required this.managementPerson,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.modifiedAt,
    required this.status,
  });

  factory Subscribe.fromJson(Map<String, dynamic> json) {
    return Subscribe(
      id: json['id'] as int,
      name: json['name'] as String,
      price: json['price'] as String,
      managementPerson: json['management_person'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      status: json['status'] as String,
    );
  }
} 