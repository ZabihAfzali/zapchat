import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

// Check if user is already logged in
class AuthCheckRequested extends AuthEvent {}

// User login event
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

// User signup event
class AuthSignupRequested extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;

  const AuthSignupRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  List<Object> get props => [name, email, phone, password];
}

// Send OTP to phone
class AuthSendOtpRequested extends AuthEvent {
  final String phoneNumber;

  const AuthSendOtpRequested({required this.phoneNumber});

  @override
  List<Object> get props => [phoneNumber];
}

// OTP verification event
class AuthOtpVerificationRequested extends AuthEvent {
  final String otp;
  final String verificationId;

  const AuthOtpVerificationRequested({
    required this.otp,
    required this.verificationId,
  });

  @override
  List<Object> get props => [otp, verificationId];
}

// Logout event
class AuthLogoutRequested extends AuthEvent {}

// Password reset event
class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object> get props => [email];
}