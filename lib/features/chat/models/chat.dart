// lib/features/chat/models/chat.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_model.dart';

class Chat {
  final String id;
  final List<String> participantIds;
  final ChatUser? otherUser;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final int unreadCount;
  final Map<String, bool> typing;
  final bool isMuted;
  final bool isPinned;

  Chat({
    required this.id,
    required this.participantIds,
    this.otherUser,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.typing = const {},
    this.isMuted = false,
    this.isPinned = false,
  });

  factory Chat.fromFirestore(
      DocumentSnapshot doc,
      ChatUser? otherUser,
      int unreadCount,
      ) {
    final data = doc.data() as Map<String, dynamic>;
    return Chat(
      id: doc.id,
      participantIds: List<String>.from(data['participants'] ?? []),
      otherUser: otherUser,
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageSenderId: data['lastMessageSender'],
      unreadCount: unreadCount,
      typing: Map<String, bool>.from(data['typing'] ?? {}),
      isMuted: data['isMuted'] ?? false,
      isPinned: data['isPinned'] ?? false,
    );
  }
}