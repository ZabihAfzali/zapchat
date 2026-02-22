// lib/features/auth/views/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zapchat/core/constants/asset_constants.dart';
import 'package:zapchat/core/routes/route_names.dart';
import 'package:zapchat/features/auth/bloc/auth_bloc.dart';
import 'package:zapchat/features/auth/bloc/auth_state.dart';
import 'package:zapchat/features/auth/views/forgot_password_screen.dart';

import '../../../core/widgets/auth_text_field.dart';
import '../../../core/widgets/auth_top_buttons.dart';
import '../../../core/widgets/social_login_buttons.dart';
import '../bloc/auth_events.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    FocusScope.of(context).unfocus();

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields', isError: true);
      return;
    }

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _handleGoogleSignIn() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(GoogleSignInRequested());
  }

  void _handleFacebookSignIn() {
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(FacebookSignInRequested());
  }

  void _showAccountLinkingDialog(String email, List<String> providers) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Account Already Exists',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('An account with email $email already exists using:'),
            const SizedBox(height: 16),
            ...providers.map((p) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    p.contains('google') ? Icons.g_mobiledata :
                    p.contains('facebook') ? Icons.facebook :
                    p.contains('password') ? Icons.email : Icons.person,
                    color: Colors.black,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    p.replaceAll('.com', '').toUpperCase(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            const Text(
              'Would you like to sign in with that method instead?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Determine which provider to use
              if (providers.contains('google.com')) {
                _handleGoogleSignIn();
              } else if (providers.contains('facebook.com')) {
                _handleFacebookSignIn();
              } else if (providers.contains('password')) {
                // Focus on email field for password sign in
                _emailController.text = email;
                FocusScope.of(context).requestFocus(FocusNode());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              providers.contains('google.com') ? 'Sign in with Google' :
              providers.contains('facebook.com') ? 'Sign in with Facebook' :
              'Sign in with Email',
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          _showSnackBar('Login successful!');
          Navigator.pushReplacementNamed(context, RouteNames.main);
        }

        if (state is AccountLinkingNeeded) {
          _showAccountLinkingDialog(state.email, state.providers);
        }

        if (state is AccountsLinked) {
          _showSnackBar('Accounts linked successfully!');
        }

        if (state is AuthError) {
          _showSnackBar(state.message, isError: true);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFFFFC00), // Snapchat yellow
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(18.r),
              child: Column(
                children: [
                  // Logo
                  Container(
                    margin: EdgeInsets.all(20.r),
                    height: 100.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: SvgPicture.asset(
                      AssetConstants.snapLogoNoBackgroundWhite,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Toggle Buttons
                  Row(
                    children: [
                      TopAuthButton(
                        title: 'Log In',
                        isActive: true,
                        onTap: () {},
                      ),
                      TopAuthButton(
                        title: 'Sign Up',
                        isActive: false,
                        onTap: () =>
                            Navigator.pushNamed(context, RouteNames.signup),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Email Field
                  AuthTextField(
                    hint: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                  ),

                  SizedBox(height: 12.h),

                  // Password Field
                  AuthTextField(
                    hint: 'Password',
                    controller: _passwordController,
                    isPassword: true,
                    enabled: !isLoading,
                  ),

                  SizedBox(height: 26.h),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade800,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: isLoading ? null : _handleLogin,
                      child: isLoading
                          ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Forgot Password
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    ),
                    child: Text(
                      'Forgot your password?',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Google Button
                  DefaultButton(
                    title: 'Continue with Google',
                    image: AssetConstants.googleLogoLight,
                    onPressed: isLoading ? null : _handleGoogleSignIn,
                    buttonColor: Colors.black,
                    buttonTextColor: Colors.white,
                  ),

                  SizedBox(height: 12.h),

                  // Facebook Button
                  DefaultButton(
                    title: 'Continue with Facebook',
                    image: AssetConstants.facebookLight,
                    onPressed: isLoading ? null : _handleFacebookSignIn,
                    buttonColor: Colors.black,
                    buttonTextColor: Colors.white,
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}