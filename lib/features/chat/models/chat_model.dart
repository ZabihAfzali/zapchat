// lib/features/chat/models/chat_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String uid;
  final String userName; // Changed from 'name' to 'userName' to match Firestore
  final String email; // Added email field
  final String? phoneNumber; // Added phoneNumber field
  final String? profileImage; // Changed from 'profilePicture' to 'profileImage'
  final bool isOnline;
  final DateTime? lastSeen;
  final bool hasStory;
  final bool isBirthday;
  final String? bitmojiAvatar;
  final String status; // Added status field
  final String country; // Added country field
  final String gender; // Added gender field
  final DateTime? birthday; // Added birthday field

  ChatUser({
    required this.uid,
    required this.userName,
    required this.email,
    this.phoneNumber,
    this.profileImage,
    this.isOnline = false,
    this.lastSeen,
    this.hasStory = false,
    this.isBirthday = false,
    this.bitmojiAvatar,
    this.status = 'Hey there! I am using ZapChat',
    this.country = '',
    this.gender = '',
    this.birthday,
  });

  factory ChatUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse birthday if it exists (could be Timestamp or String)
    DateTime? birthdayDate;
    if (data['birthday'] != null) {
      if (data['birthday'] is Timestamp) {
        birthdayDate = (data['birthday'] as Timestamp).toDate();
      } else if (data['birthday'] is String) {
        birthdayDate = DateTime.tryParse(data['birthday']);
      }
    }

    return ChatUser(
      uid: doc.id,
      // Try both field names for backward compatibility
      userName: data['userName'] ?? data['name'] ?? 'Unknown',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? data['phone'] ?? '',
      // Try both field names for profile image
      profileImage: data['profileImage'] ?? data['profilePicture'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      hasStory: data['hasStory'] ?? false,
      isBirthday: data['isBirthday'] ?? false,
      bitmojiAvatar: data['bitmojiAvatar'],
      status: data['status'] ?? 'Hey there! I am using ZapChat',
      country: data['country'] ?? '',
      gender: data['gender'] ?? '',
      birthday: birthdayDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'hasStory': hasStory,
      'isBirthday': isBirthday,
      'bitmojiAvatar': bitmojiAvatar,
      'status': status,
      'country': country,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
    };
  }

  // Helper getters for backward compatibility
  String get name => userName; // For code that still uses 'name'
  String? get profilePicture => profileImage; // For code that still uses 'profilePicture'
  String? get username => email.split('@').first; // Generate username from email if needed
}