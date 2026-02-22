import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StoriesRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

// Get all user's active stories (last 24 hours)
  Future<List<Map<String, dynamic>>> getUserStories() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: user.uid)
          .get();

      final now = DateTime.now();
      final activeStories = snapshot.docs.where((doc) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        return timestamp != null && now.difference(timestamp).inHours < 24;
      }).toList();

      // Sort by timestamp (newest first)
      activeStories.sort((a, b) {
        final aTime = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      return activeStories.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting user stories: $e');
      return [];
    }
  }

// Get all friends' stories with seen status
  Future<List<Map<String, dynamic>>> getFriendsStories() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final usersSnapshot = await _firestore
          .collection('users')
          .limit(20)
          .get();

      List<Map<String, dynamic>> friendsWithStories = [];

      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        if (userId == currentUser.uid) continue;

        final storiesSnapshot = await _firestore
            .collection('stories')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

        if (storiesSnapshot.docs.isEmpty) continue;

        final userData = userDoc.data();
        final List<Map<String, dynamic>> stories = [];
        bool allSeen = true;

        for (var doc in storiesSnapshot.docs) {
          final storyData = doc.data();
          final viewedBy = storyData['viewedBy'] as List? ?? [];
          final isSeen = viewedBy.contains(currentUser.uid);

          if (!isSeen) allSeen = false;

          stories.add({
            'id': doc.id,
            ...storyData,
            'isSeen': isSeen,
          });
        }

        friendsWithStories.add({
          'userId': userId,
          'name': userData['displayName'] ?? userData['name'] ?? 'Friend',
          'profileImage': userData['profileImage'],
          'stories': stories,
          'isUnseen': !allSeen, // True if any story is unseen
        });
      }

      return friendsWithStories;
    } catch (e) {
      print('Error getting friends stories: $e');
      return [];
    }
  }

// Upload a new story with better error handling
  Future<void> uploadStory({
    required File mediaFile,
    String? caption,
    required String mediaType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Use appropriate file extension based on media type
      final extension = mediaType == 'video' ? '.mp4' : '.jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
      final ref = _storage.ref().child('stories/$fileName');

      // Create metadata
      final metadata = SettableMetadata(
        contentType: mediaType == 'video' ? 'video/mp4' : 'image/jpeg',
        customMetadata: {
          'userId': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Configure upload task with retry
      final uploadTask = ref.putFile(mediaFile, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      }, onError: (error) {
        print('Upload error: $error');
        throw error;
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final mediaUrl = await snapshot.ref.getDownloadURL();

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Save to Firestore
      await _firestore.collection('stories').add({
        'userId': user.uid,
        'userName': userData['displayName'] ?? user.displayName ?? 'User',
        'userImage': userData['profileImage'],
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'caption': caption ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'viewedBy': [], // Initialize empty array for viewers
      });

      print('Story uploaded successfully');
    } catch (e) {
      print('Error uploading story: $e');
      throw Exception('Failed to upload story: $e');
    }
  }

  // Add this method to handle upload with timeout
  Future<void> uploadStoryWithTimeout({
    required File mediaFile,
    String? caption,
    required String mediaType,
  }) async {
    try {
      await uploadStory(
        mediaFile: mediaFile,
        caption: caption,
        mediaType: mediaType,
      ).timeout(
        const Duration(minutes: 5), // 5 minute timeout for videos
        onTimeout: () {
          throw Exception('Upload timed out. Please try again.');
        },
      );
    } catch (e) {
      print('Upload failed: $e');
      rethrow;
    }
  }

  // Mark story as seen
// Add this method to your StoriesRepository class

// Mark story as seen
  Future<void> markStoryAsSeen(String storyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final storyRef = _firestore.collection('stories').doc(storyId);
      await storyRef.update({
        'viewedBy': FieldValue.arrayUnion([user.uid]),
      });
      print('Story $storyId marked as seen by ${user.uid}');
    } catch (e) {
      print('Error marking story as seen: $e');
    }
  }}