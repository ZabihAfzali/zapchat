// lib/features/chat/repository/chat_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:zapchat/features/chat/models/chat.dart';
import 'package:zapchat/features/chat/models/message.dart';
import 'package:zapchat/features/chat/models/group.dart';

import '../models/chat_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // ==================== CHAT STREAMS - INDEX FREE ====================

  // Get chats stream - COMPLETELY INDEX-FREE
  Stream<List<Chat>> getChatsStream() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    // Remove ALL ordering from Firestore - we'll sort in memory
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      final chats = <Chat>[];

      for (var doc in snapshot.docs) {
        try {
          final participants = List<String>.from(doc['participants'] ?? []);
          final otherUserId = participants.firstWhere((id) => id != currentUserId);

          final userDoc = await _firestore.collection('users').doc(otherUserId).get();
          final otherUser = userDoc.exists ? ChatUser.fromFirestore(userDoc) : null;

          // Calculate unread count
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

      // Sort in memory by last message time
      chats.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return chats;
    });
  }

  // Get messages stream for a specific chat
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

  // ==================== GROUP STREAMS - INDEX FREE ====================

  // Get groups stream - COMPLETELY INDEX-FREE
  Stream<List<Group>> getGroupsStream() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    // Remove ordering from Firestore - we'll sort in memory
    return _firestore
        .collection('groups')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final groups = snapshot.docs
          .map((doc) => Group.fromFirestore(doc))
          .toList();

      // Sort in memory by last message time
      groups.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return groups;
    });
  }

  // Get group messages stream
  Stream<List<Message>> getGroupMessagesStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
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

  // ==================== GROUP METHODS - INDEX FREE ====================

  // Get all groups where current user is a member - INDEX FREE
  Future<List<Group>> getAllGroups() async {
    if (currentUserId.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: currentUserId)
          .get(); // Removed orderBy

      final groups = snapshot.docs
          .map((doc) => Group.fromFirestore(doc))
          .toList();

      // Sort in memory
      groups.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return groups;
    } catch (e) {
      print('Error getting groups: $e');
      return [];
    }
  }

  // Get recent groups with activity - INDEX FREE
  Future<List<Group>> getRecentGroups() async {
    if (currentUserId.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: currentUserId)
          .get(); // Removed complex query

      final groups = snapshot.docs
          .map((doc) => Group.fromFirestore(doc))
          .where((group) => group.lastMessage != null && group.lastMessage!.isNotEmpty)
          .toList();

      // Sort in memory
      groups.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      return groups.take(20).toList();
    } catch (e) {
      print('Error getting recent groups: $e');
      return [];
    }
  }

  // Create a new group
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
    String? avatar,
  }) async {
    if (currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      // Ensure current user is in members list
      if (!memberIds.contains(currentUserId)) {
        memberIds.add(currentUserId);
      }

      final groupData = {
        'name': name,
        'avatar': avatar,
        'members': memberIds,
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'isMuted': false,
      };

      final docRef = await _firestore.collection('groups').add(groupData);
      return docRef.id;
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    }
  }

  // Get group details by ID
  Future<Group?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (doc.exists) {
        return Group.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting group: $e');
      return null;
    }
  }

  // Update group details
  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? avatar,
    bool? isMuted,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (avatar != null) updates['avatar'] = avatar;
      if (isMuted != null) updates['isMuted'] = isMuted;

      await _firestore.collection('groups').doc(groupId).update(updates);
    } catch (e) {
      print('Error updating group: $e');
      rethrow;
    }
  }

  // Add members to group
  Future<void> addGroupMembers(String groupId, List<String> newMemberIds) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion(newMemberIds),
      });
    } catch (e) {
      print('Error adding members: $e');
      rethrow;
    }
  }

  // Remove member from group
  Future<void> removeGroupMember(String groupId, String memberId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([memberId]),
      });
    } catch (e) {
      print('Error removing member: $e');
      rethrow;
    }
  }

  // Leave group
  Future<void> leaveGroup(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      print('Error leaving group: $e');
      rethrow;
    }
  }

  // Send group message
  Future<void> sendGroupMessage({
    required String groupId,
    required String text,
  }) async {
    try {
      final messageData = {
        'chatId': groupId,
        'senderId': currentUserId,
        'content': text,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'readBy': [currentUserId],
        'isDeleted': false,
        'deletedFor': [],
      };

      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc();
      batch.set(messageRef, messageData);

      final groupRef = _firestore.collection('groups').doc(groupId);
      batch.update(groupRef, {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUserId,
        'unreadCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Error sending group message: $e');
      rethrow;
    }
  }

  // Send media to group
  Future<void> sendGroupMediaMessage({
    required String groupId,
    required File file,
    required String mediaType,
    String? caption,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storageRef = _storage
          .ref()
          .child('group_media')
          .child(groupId)
          .child(fileName);

      await storageRef.putFile(file);
      final mediaUrl = await storageRef.getDownloadURL();
      final fileSize = await file.length();

      final messageData = {
        'chatId': groupId,
        'senderId': currentUserId,
        'content': caption,
        'mediaUrl': mediaUrl,
        'type': mediaType,
        'metadata': {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': mediaType,
          ...?metadata,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'readBy': [currentUserId],
        'isDeleted': false,
        'deletedFor': [],
      };

      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc();
      batch.set(messageRef, messageData);

      final groupRef = _firestore.collection('groups').doc(groupId);
      batch.update(groupRef, {
        'lastMessage': mediaType == 'image' ? '📷 Photo' :
        mediaType == 'video' ? '🎥 Video' :
        mediaType == 'audio' ? '🎵 Audio' : '📎 File',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUserId,
        'unreadCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Error sending group media: $e');
      rethrow;
    }
  }

  // ==================== SEARCH FUNCTIONALITY - INDEX FREE ====================

  // Search messages in a specific chat
  Future<List<Message>> searchMessagesInChat(String chatId, String query) async {
    if (query.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: query + '\uf8ff')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .where((message) => !message.deletedFor.contains(currentUserId))
          .toList();
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }

  // Search users by name or username - FIXED for updated schema
  Future<List<ChatUser>> searchUsers(String query) async {
    if (query.isEmpty || currentUserId.isEmpty) return [];

    try {
      // Search by userName (our updated schema)
      final nameSnapshot = await _firestore
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: query)
          .where('userName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      // Search by email
      final emailSnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get();

      // Combine and remove duplicates
      final Map<String, ChatUser> userMap = {};

      for (var doc in nameSnapshot.docs) {
        if (doc.id != currentUserId) {
          userMap[doc.id] = ChatUser.fromFirestore(doc);
        }
      }

      for (var doc in emailSnapshot.docs) {
        if (doc.id != currentUserId && !userMap.containsKey(doc.id)) {
          userMap[doc.id] = ChatUser.fromFirestore(doc);
        }
      }

      return userMap.values.toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Search groups by name - INDEX FREE
  Future<List<Group>> searchGroups(String query) async {
    if (query.isEmpty || currentUserId.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: currentUserId)
          .get();

      final groups = snapshot.docs
          .map((doc) => Group.fromFirestore(doc))
          .where((group) =>
          group.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return groups;
    } catch (e) {
      print('Error searching groups: $e');
      return [];
    }
  }

  // ==================== CHAT MANAGEMENT ====================

  // Get or create chat between two users
  Future<String> getOrCreateChat(String otherUserId) async {
    if (currentUserId.isEmpty) throw Exception('User not authenticated');

    try {
      // Check if chat already exists
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

      // Create new chat
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

  // Get all users - EXCLUDES CURRENT USER - FIXED for updated schema
  Future<List<ChatUser>> getAllUsers() async {
    if (currentUserId.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .limit(100)
          .get();

      final users = snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => ChatUser.fromFirestore(doc))
          .toList();

      // Sort by userName (updated field name)
      users.sort((a, b) => a.userName.toLowerCase().compareTo(b.userName.toLowerCase()));

      return users;
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // Get recent chat users - INDEX FREE - FIXED for updated schema
  Future<List<ChatUser>> getRecentChatUsers() async {
    if (currentUserId.isEmpty) return [];

    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .limit(50)
          .get();

      final List<MapEntry<ChatUser, DateTime>> recentUsersWithTime = [];

      for (var doc in chatsSnapshot.docs) {
        // Skip chats with no messages
        if (doc['lastMessage'] == null ||
            doc['lastMessage'] == '' ||
            doc['lastMessageTime'] == null) {
          continue;
        }

        final participants = List<String>.from(doc['participants'] ?? []);
        final otherUserId = participants.firstWhere((id) => id != currentUserId);

        if (otherUserId == currentUserId) continue;

        final lastMessageTime = (doc['lastMessageTime'] as Timestamp).toDate();

        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
        if (userDoc.exists) {
          recentUsersWithTime.add(
              MapEntry(ChatUser.fromFirestore(userDoc), lastMessageTime)
          );
        }
      }

      // Sort in memory
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

  // Find user by name or email - FIXED for updated schema
  Future<ChatUser?> findUser({String? name, String? email}) async {
    if (currentUserId.isEmpty) return null;

    try {
      Query query = _firestore.collection('users');

      if (name != null && name.isNotEmpty) {
        // Use userName instead of name (updated schema)
        query = query.where('userName', isEqualTo: name);
      } else if (email != null && email.isNotEmpty) {
        query = query.where('email', isEqualTo: email);
      } else {
        return null;
      }

      final snapshot = await query.limit(1).get();

      if (snapshot.docs.isNotEmpty && snapshot.docs.first.id != currentUserId) {
        return ChatUser.fromFirestore(snapshot.docs.first);
      }

      return null;
    } catch (e) {
      print('Error finding user: $e');
      return null;
    }
  }

  // ==================== MESSAGE OPERATIONS ====================

  // Send text message
  Future<void> sendTextMessage({
    required String chatId,
    required String text,
    required String receiverId,
  }) async {
    try {
      final messageData = {
        'chatId': chatId,
        'senderId': currentUserId,
        'content': text,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'readBy': [currentUserId],
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
    Map<String, dynamic>? metadata,
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
      final fileSize = await file.length();

      final messageData = {
        'chatId': chatId,
        'senderId': currentUserId,
        'content': caption,
        'mediaUrl': mediaUrl,
        'type': mediaType,
        'metadata': {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': mediaType,
          ...?metadata,
        },
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'readBy': [currentUserId],
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
        'lastMessage': mediaType == 'image' ? '📷 Photo' :
        mediaType == 'video' ? '🎥 Video' :
        mediaType == 'audio' ? '🎵 Audio' : '📎 File',
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

  // Mark message as read
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

  // Pin/Unpin chat
  Future<void> togglePinChat(String chatId, bool isPinned) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isPinned': isPinned,
      });
    } catch (e) {
      print('Error toggling pin: $e');
    }
  }

  // Mute/Unmute chat
  Future<void> toggleMuteChat(String chatId, bool isMuted) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'isMuted': isMuted,
      });
    } catch (e) {
      print('Error toggling mute: $e');
    }
  }
}