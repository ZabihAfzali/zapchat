import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user data
  Future<Map<String, dynamic>> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data() ?? {};
  }

  // Get friends list
  Future<List<Map<String, dynamic>>> getFriends() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // This is a simplified version - you'll need to implement your own logic
    return [
      {
        'id': '1',
        'name': 'Emma Wilson',
        'lastMessage': 'Sent a snap 📸',
        'time': '2 min ago',
        'unread': true,
        'hasStory': true,
        'isOnline': true,
      },
      {
        'id': '2',
        'name': 'John Smith',
        'lastMessage': 'Hey! How are you doing?',
        'time': '1 hr ago',
        'unread': false,
        'hasStory': false,
        'isOnline': true,
      },
      {
        'id': '3',
        'name': 'Sophia Miller',
        'lastMessage': 'Missed video call 📞',
        'time': '3 hrs ago',
        'unread': true,
        'hasStory': true,
        'isOnline': false,
      },
    ];
  }

  // Get stories
  Future<List<Map<String, dynamic>>> getStories() async {
    return [
      {
        'id': '1',
        'name': 'Emma',
        'isLive': true,
        'isUnseen': true,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      },
      {
        'id': '2',
        'name': 'John',
        'isLive': false,
        'isUnseen': true,
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      },
      {
        'id': '3',
        'name': 'Sophia',
        'isLive': true,
        'isUnseen': false,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      },
    ];
  }

  // Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}