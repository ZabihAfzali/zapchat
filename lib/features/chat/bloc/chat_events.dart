
import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

// Load chats
class LoadChats extends ChatEvent {}

// Load messages for a specific chat
class LoadMessages extends ChatEvent {
  final String chatId;

  const LoadMessages({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

// Send text message
class SendTextMessage extends ChatEvent {
  final String chatId;
  final String text;
  final String receiverId;

  const SendTextMessage({
    required this.chatId,
    required this.text,
    required this.receiverId,
  });

  @override
  List<Object> get props => [chatId, text, receiverId];
}

// Send media message
class SendMediaMessage extends ChatEvent {
  final String chatId;
  final String filePath;
  final String mediaType; // 'image' or 'video'
  final String receiverId;

  const SendMediaMessage({
    required this.chatId,
    required this.filePath,
    required this.mediaType,
    required this.receiverId,
  });

  @override
  List<Object> get props => [chatId, filePath, mediaType, receiverId];
}

// Mark message as read
class MarkMessageAsRead extends ChatEvent {
  final String chatId;
  final String messageId;

  const MarkMessageAsRead({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object> get props => [chatId, messageId];
}

// Update typing status
class UpdateTypingStatus extends ChatEvent {
  final String chatId;
  final bool isTyping;

  const UpdateTypingStatus({
    required this.chatId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [chatId, isTyping];
}

// Delete message
class DeleteMessage extends ChatEvent {
  final String chatId;
  final String messageId;
  final bool forEveryone;

  const DeleteMessage({
    required this.chatId,
    required this.messageId,
    required this.forEveryone,
  });

  @override
  List<Object> get props => [chatId, messageId, forEveryone];
}