import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  // Login with email and password
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user!;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<User> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;

      // Update display name
      await user.updateDisplayName(name);

      // Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profilePicture': '',
        'status': '',
        'lastSeen': FieldValue.serverTimestamp(),
      });

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? profilePicture,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (phone != null) updateData['phone'] = phone;
    if (profilePicture != null) updateData['profilePicture'] = profilePicture;

    await _firestore.collection('users').doc(userId).update(updateData);

    // Also update Firebase Auth display name
    if (name != null) {
      await _firebaseAuth.currentUser?.updateDisplayName(name);
    }
  }
}