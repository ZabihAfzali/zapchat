// lib/features/chat/bloc/chat_states.dart

import 'package:equatable/equatable.dart';

import '../models/chat.dart';
import '../models/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatsLoaded extends ChatState {
  final List<Chat> chats;

  const ChatsLoaded({required this.chats});

  @override
  List<Object> get props => [chats];
}

class MessagesLoaded extends ChatState {
  final String chatId;
  final List<Message> messages;
  final bool isTyping;

  const MessagesLoaded({
    required this.chatId,
    required this.messages,
    this.isTyping = false,
  });

  @override
  List<Object> get props => [chatId, messages, isTyping];
}

class MessageSent extends ChatState {
  final String chatId;
  final Message message;

  const MessageSent({required this.chatId, required this.message});

  @override
  List<Object> get props => [chatId, message];
}

class MessageDeleted extends ChatState {
  final String chatId;
  final String messageId;

  const MessageDeleted({required this.chatId, required this.messageId});

  @override
  List<Object> get props => [chatId, messageId];
}

class TypingStatusUpdated extends ChatState {
  final String chatId;
  final bool isTyping;

  const TypingStatusUpdated({required this.chatId, required this.isTyping});

  @override
  List<Object> get props => [chatId, isTyping];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object> get props => [message];
}