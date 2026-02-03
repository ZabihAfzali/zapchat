import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapchat/features/auth/repository/auth_repository.dart';

import 'auth_events.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignupRequested>(_onAuthSignupRequested);
    on<AuthSendOtpRequested>(_onSendOtpRequested);
    on<AuthOtpVerificationRequested>(_onOtpVerificationRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final user = authRepository.currentUser;

      if (user != null) {
        emit(Authenticated(
          userId: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'User',
        ));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to check authentication status'));
    }
  }

  Future<void> _onAuthLoginRequested(
      AuthLoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final user = await authRepository.login(
        email: event.email,
        password: event.password,
      );

      emit(Authenticated(
        userId: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'User',
      ));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _getErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(message: 'Login failed. Please try again.'));
    }
  }

  Future<void> _onAuthSignupRequested(
      AuthSignupRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final user = await authRepository.signUp(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
      );

      // Emit authenticated state
      emit(Authenticated(
        userId: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'User',
      ));

      // Do NOT send OTP here - let the UI handle it
      // The SignUpScreen listener will handle OTP sending separately

    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _getErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(message: 'Signup failed. Please try again.'));
    }
  }

  Future<void> _onSendOtpRequested(
      AuthSendOtpRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    // Use a completer to handle async callbacks properly
    final completer = Completer<void>();

    await authRepository.sendOtpToPhone(
      phoneNumber: event.phoneNumber,
      onCodeSent: (verificationId) {
        if (!completer.isCompleted) {
          emit(OtpSent(
            verificationId: verificationId,
            phoneNumber: event.phoneNumber,
          ));
          completer.complete();
        }
      },
      onVerificationFailed: (error) {
        if (!completer.isCompleted) {
          emit(AuthError(message: 'Failed to send OTP: ${error.message}'));
          completer.complete();
        }
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        // Just store it, no state change needed
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    // Wait for callback to complete
    await completer.future.timeout(const Duration(seconds: 30), onTimeout: () {
      emit(AuthError(message: 'OTP request timeout. Please try again.'));
    });
  }

  Future<void> _onOtpVerificationRequested(
      AuthOtpVerificationRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final userCredential = await authRepository.verifyOtp(
        otp: event.otp,
        verificationId: event.verificationId,
      );

      final user = userCredential.user;
      if (user != null) {
        emit(Authenticated(
          userId: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'User',
        ));
      } else {
        emit(AuthError(message: 'OTP verification failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _getErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(message: 'OTP verification failed. Please try again.'));
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      await authRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Logout failed'));
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'invalid-verification-code':
        return 'Invalid OTP code.';
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later.';
      case 'provider-already-linked':
        return 'Phone number already linked to another account.';
      case 'billing-not-enabled':
        return 'Phone verification requires billing to be enabled. Please use test mode or enable billing.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}