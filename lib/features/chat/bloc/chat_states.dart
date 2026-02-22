// lib/features/chat/bloc/chat_states.dart

import 'package:equatable/equatable.dart';

import '../models/chat.dart';
import '../models/group.dart';
import '../models/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

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

  MessagesLoaded copyWith({
    String? chatId,
    List<Message>? messages,
    bool? isTyping,
  }) {
    return MessagesLoaded(
      chatId: chatId ?? this.chatId,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
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

class SearchState extends Equatable {
  final String query;
  final bool isSearching;
  final List<Chat> chatResults;
  final List<Message> messageResults;

  const SearchState({
    this.query = '',
    this.isSearching = false,
    this.chatResults = const [],
    this.messageResults = const [],
  });

  @override
  List<Object> get props => [query, isSearching, chatResults, messageResults];

  SearchState copyWith({
    String? query,
    bool? isSearching,
    List<Chat>? chatResults,
    List<Message>? messageResults,
  }) {
    return SearchState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      chatResults: chatResults ?? this.chatResults,
      messageResults: messageResults ?? this.messageResults,
    );
  }
}

// In chat_states.dart
class ChatsLoaded extends ChatState {
  final List<Chat> chats;
  final List<Group> groups; // Add groups
  final SearchState searchState;

  const ChatsLoaded({
    required this.chats,
    this.groups = const [], // Default empty list
    this.searchState = const SearchState(),
  });

  @override
  List<Object> get props => [chats, groups, searchState];

  ChatsLoaded copyWith({
    List<Chat>? chats,
    List<Group>? groups,
    SearchState? searchState,
  }) {
    return ChatsLoaded(
      chats: chats ?? this.chats,
      groups: groups ?? this.groups,
      searchState: searchState ?? this.searchState,
    );
  }
}
class GroupsLoaded extends ChatState {
  final List<Group> groups;
  const GroupsLoaded({required this.groups});
}

class GroupMessagesLoaded extends ChatState {
  final String chatId;
  final List<Message> messages;
  const GroupMessagesLoaded({required this.chatId, required this.messages});
}

