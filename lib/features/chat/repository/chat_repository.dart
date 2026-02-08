import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapchat/core/config/app_config.dart';

import '../../../core/services/storage_services.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService;

  ChatRepository({StorageService? storageService})
      : _storageService = storageService ??
      (AppConfig.useDevStorage ? DevStorageService() : FirebaseStorageService());

  // Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? 'user1'; // Default for dev

  // Development data for testing
  final List<Map<String, dynamic>> _devChats = [
     {
      'id': 'user2',
      'name': 'Emma Wilson',
      'profilePicture': 'https://randomuser.me/api/portraits/women/1.jpg',
      'isOnline': true,
      'hasStory': true, // Add this field
    },
  ];

  final List<Map<String, dynamic>> _devMessages = [
    {
      'id': 'msg_1',
      'senderId': 'user1',
      'text': 'Hello!',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 10))??'',
      'type': 'text',
      'status': 'read',
    },
    {
      'id': 'msg_2',
      'senderId': 'user2',
      'text': 'Hi there! How are you?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
      'type': 'text',
      'status': 'read',
    },
    {
      'id': 'msg_3',
      'senderId': 'user1',
      'text': 'I\'m good! Working on ZapChat 😊',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'type': 'text',
      'status': 'delivered',
    },
    {
      'id': 'msg_4',
      'senderId': 'user1',
      'mediaUrl': 'https://picsum.photos/300/400',
      'mediaType': 'image',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
      'type': 'media',
      'status': 'sent',
    },
  ];

  // MARK AS READ METHOD
  Future<void> markAsRead(String chatId, String messageId) async {
    if (AppConfig.useDevChatData) {
      // Simulate marking as read in dev mode
      await Future.delayed(const Duration(milliseconds: 300));
      print('📖 DEV: Marked message $messageId as read');
      return;
    }

    // Real Firestore implementation
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([currentUserId]),
        'status': 'read',
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // UPDATE TYPING STATUS METHOD
  Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    if (AppConfig.useDevChatData) {
      // Simulate typing status in dev mode
      await Future.delayed(const Duration(milliseconds: 200));
      print('⌨️  DEV: User ${isTyping ? 'started' : 'stopped'} typing in chat $chatId');
      return;
    }

    // Real Firestore implementation
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typing.${currentUserId}': isTyping,
        'typingLastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // DELETE MESSAGE METHOD
  Future<void> deleteMessage(String chatId, String messageId, bool forEveryone) async {
    if (AppConfig.useDevChatData) {
      // Simulate deletion in dev mode
      await Future.delayed(const Duration(milliseconds: 300));
      print('🗑️  DEV: Deleted message $messageId from chat $chatId');
      return;
    }

    // Real Firestore implementation
    try {
      if (forEveryone) {
        // Delete for everyone
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .delete();
      } else {
        // Delete only for current user (soft delete)
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .update({
          'deletedFor': FieldValue.arrayUnion([currentUserId]),
          'isDeleted': true,
        });
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  // Get chats (development version)
  Future<List<Map<String, dynamic>>> getChats() async {
    if (AppConfig.useDevChatData) {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      return _devChats;
    }

    // Real Firestore implementation would go here
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Get messages (development version)
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    if (AppConfig.useDevChatData) {
      await Future.delayed(const Duration(seconds: 1));
      return _devMessages;
    }

    // Real implementation
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Send message (works in dev mode)
  Future<void> sendMessage({
    required String chatId,
    required String text,
    String? mediaPath,
    String? mediaType,
  }) async {
    if (AppConfig.useDevChatData) {
      // Add to dev messages list
      _devMessages.insert(0, {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'senderId': currentUserId,
        'text': text,
        'timestamp': DateTime.now(),
        'type': mediaPath != null ? 'media' : 'text',
        'mediaUrl': mediaPath,
        'mediaType': mediaType,
        'status': 'sent',
      });

      // Update chat last message
      final chatIndex = _devChats.indexWhere((c) => c['id'] == chatId);
      if (chatIndex != -1) {
        final chat = _devChats[chatIndex];
        chat['lastMessage'] = text;
        chat['lastMessageTime'] = DateTime.now();
        chat['unreadCount'] = (chat['unreadCount'] as int) + 1;
      }

      return;
    }

    // Real Firestore implementation
    final messageData = {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
      'status': 'sent',
    };

    if (mediaPath != null && AppConfig.canUploadMedia) {
      // Upload media to storage
      final mediaUrl = mediaType == 'image'
          ? await _storageService.uploadChatImage(mediaPath, chatId)
          : await _storageService.uploadChatVideo(mediaPath, chatId);

      messageData['mediaUrl'] = mediaUrl;
      messageData['mediaType'] = mediaType!;
      messageData['type'] = 'media';
    }

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageData);

    // Update chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': currentUserId,
    });
  }
}