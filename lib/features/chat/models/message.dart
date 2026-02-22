// lib/features/chat/models/message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, audio, file }
enum MessageStatus { sending, sent, delivered, read, error }

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String? content;
  final String? mediaUrl;
  final String? localPath;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final MessageStatus status;
  final List<String> readBy;
  final bool isDeleted;
  final List<String> deletedFor;
  final String? replyToId;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.localPath,
    this.metadata,
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
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: MessageType.values.firstWhere(
            (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      content: data['content'],
      mediaUrl: data['mediaUrl'],
      metadata: data['metadata'],
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

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'type': type.toString().split('.').last,
      'content': content,
      'mediaUrl': mediaUrl,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.toString().split('.').last,
      'readBy': readBy,
      'isDeleted': isDeleted,
      'deletedFor': deletedFor,
      'replyToId': replyToId,
    };
  }

  // Add these missing getters
  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isVideo => type == MessageType.video;
  bool get isAudio => type == MessageType.audio;
  bool get isFile => type == MessageType.file;
  bool get isMedia => type != MessageType.text;
}