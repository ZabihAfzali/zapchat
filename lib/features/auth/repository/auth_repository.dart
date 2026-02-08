import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  // Send OTP to phone number (SIMPLIFIED VERSION)
  Future<void> sendOtpToPhone({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      // Format phone number for Firebase (add +33 for France)
      String formattedPhone = _formatPhoneNumber(phoneNumber);

      print('📱 Attempting to send OTP to: $formattedPhone');

      // Use a try-catch to handle billing errors gracefully
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android devices
          print('✅ Auto-verification completed');
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Verification failed: ${e.code} - ${e.message}');

          // Handle billing error specifically
          if (e.code == 'billing-not-enabled' || e.message?.contains('BILLING_NOT_ENABLED') == true) {
            onVerificationFailed(FirebaseAuthException(
              code: 'billing-not-enabled',
              message: 'Phone verification requires billing. Using test mode.',
            ));
          } else {
            onVerificationFailed(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ Verification code sent. ID: ${verificationId.substring(0, 20)}...');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('❌ Exception in sendOtpToPhone: $e');
      rethrow;
    }
  }

  // Verify OTP
  Future<UserCredential> verifyOtp({
    required String otp,
    required String verificationId,
  }) async {
    try {
      print('🔐 Verifying OTP: $otp');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print('❌ OTP verification error: $e');
      rethrow;
    }
  }

  // Format French phone number
  String _formatPhoneNumber(String phoneNumber) {
    // Remove any non-digit characters
    String digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // If it starts with 0, replace with +33
    if (digits.startsWith('0')) {
      digits = '+33${digits.substring(1)}';
    }
    // If it starts with 33, add +
    else if (digits.startsWith('33')) {
      digits = '+$digits';
    }
    // If no country code, assume it's French and add +33
    else if (!digits.startsWith('+')) {
      digits = '+33$digits';
    }

    print('📞 Formatted phone: $digits');
    return digits;
  }

  // Login with email and password
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔑 Attempting login for: $email');
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Login successful: ${userCredential.user!.uid}');
      return userCredential.user!;
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  // Sign up with email, password, and phone
  Future<User> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      print('👤 Creating account for: $email');

      // 1. Create user in Firebase Auth with email/password
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;

      print('✅ Auth user created: ${user.uid}');

      // 2. Update display name
      await user.updateDisplayName(name);

      // 3. Create user document in Firestore
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'formattedPhone': _formatPhoneNumber(phone),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'profilePicture': '',
          'status': 'Hey there! I am using ZapChat',
          'lastSeen': FieldValue.serverTimestamp(),
          'isOnline': true,
        }, SetOptions(merge: true));
        print('✅ Firestore document created');
      } catch (firestoreError) {
        print('⚠️ Firestore error: $firestoreError');
        // Continue even if Firestore fails
      }

      return user;
    } catch (e) {
      print('❌ Signup error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    print('🚪 Logging out');
    await _firebaseAuth.signOut();
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() ?? {};
    } catch (e) {
      print('❌ Error getting user data: $e');
      return {};
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    print('📧 Sending password reset to: $email');
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }
}