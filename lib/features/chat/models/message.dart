// lib/features/chat/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String? text;
  final String? mediaUrl;
  final String? mediaType;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final List<String> readBy;
  final bool isDeleted;
  final List<String> deletedFor;
  final String? replyToId;

  Message({
    required this.id,
    required this.senderId,
    this.text,
    this.mediaUrl,
    this.mediaType,
    required this.type,
    required this.timestamp,
    required this.status,
    this.readBy = const [],
    this.isDeleted = false,
    this.deletedFor = const [],
    this.replyToId,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      type: MessageType.values.firstWhere(
            (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
            (e) => e.toString() == 'MessageStatus.${data['status']}',
        orElse: () => MessageStatus.sent,
      ),
      readBy: List<String>.from(data['readBy'] ?? []),
      isDeleted: data['isDeleted'] ?? false,
      deletedFor: List<String>.from(data['deletedFor'] ?? []),
      replyToId: data['replyToId'],
    );
  }
}

enum MessageType { text, image, video, audio, location, sticker }
enum MessageStatus { sent, delivered, read }