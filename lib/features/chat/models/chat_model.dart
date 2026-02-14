// lib/features/chat/models/chat_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String uid;
  final String name;
  final String? username;
  final String? profilePicture;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool hasStory;
  final bool isBirthday;
  final String? bitmojiAvatar;

  ChatUser({
    required this.uid,
    required this.name,
    this.username,
    this.profilePicture,
    this.isOnline = false,
    this.lastSeen,
    this.hasStory = false,
    this.isBirthday = false,
    this.bitmojiAvatar,
  });

  factory ChatUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatUser(
      uid: doc.id,
      name: data['name'] ?? 'Unknown',
      username: data['username'],
      profilePicture: data['profilePicture'],
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      hasStory: data['hasStory'] ?? false,
      isBirthday: data['isBirthday'] ?? false,
      bitmojiAvatar: data['bitmojiAvatar'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'profilePicture': profilePicture,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'hasStory': hasStory,
      'isBirthday': isBirthday,
      'bitmojiAvatar': bitmojiAvatar,
    };
  }
}