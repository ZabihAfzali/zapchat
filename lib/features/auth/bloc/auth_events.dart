// lib/features/auth/bloc/auth_event.dart

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class AuthSignupRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String? phone;
  const AuthSignupRequested({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });
  @override
  List<Object?> get props => [name, email, password, phone];
}

class GoogleSignInRequested extends AuthEvent {}
class FacebookSignInRequested extends AuthEvent {}

class LinkAccountsRequested extends AuthEvent {
  final String email;
  final String providerToLink; // 'google' or 'facebook'
  const LinkAccountsRequested({
    required this.email,
    required this.providerToLink,
  });
  @override
  List<Object?> get props => [email, providerToLink];
}

class AuthLogoutRequested extends AuthEvent {}
class CheckAuthStatus extends AuthEvent {}