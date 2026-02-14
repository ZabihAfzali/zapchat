// lib/features/chat/repository/chat_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:zapchat/features/chat/models/chat.dart';
import 'package:zapchat/features/chat/models/message.dart';

import '../models/chat_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Get chats stream - NO INDEX NEEDED
  Stream<List<Chat>> getChatsStream() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      final chats = <Chat>[];

      for (var doc in snapshot.docs) {
        try {
          final participants = List<String>.from(doc['participants'] ?? []);
          final otherUserId =
          participants.firstWhere((id) => id != currentUserId);

          final userDoc =
          await _firestore.collection('users').doc(otherUserId).get();
          final otherUser = userDoc.exists
              ? ChatUser.fromFirestore(userDoc)
              : null;

          final messagesSnapshot = await _firestore
              .collection('chats')
              .doc(doc.id)
              .collection('messages')
              .where('readBy', arrayContains: currentUserId)
              .count()
              .get();

          final totalMessagesSnapshot = await _firestore
              .collection('chats')
              .doc(doc.id)
              .collection('messages')
              .count()
              .get();

          final readCount = messagesSnapshot.count ?? 0;
          final totalCount = totalMessagesSnapshot.count ?? 0;
          final unreadCount = totalCount - readCount;

          chats.add(Chat.fromFirestore(doc, otherUser, unreadCount));
        } catch (e) {
          print('Error processing chat doc: $e');
          continue;
        }
      }

      // Sort in memory
      chats.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return chats;
    });
  }

  // Get messages stream
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .where((message) => !message.deletedFor.contains(currentUserId))
          .toList();
    });
  }

  // Get or create chat
  Future<String> getOrCreateChat(String otherUserId) async {
    if (currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in querySnapshot.docs) {
        final participants = List<String>.from(doc['participants'] ?? []);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      final chatRef = await _firestore.collection('chats').add({
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageSender': '',
        'unreadCount': 0,
        'typing': {},
        'isMuted': false,
        'isPinned': false,
      });

      return chatRef.id;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  // Get all users - EXCLUDES CURRENT USER
  Future<List<ChatUser>> getAllUsers() async {
    if (currentUserId.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .limit(100)
          .get();

      final users = snapshot.docs
          .where((doc) => doc.id != currentUserId) // Current user excluded
          .map((doc) => ChatUser.fromFirestore(doc))
          .toList();

      users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return users;
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // Get recent chat users - EXCLUDES CURRENT USER
  Future<List<ChatUser>> getRecentChatUsers() async {
    if (currentUserId.isEmpty) return [];

    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .limit(30)
          .get();

      final List<MapEntry<ChatUser, DateTime>> recentUsersWithTime = [];

      for (var doc in chatsSnapshot.docs) {
        if (doc['lastMessage'] == null ||
            doc['lastMessage'] == '' ||
            doc['lastMessageTime'] == null) {
          continue;
        }

        final participants = List<String>.from(doc['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != currentUserId);

        if (otherUserId == currentUserId) continue; // Safety check

        final lastMessageTime = (doc['lastMessageTime'] as Timestamp).toDate();

        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          recentUsersWithTime.add(
              MapEntry(ChatUser.fromFirestore(userDoc), lastMessageTime)
          );
        }
      }

      recentUsersWithTime.sort((a, b) => b.value.compareTo(a.value));

      return recentUsersWithTime
          .take(20)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      print('Error getting recent chats: $e');
      return [];
    }
  }

  // Send text message
  Future<void> sendTextMessage({
    required String chatId,
    required String text,
    required String receiverId,
  }) async {
    try {
      final messageData = {
        'senderId': currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'status': 'sent',
        'readBy': [currentUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'deletedFor': [],
      };

      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      batch.set(messageRef, messageData);

      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUserId,
        'unreadCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Send media message
  Future<void> sendMediaMessage({
    required String chatId,
    required File file,
    required String mediaType,
    required String receiverId,
    String? caption,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storageRef = _storage
          .ref()
          .child('chat_media')
          .child(chatId)
          .child(fileName);

      await storageRef.putFile(file);
      final mediaUrl = await storageRef.getDownloadURL();

      final messageData = {
        'senderId': currentUserId,
        'text': caption ?? (mediaType == 'image' ? '📷 Photo' : '🎥 Video'),
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'media',
        'status': 'sent',
        'readBy': [currentUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'deletedFor': [],
      };

      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      batch.set(messageRef, messageData);

      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'lastMessage': mediaType == 'image' ? '📷 Photo' : '🎥 Video',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUserId,
        'unreadCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Error sending media: $e');
      rethrow;
    }
  }

  // Mark as read
  Future<void> markAsRead(String chatId, String messageId) async {
    try {
      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      batch.update(messageRef, {
        'readBy': FieldValue.arrayUnion([currentUserId]),
        'status': 'read',
      });

      final chatRef = _firestore.collection('chats').doc(chatId);
      batch.update(chatRef, {
        'unreadCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // Update typing status
  Future<void> updateTypingStatus(String chatId, bool isTyping) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'typing.$currentUserId': isTyping,
        'typingLastUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId, bool forEveryone) async {
    try {
      if (forEveryone) {
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .delete();
      } else {
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
      rethrow;
    }
  }

  // Clear unread count
  Future<void> clearUnreadCount(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      print('Error clearing unread count: $e');
    }
  }
}