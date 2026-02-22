// lib/features/profile/repository/profile_repository.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_model.dart'; // Import your existing UserModel

class ProfileRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  // ==================== GET USER PROFILE ====================

  /// Get user profile data from existing users collection
  Future<Map<String, dynamic>> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      // Create basic user document if it doesn't exist
      final userModel = UserModel.fromAuth(
        uid: user.uid,
        email: user.email!,
        userName: user.displayName,
      );

      await _firestore.collection('users').doc(user.uid).set(
        userModel.toMap(),
        SetOptions(merge: true),
      );

      return userModel.toMap();
    }

    final data = doc.data() ?? {};

    // Return data in the format expected by your profile screen
    return {
      'uid': user.uid,
      'email': user.email,
      'name': data['userName'] ?? data['name'] ?? '', // Handle both field names
      'userName': data['userName'] ?? data['name'] ?? '',
      'phone': data['phoneNumber'] ?? data['phone'] ?? '',
      'phoneNumber': data['phoneNumber'] ?? data['phone'] ?? '',
      'status': data['status'] ?? 'Hey there! I am using ZapChat',
      'country': data['country'] ?? '',
      'gender': data['gender'] ?? 'Male',
      'birthday': data['birthday'],
      'profileImage': data['profileImage'] ?? data['profilePicture'] ?? '',
      'profilePicture': data['profilePicture'] ?? data['profileImage'] ?? '',
      'providers': data['providers'] ?? [],
      'createdAt': data['createdAt'],
      'updatedAt': data['updatedAt'],
      'lastSeen': data['lastSeen'],
      'isOnline': data['isOnline'] ?? true,
    };
  }

  // ==================== UPLOAD PROFILE IMAGE ====================

  /// Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    try {
      // Use a fixed path structure: profile_images/user_uid/timestamp.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage
          .ref()
          .child('profile_images/${user.uid}/profile_$timestamp.jpg');

      // Compress image if needed (you can add image compression here)

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file
      await ref.putFile(imageFile, metadata);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      print('✅ Image uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      rethrow;
    }
  }

  // ==================== UPDATE PROFILE DATA ====================

  /// Update user profile data in the existing users collection
  Future<void> updateProfileData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Map frontend field names to database field names
    final Map<String, dynamic> firestoreData = {};

    // Map common field names
    if (data.containsKey('name')) firestoreData['userName'] = data['name'];
    if (data.containsKey('userName')) firestoreData['userName'] = data['userName'];
    if (data.containsKey('phone')) firestoreData['phoneNumber'] = data['phone'];
    if (data.containsKey('phoneNumber')) firestoreData['phoneNumber'] = data['phoneNumber'];
    if (data.containsKey('status')) firestoreData['status'] = data['status'];
    if (data.containsKey('country')) firestoreData['country'] = data['country'];
    if (data.containsKey('gender')) firestoreData['gender'] = data['gender'];
    if (data.containsKey('birthday')) firestoreData['birthday'] = data['birthday'];

    // Handle profile image
    if (data.containsKey('profileImage')) {
      firestoreData['profileImage'] = data['profileImage'];
      firestoreData['profilePicture'] = data['profileImage']; // Save in both for compatibility
    }
    if (data.containsKey('profilePicture')) {
      firestoreData['profilePicture'] = data['profilePicture'];
      firestoreData['profileImage'] = data['profilePicture'];
    }

    // Add timestamp
    firestoreData['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(firestoreData, SetOptions(merge: true));

      print('✅ Profile data updated successfully in users collection');
    } catch (e) {
      print('❌ Error updating profile data: $e');
      rethrow;
    }
  }

  // ==================== COMPLETE PROFILE UPDATE ====================

  /// Update user profile with optional image upload
  Future<void> updateUserProfile({
    required Map<String, dynamic> profileData,
    File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    String? imageUrl;

    // Upload image if provided
    if (imageFile != null) {
      try {
        imageUrl = await uploadProfileImage(imageFile);
        print('✅ Image uploaded with URL: $imageUrl');
      } catch (e) {
        print('❌ Failed to upload image: $e');
        // Continue without image if upload fails
      }
    }

    // Prepare data for Firestore
    final Map<String, dynamic> dataToSave = {};

    // Map all profile data fields
    if (profileData.containsKey('name')) {
      dataToSave['userName'] = profileData['name'];
    }
    if (profileData.containsKey('userName')) {
      dataToSave['userName'] = profileData['userName'];
    }
    if (profileData.containsKey('phone')) {
      dataToSave['phoneNumber'] = profileData['phone'];
    }
    if (profileData.containsKey('phoneNumber')) {
      dataToSave['phoneNumber'] = profileData['phoneNumber'];
    }
    if (profileData.containsKey('status')) {
      dataToSave['status'] = profileData['status'];
    }
    if (profileData.containsKey('country')) {
      dataToSave['country'] = profileData['country'];
    }
    if (profileData.containsKey('gender')) {
      dataToSave['gender'] = profileData['gender'];
    }
    if (profileData.containsKey('birthday')) {
      dataToSave['birthday'] = profileData['birthday'];
    }

    // Add image URL if available
    if (imageUrl != null) {
      dataToSave['profileImage'] = imageUrl;
      dataToSave['profilePicture'] = imageUrl;
    } else if (profileData.containsKey('profileImage') && profileData['profileImage'] != null) {
      dataToSave['profileImage'] = profileData['profileImage'];
      dataToSave['profilePicture'] = profileData['profileImage'];
    } else if (profileData.containsKey('profilePicture') && profileData['profilePicture'] != null) {
      dataToSave['profilePicture'] = profileData['profilePicture'];
      dataToSave['profileImage'] = profileData['profilePicture'];
    }

    // Add timestamp
    dataToSave['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _firestore.collection('users').doc(user.uid).set(
        dataToSave,
        SetOptions(merge: true),
      );
      print('✅ Profile data saved successfully to users collection');
    } catch (e) {
      print('❌ Error saving profile data: $e');
      rethrow;
    }
  }

  // ==================== USER STORIES (Keep as is) ====================

  /// Get user stories
  Future<List<Map<String, dynamic>>> getUserStories() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting user stories: $e');
      return [];
    }
  }

  // ==================== HELPER METHODS ====================

  /// Check if user profile exists
  Future<bool> profileExists() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      print('Error checking profile existence: $e');
      return false;
    }
  }

  /// Get user model directly
  Future<UserModel?> getUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(user.uid, doc.data() ?? {});
      }
      return null;
    } catch (e) {
      print('Error getting user model: $e');
      return null;
    }
  }

  /// Delete profile image from storage
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract path from URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ Profile image deleted');
    } catch (e) {
      print('❌ Error deleting profile image: $e');
      rethrow;
    }
  }
}