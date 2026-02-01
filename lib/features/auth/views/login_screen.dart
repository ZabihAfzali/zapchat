import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zapchat/features/auth/views/sign_up_screen.dart';

import '../../../core/widgets/auth_text_field.dart';
import '../../../core/widgets/auth_top_buttons.dart';
import '../../../core/widgets/social_login_buttons.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFC00), // Snapchat yellow
      body: Padding(
        padding:  EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Snapchat logo
            Image.asset(
              'assets/images/snapchat_logo.jpg',
              height: 80.h,
            ),
             SizedBox(height: 28.h),

            // LOGIN / SIGNUP TOGGLE BUTTONS
            Row(
              children: [
                Expanded(
                  child: TopAuthButton(
                    title: 'Log In',
                    isActive: true,
                    onTap: () {},
                  ),
                ),
                 SizedBox(width: 12.w),
                Expanded(
                  child: TopAuthButton(
                    title: 'Sign Up',
                    isActive: false,
                    onTap: () {
                      // Navigate to signup screen later
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpScreen()));
                    },
                  ),
                ),
              ],
            ),
             SizedBox(height: 24.h),

            // EMAIL TEXT FIELD
            AuthTextField(
              hint: 'Email or Username',
              controller: emailController,
            ),
             SizedBox(height: 12.h),

            // PASSWORD TEXT FIELD
            AuthTextField(
              hint: 'Password',
              controller: passwordController,
              isPassword: true,
            ),
             SizedBox(height: 26.h),

            // LOGIN BUTTON
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                onPressed: () {

                },
                child: const Text('Log In'),
              ),
            ),

             SizedBox(height: 12.h),

            // FORGOT PASSWORD CENTERED BELOW LOGIN BUTTON
            TextButton(
              onPressed: () {
                // Handle forgot password
              },
              child: const Text(
                'Forgot your password?',
                style: TextStyle(color: Colors.black),
              ),
            ),
             SizedBox(height: 24.h),

            const Text(
              'or continue with',
              style: TextStyle(color: Colors.black54),
            ),

             SizedBox(height: 16.h),

// GOOGLE
            SocialLoginButton(
              text: 'Continue with Google',
              icon: Icons.g_mobiledata,
              onTap: () {
              },
            ),

             SizedBox(height: 12.h),

// FACEBOOK
            SocialLoginButton(
              text: 'Continue with Facebook',
              icon: Icons.facebook,
              onTap: () {
              },
            ),

          ],
        ),
      ),
    );
  }
}
