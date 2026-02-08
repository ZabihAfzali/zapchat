

// AuthWrapper will decide which screen to show based on auth state
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zapchat/core/screens/splash_screen.dart';
import 'package:zapchat/features/chat/views/chat_list_screen.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/home/views/main_screen.dart';
import '../../main.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Show loading while checking auth state
        if (state is AuthLoading) {
          return const SplashScreen();
        }

        // If authenticated, show main app (we'll implement later)
        if (state is Authenticated) {
          return const ChatListScreen(); // We'll create this later
        }

        // If not authenticated, show login screen
        return const LoginScreen();
      },
    );
  }
}