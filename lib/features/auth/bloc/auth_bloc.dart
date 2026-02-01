import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zapchat/features/auth/repository/auth_repository.dart';

import 'auth_events.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignupRequested>(_onAuthSignupRequested);
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

      emit(Authenticated(
        userId: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'User',
      ));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _getErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError(message: 'Signup failed. Please try again.'));
    }
  }

  Future<void> _onOtpVerificationRequested(
      AuthOtpVerificationRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    // We'll implement phone verification later
    // For now, just emit authenticated
    final user = authRepository.currentUser;
    if (user != null) {
      emit(Authenticated(
        userId: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'User',
      ));
    } else {
      emit(AuthError(message: 'OTP verification failed'));
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
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}