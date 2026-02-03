import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
  }

  Future<void> _onLoadChats(
      LoadChats event,
      Emitter<ChatState> emit,
      ) async {
    emit(ChatLoading());

    try {
      final chats = await chatRepository.getChats();
      emit(ChatsLoaded(chats: chats));
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
      final messages = await chatRepository.getMessages(event.chatId);
      emit(MessagesLoaded(
        chatId: event.chatId,
        messages: messages,
      ));
    } catch (e) {
      emit(ChatError(message: 'Failed to load messages: $e'));
    }
  }

  Future<void> _onSendTextMessage(
      SendTextMessage event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await chatRepository.sendMessage(
        chatId: event.chatId,
        text: event.text,
      );

      // In real app, we'd get the actual message from Firestore
      final newMessage = {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'text': event.text,
        'senderId': chatRepository.currentUserId,
        'timestamp': DateTime.now(),
        'type': 'text',
        'status': 'sent',
      };

      emit(MessageSent(
        chatId: event.chatId,
        message: newMessage,
      ));
    } catch (e) {
      emit(ChatError(message: 'Failed to send message: $e'));
    }
  }

  Future<void> _onSendMediaMessage(
      SendMediaMessage event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await chatRepository.sendMessage(
        chatId: event.chatId,
        text: event.mediaType == 'image' ? '📷 Photo' : '🎥 Video',
        mediaPath: event.filePath,
        mediaType: event.mediaType,
      );

      final newMessage = {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'text': event.mediaType == 'image' ? '📷 Photo' : '🎥 Video',
        'senderId': chatRepository.currentUserId,
        'timestamp': DateTime.now(),
        'type': 'media',
        'mediaType': event.mediaType,
        'mediaUrl': event.filePath, // In dev, this is the local path
        'status': 'sent',
      };

      emit(MessageSent(
        chatId: event.chatId,
        message: newMessage,
      ));
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

      // In a real app, we'd update the local state
      // For now, just acknowledge
      emit(MessagesLoaded(
        chatId: event.chatId,
        messages: const [],
      ));
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
}