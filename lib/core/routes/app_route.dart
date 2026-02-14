import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zapchat/core/routes/route_names.dart';

import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/sign_up_screen.dart';
import '../../features/home/views/main_screen.dart';
import '../screens/auth_wrapper.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {

    // -------- AUTH --------
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());

    // -------- MAIN --------
      case RouteNames.main:
        return MaterialPageRoute(builder: (_) => const MainScreen());


    // Add more cases here...

      default:
        return _errorRoute('Route not found');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.redAccent, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
