import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zapchat/core/constants/asset_constants.dart';
import 'package:zapchat/core/routes/route_names.dart';
import 'package:zapchat/features/auth/bloc/auth_bloc.dart';
import 'package:zapchat/features/auth/views/sign_up_screen.dart';
import 'package:zapchat/features/auth/views/forgot_password_screen.dart';

import '../../../core/widgets/auth_text_field.dart';
import '../../../core/widgets/auth_top_buttons.dart';
import '../../../core/widgets/social_login_buttons.dart';
import '../bloc/auth_events.dart';
import '../bloc/auth_state.dart';

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

  void _handleLogin() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: emailController.text.trim(),
        password: passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Navigate to MainScreen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
                (route) => false,
          );
        }

        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFC00), // Snapchat yellow
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Snapchat logos
                  Container(
                    margin: EdgeInsets.all(20.r),
                    height: 100.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(20.r))
                    ),
                    child: SvgPicture.asset(
                      AssetConstants.snapLogoNoBackgroundWhite,
                      height: 100.h,
                      width: 100.w,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // LOGIN / SIGNUP TOGGLE BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                    children: [
                      TopAuthButton(
                        title: 'Log In',
                        isActive: true,
                        onTap: () {},
                      ),
                      SizedBox(width: 12.w),
                      TopAuthButton(
                        title: 'Sign Up',
                        isActive: false,
                        onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpScreen()));
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // EMAIL TEXT FIELD
                  AuthTextField(
                    hint: 'Email',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
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
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;

                      return SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: isLoading ? null : _handleLogin,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                              : const Text('Log In'),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 12.h),

                  // FORGOT PASSWORD CENTERED BELOW LOGIN BUTTON
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot your password?',
                      style: TextStyle(
                          color: Colors.black,
                        fontSize: 15.sp,

                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                   Text(
                    'or continue with',
                    style: TextStyle(
                        color: Colors.black54,
                      fontSize: 16.sp,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // GOOGLE

                  DefaultButton(
                    title: 'Continue with Google',
                    image: AssetConstants.googleLogoLight,
                    onPressed: (){
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Google Sign In coming soon'),
                        ),
                      );
                    },
                    buttonColor: Colors.black,
                    buttonTextColor: Colors.white,
                  ),
                  // SocialLoginButton(
                  //   text: 'Continue with Google',
                  //   image: AssetConstants.googleLogoLight,
                  //   onTap: () {
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       const SnackBar(
                  //         content: Text('Google Sign In coming soon'),
                  //       ),
                  //     );
                  //   },
                  // ),

                  SizedBox(height: 12.h),

                  // FACEBOOK

                  DefaultButton(
                      title: 'Continue with Facebook',
                      image: AssetConstants.facebookLight,
                      onPressed: (){
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Facebook Sign In coming soon'),
                          ),
                        );
                      },
                      buttonColor: Colors.black,
                      buttonTextColor: Colors.white,
                  ),
                  // SocialLoginButton(
                  //   text: 'Continue with Facebook',
                  //   image: AssetConstants.facebookLight,
                  //   onTap: () {
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       const SnackBar(
                  //         content: Text('Facebook Sign In coming soon'),
                  //       ),
                  //     );
                  //   },
                  // ),

                  SizedBox(height: 40.h), // Add bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}