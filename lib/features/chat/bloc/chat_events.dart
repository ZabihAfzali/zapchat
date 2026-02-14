// lib/features/chat/bloc/chat_events.dart

import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class LoadChats extends ChatEvent {}

class LoadMessages extends ChatEvent {
  final String chatId;

  const LoadMessages({required this.chatId});

  @override
  List<Object> get props => [chatId];
}

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

class SendMediaMessage extends ChatEvent {
  final String chatId;
  final File file;
  final String mediaType;
  final String receiverId;
  final String? caption;

  const SendMediaMessage({
    required this.chatId,
    required this.file,
    required this.mediaType,
    required this.receiverId,
    this.caption,
  });

  @override
  List<Object> get props => [chatId, file, mediaType, receiverId];
}

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

class ClearUnreadCount extends ChatEvent {
  final String chatId;

  const ClearUnreadCount({required this.chatId});

  @override
  List<Object> get props => [chatId];
}