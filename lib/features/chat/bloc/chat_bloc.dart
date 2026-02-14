// lib/features/chat/bloc/chat_bloc.dart
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zapchat/features/chat/models/chat.dart';
import 'package:zapchat/features/chat/models/message.dart';
import 'package:zapchat/features/chat/repository/chat_repository.dart';

import 'chat_events.dart';
import 'chat_states.dart';


class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    on<LoadChats>(_onLoadChats);
    on<LoadMessages>(_onLoadMessages);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendMediaMessage>(_onSendMediaMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<UpdateTypingStatus>(_onUpdateTypingStatus);
    on<DeleteMessage>(_onDeleteMessage);
    on<ClearUnreadCount>(_onClearUnreadCount);
  }

  Future<void> _onLoadChats(
      LoadChats event,
      Emitter<ChatState> emit,
      ) async {
    emit(ChatLoading());

    try {
      // Listen to real-time updates
      await emit.forEach<List<Chat>>(
        chatRepository.getChatsStream(),
        onData: (chats) => ChatsLoaded(chats: chats),
        onError: (error, stackTrace) => ChatError(message: error.toString()),
      );
    } catch (e) {
      emit(ChatError(message: 'Failed to load chats: $e'));
    }
  }

  Future<void> _onLoadMessages(
      LoadMessages event,
      Emitter<ChatState> emit,
      ) async {
    emit(ChatLoading());

    try {
      // Listen to real-time messages
      await emit.forEach<List<Message>>(
        chatRepository.getMessagesStream(event.chatId),
        onData: (messages) => MessagesLoaded(
          chatId: event.chatId,
          messages: messages,
        ),
        onError: (error, stackTrace) => ChatError(message: error.toString()),
      );
    } catch (e) {
      emit(ChatError(message: 'Failed to load messages: $e'));
    }
  }

  Future<void> _onSendTextMessage(
      SendTextMessage event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await chatRepository.sendTextMessage(
        chatId: event.chatId,
        text: event.text,
        receiverId: event.receiverId,
      );
    } catch (e) {
      emit(ChatError(message: 'Failed to send message: $e'));
    }
  }

  Future<void> _onSendMediaMessage(
      SendMediaMessage event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await chatRepository.sendMediaMessage(
        chatId: event.chatId,
        file: event.file,
        mediaType: event.mediaType,
        receiverId: event.receiverId,
        caption: event.caption,
      );
    } catch (e) {
      emit(ChatError(message: 'Failed to send media: $e'));
    }
  }

  Future<void> _onMarkMessageAsRead(
      MarkMessageAsRead event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await chatRepository.markAsRead(event.chatId, event.messageId);
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  Future<void> _onUpdateTypingStatus(
      UpdateTypingStatus event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await chatRepository.updateTypingStatus(
        event.chatId,
        event.isTyping,
      );

      emit(TypingStatusUpdated(
        chatId: event.chatId,
        isTyping: event.isTyping,
      ));
    } catch (e) {
      print('Failed to update typing status: $e');
    }
  }

  Future<void> _onDeleteMessage(
      DeleteMessage event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await chatRepository.deleteMessage(
        event.chatId,
        event.messageId,
        event.forEveryone,
      );

      emit(MessageDeleted(
        chatId: event.chatId,
        messageId: event.messageId,
      ));
    } catch (e) {
      emit(ChatError(message: 'Failed to delete message: $e'));
    }
  }

  Future<void> _onClearUnreadCount(
      ClearUnreadCount event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await chatRepository.clearUnreadCount(event.chatId);
    } catch (e) {
      print('Failed to clear unread count: $e');
    }
  }
}