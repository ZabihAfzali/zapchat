part of 'auth_bloc.dart';

import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

// Initial state
class AuthInitial extends AuthState {}

// Loading state
class AuthLoading extends AuthState {}

// Authenticated state
class Authenticated extends AuthState {
  final String userId;
  final String email;
  final String name;

  const Authenticated({
    required this.userId,
    required this.email,
    required this.name,
  });

  @override
  List<Object> get props => [userId, email, name];
}

// Unauthenticated state
class Unauthenticated extends AuthState {}

// OTP sent state
class OtpSent extends AuthState {
  final String verificationId;
  final String phoneNumber;

  const OtpSent({
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [verificationId, phoneNumber];
}

// OTP verified state
class OtpVerified extends AuthState {}

// Error state
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}