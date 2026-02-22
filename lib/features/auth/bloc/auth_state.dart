// lib/features/auth/bloc/auth_state.dart

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Unauthenticated extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final Map<String, dynamic> userData;
  const Authenticated(this.user, this.userData);
  @override
  List<Object?> get props => [user.uid, userData];
}

class AccountLinkingNeeded extends AuthState {
  final String email;
  final List<String> providers;
  final String message;
  const AccountLinkingNeeded({
    required this.email,
    required this.providers,
    required this.message,
  });
  @override
  List<Object?> get props => [email, providers, message];
}

class AccountsLinked extends AuthState {
  final String message;
  const AccountsLinked({this.message = 'Accounts linked successfully!'});
  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}