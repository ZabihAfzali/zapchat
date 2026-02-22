// lib/features/auth/bloc/auth_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repository/auth_repository.dart';
import '../models/user_model.dart';
import 'auth_events.dart';
import 'auth_state.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<FacebookSignInRequested>(_onFacebookSignInRequested);
    on<LinkAccountsRequested>(_onLinkAccountsRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      add(CheckAuthStatus());
    });

    add(CheckAuthStatus());
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      final userData = await _authRepository.getUserData(user.uid);
      emit(Authenticated(user, userData));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onSignupRequested(
      AuthSignupRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUp(
        name: event.name,
        email: event.email,
        password: event.password,
        phone: event.phone,
      );
      final userData = await _authRepository.getUserData(user.uid);
      emit(Authenticated(user, userData));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onGoogleSignInRequested(
      GoogleSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        final userData = await _authRepository.getUserData(user.uid);
        emit(Authenticated(user, userData));
      } else {
        emit(Unauthenticated());
      }
    } on AccountExistsWithDifferentCredentialException catch (e) {
      // Emit a special state for account linking
      emit(AccountLinkingNeeded(
        email: e.email,
        providers: e.providers,
        message: e.message,
      ));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onFacebookSignInRequested(
      FacebookSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithFacebook();
      if (user != null) {
        final userData = await _authRepository.getUserData(user.uid);
        emit(Authenticated(user, userData));
      } else {
        emit(Unauthenticated());
      }
    } on AccountExistsWithDifferentCredentialException catch (e) {
      // Emit a special state for account linking
      emit(AccountLinkingNeeded(
        email: e.email,
        providers: e.providers,
        message: e.message,
      ));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLinkAccountsRequested(
      LinkAccountsRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      User? user;
      if (event.providerToLink == 'google') {
        user = await _authRepository.linkGoogleAccount();
      } else if (event.providerToLink == 'facebook') {
        user = await _authRepository.linkFacebookAccount();
      }

      if (user != null) {
        final userData = await _authRepository.getUserData(user.uid);
        emit(AccountsLinked());
        emit(Authenticated(user, userData));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event,
      Emitter<AuthState> emit,
      ) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      final userData = await _authRepository.getUserData(user.uid);
      emit(Authenticated(user, userData));
    } else {
      emit(Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}