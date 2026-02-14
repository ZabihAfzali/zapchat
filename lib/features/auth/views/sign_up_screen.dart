

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zapchat/features/auth/bloc/auth_bloc.dart';

import '../../../core/constants/asset_constants.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/widgets/auth_text_field.dart';
import '../bloc/auth_events.dart';
import '../bloc/auth_state.dart';

// Signup Screen
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    print('function called');
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthSignupRequested(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
      ),
    );
    print('function called again');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Account created successfully! Please log in.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Navigate back to login screen after delay
          Future.delayed(const Duration(milliseconds: 1500), () {
            Navigator.pop(context);
          });
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFC00), // Snapchat yellow
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.0.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        CupertinoIcons.back,
                        size: 30,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  // Optional Snapchat Ghost at top
                  Container(
                    margin: EdgeInsets.all(20.r),
                    height: 100.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.circular(20.r)),
                    ),
                    child: SvgPicture.asset(
                      AssetConstants.snapLogoNoBackgroundWhite,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Name Field
                  AuthTextField(hint: 'Full Name', controller: nameController),
                  SizedBox(height: 10.h),

                  // Email Field
                  AuthTextField(
                    hint: 'Email',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 10.h),
                  // Phone Field
                  AuthTextField(
                    hint: 'Phone Number (optional for now)',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 10.h),

                  // Password Field
                  AuthTextField(
                    hint: 'Password (min. 6 characters)',
                    controller: passwordController,
                    isPassword: true,
                  ),
                  SizedBox(height: 10.h),

                  // Confirm Password Field
                  AuthTextField(
                    hint: 'Confirm Password',
                    controller: confirmPasswordController,
                    isPassword: true,
                  ),
                  SizedBox(height: 20.h),
                  // Sign Up Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;

                      return GestureDetector(
                        onTap: () {
                          if(isLoading == false){
                            _handleSignUp();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              RouteNames.login,   // the new route
                                  (route) => false,  // remove all previous routes
                            );                          }
                          else{
                            print('is loading :: $isLoading');
                          }
                        },
                        child: Container(
                          height: 50.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.r),
                            color: Colors.black,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : Center(
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 16.h),

                  // Already have account: go to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40.h), // Bottom padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
