// lib/features/auth/models/user_model.dart
class UserModel {
  final String uid;
  final String userName;
  final String email;
  final String? password; // Only used for email/password auth
  final String? phoneNumber;
  final String status;
  final String country;
  final DateTime? birthday;
  final String gender;
  final String profileImage;
  final DateTime? createdAt;
  final DateTime? lastSeen;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.userName,
    required this.email,
    this.password,
    this.phoneNumber,
    this.status = 'Hey there! I am using ZapChat',
    this.country = '',
    this.birthday,
    this.gender = '',
    this.profileImage = '',
    this.createdAt,
    this.lastSeen,
    this.isOnline = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
      'phoneNumber': phoneNumber,
      'status': status,
      'country': country,
      'birthday': birthday?.toIso8601String(),
      'gender': gender,
      'profileImage': profileImage,
      'createdAt': createdAt?.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      userName: map['userName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      status: map['status'] ?? 'Hey there! I am using ZapChat',
      country: map['country'] ?? '',
      birthday: map['birthday'] != null ? DateTime.tryParse(map['birthday']) : null,
      gender: map['gender'] ?? '',
      profileImage: map['profileImage'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) : null,
      lastSeen: map['lastSeen'] != null ? DateTime.tryParse(map['lastSeen']) : null,
      isOnline: map['isOnline'] ?? true,
    );
  }

  // For creating initial user after auth
  factory UserModel.fromAuth({
    required String uid,
    required String email,
    String? userName,
  }) {
    return UserModel(
      uid: uid,
      userName: userName ?? email.split('@').first,
      email: email,
    );
  }

  UserModel copyWith({
    String? userName,
    String? phoneNumber,
    String? status,
    String? country,
    DateTime? birthday,
    String? gender,
    String? profileImage,
    DateTime? lastSeen,
    bool? isOnline,
  }) {
    return UserModel(
      uid: uid,
      userName: userName ?? this.userName,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      country: country ?? this.country,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      profileImage: profileImage ?? this.profileImage,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt,
    );
  }
}