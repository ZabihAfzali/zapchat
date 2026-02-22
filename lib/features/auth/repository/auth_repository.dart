// lib/features/auth/repository/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/user_model.dart';

// Custom Exception for account linking
class AccountExistsWithDifferentCredentialException implements Exception {
  final String email;
  final List<String> providers;
  final String message;

  AccountExistsWithDifferentCredentialException({
    required this.email,
    required this.providers,
    required this.message,
  });

  @override
  String toString() => message;
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  // ==================== EMAIL & PASSWORD ====================

  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user!;
      await user.updateDisplayName(name);

      final userModel = UserModel(
        uid: user.uid,
        userName: name,
        email: email,
        phoneNumber: phone,
      );

      await _createUserInFirestore(userModel);
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }

  // ==================== GOOGLE SIGN IN ====================

  Future<User?> signInWithGoogle() async {
    try {
      print('🔵 Attempting Google Sign In');

      await _googleSignIn.initialize();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception('Authenticate not supported');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) {
        print('⚠️ Google Sign In cancelled');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) throw Exception('No ID token');

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      try {
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        final user = userCredential.user!;

        await _handleSocialSignInUser(user);
        return user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          // Handle account linking scenario - use Firestore to get providers
          final providers = await _getProvidersFromFirestore(e.email ?? googleUser.email);
          throw AccountExistsWithDifferentCredentialException(
            email: e.email ?? googleUser.email,
            providers: providers,
            message: 'An account already exists with this email. Please sign in with your original method.',
          );
        }
        rethrow;
      }

    } on GoogleSignInException catch (e) {
      if (e.code.toString().contains('canceled')) return null;
      throw Exception(e.description);
    } catch (e) {
      print('Google Sign In Error: $e');
      return null;
    }
  }

  // ==================== FACEBOOK SIGN IN ====================

  Future<User?> signInWithFacebook() async {
    try {
      print('🔵 Attempting Facebook Sign In');

      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        return null;
      }

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed: ${result.message}');
      }

      final String accessToken = result.accessToken?.tokenString ?? '';
      if (accessToken.isEmpty) throw Exception('Failed to get access token');

      final credential = FacebookAuthProvider.credential(accessToken);

      try {
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        final user = userCredential.user!;
        await _handleSocialSignInUser(user);
        return user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          // Handle account linking scenario - use Firestore to get providers
          final providers = await _getProvidersFromFirestore(e.email ?? '');
          throw AccountExistsWithDifferentCredentialException(
            email: e.email ?? 'unknown',
            providers: providers,
            message: 'An account already exists with this email. Please sign in with your original method.',
          );
        }
        rethrow;
      }

    } catch (e) {
      print('Facebook Sign In Error: $e');
      rethrow;
    }
  }

  // ==================== FIRESTORE METHODS ====================

  /// Create user in Firestore
  Future<void> _createUserInFirestore(UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(userModel.uid).set(
        {
          ...userModel.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'providers': [_getCurrentProvider()],
        },
        SetOptions(merge: true),
      );
      print('✅ User created in Firestore');
    } catch (e) {
      print('❌ Error creating user in Firestore: $e');
      throw Exception('Failed to save user data');
    }
  }

  /// Get current provider
  String _getCurrentProvider() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return 'unknown';

    for (var info in user.providerData) {
      if (info.providerId == 'google.com') return 'google.com';
      if (info.providerId == 'facebook.com') return 'facebook.com';
      if (info.providerId == 'password') return 'email';
    }
    return 'unknown';
  }

  /// Get providers from Firestore (alternative to deprecated fetchSignInMethodsForEmail)
  Future<List<String>> _getProvidersFromFirestore(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final providers = data['providers'] as List<dynamic>?;
        if (providers != null) {
          return providers.map((p) => p.toString()).toList();
        }
      }

      // If not found in Firestore, check Firebase Auth user by trying to get user data
      // This is a fallback - we'll return a default list
      return ['email']; // Default to email
    } catch (e) {
      print('Error getting providers from Firestore: $e');
      return ['email']; // Default to email on error
    }
  }

  /// Handle social sign-in user
  Future<void> _handleSocialSignInUser(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        final userModel = UserModel.fromAuth(
          uid: user.uid,
          email: user.email!,
          userName: user.displayName,
        );

        // Add provider information
        final Map<String, dynamic> userMap = userModel.toMap();
        userMap['providers'] = [user.providerData.first.providerId];

        await _firestore.collection('users').doc(user.uid).set(
          {
            ...userMap,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        print('✅ Created new user in Firestore');
      } else {
        // Update last login and add provider if not exists
        final existingProviders = List<String>.from(userDoc.data()?['providers'] ?? []);
        final currentProvider = user.providerData.first.providerId;

        if (!existingProviders.contains(currentProvider)) {
          existingProviders.add(currentProvider);
        }

        await _firestore.collection('users').doc(user.uid).update({
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
          'providers': existingProviders,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('⚠️ Error handling social user: $e');
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() ?? {};
    } catch (e) {
      print('Error getting user data: $e');
      return {};
    }
  }

  // ==================== ACCOUNT LINKING ====================

  /// Link Facebook account to existing user
  Future<User> linkFacebookAccount() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw Exception('Facebook login failed');
      }

      final String accessToken = result.accessToken?.tokenString ?? '';
      final credential = FacebookAuthProvider.credential(accessToken);

      final userCredential = await currentUser.linkWithCredential(credential);

      // Update Firestore to show both providers
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'providers': FieldValue.arrayUnion(['facebook.com']),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user!;
    } catch (e) {
      print('Error linking Facebook: $e');
      rethrow;
    }
  }

  /// Link Google account to existing user
  Future<User> linkGoogleAccount() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      await _googleSignIn.initialize();
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();

      if (googleUser == null) throw Exception('Google sign in cancelled');

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await currentUser.linkWithCredential(credential);

      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'providers': FieldValue.arrayUnion(['google.com']),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user!;
    } catch (e) {
      print('Error linking Google: $e');
      rethrow;
    }
  }

  // ==================== LOGOUT ====================

  Future<void> logout() async {
    try {
      // Update online status
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      await _googleSignIn.signOut();
      await _facebookAuth.logOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // ==================== ERROR HANDLING ====================

  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No account found with this email.');
      case 'wrong-password':
        return Exception('Incorrect password.');
      case 'email-already-in-use':
        return Exception('Email already registered.');
      case 'weak-password':
        return Exception('Password must be at least 6 characters.');
      case 'invalid-email':
        return Exception('Invalid email address.');
      case 'account-exists-with-different-credential':
        return Exception('An account already exists with this email using a different sign-in method.');
      default:
        return Exception(e.message ?? 'Authentication failed');
    }
  }
}