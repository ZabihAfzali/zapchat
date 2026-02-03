
import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatsLoaded extends ChatState {
  final List<Map<String, dynamic>> chats;
  final bool hasMore;

  const ChatsLoaded({
    required this.chats,
    this.hasMore = false,
  });

  @override
  List<Object> get props => [chats, hasMore];
}

class MessagesLoaded extends ChatState {
  final String chatId;
  final List<Map<String, dynamic>> messages;
  final Map<String, dynamic>? chatInfo;
  final bool isTyping;

  const MessagesLoaded({
    required this.chatId,
    required this.messages,
    this.chatInfo,
    this.isTyping = false,
  });

  @override
  List<Object> get props => [chatId, messages, isTyping];
}

class MessageSent extends ChatState {
  final String chatId;
  final Map<String, dynamic> message;

  const MessageSent({
    required this.chatId,
    required this.message,
  });

  @override
  List<Object> get props => [chatId, message];
}

class MessageDeleted extends ChatState {
  final String chatId;
  final String messageId;

  const MessageDeleted({
    required this.chatId,
    required this.messageId,
  });

  @override
  List<Object> get props => [chatId, messageId];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object> get props => [message];
}

class TypingStatusUpdated extends ChatState {
  final String chatId;
  final bool isTyping;

  const TypingStatusUpdated({
    required this.chatId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [chatId, isTyping];
}