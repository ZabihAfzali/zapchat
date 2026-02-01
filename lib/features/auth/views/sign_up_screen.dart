import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zapchat/features/auth/views/otp_screen.dart';

import '../../../core/widgets/auth_text_field.dart';


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

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFC00), // Snapchat yellow
        body: Padding(
          padding:  EdgeInsets.symmetric(horizontal: 8.sp),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 10.h,),
                Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                      onTap: (){
                        Navigator.pop(context);
                      },
                      child:
                      Icon(CupertinoIcons.back,size: 30,),
                  ),
                ),
                 SizedBox(height: 10.h),
      
                // Optional Snapchat Ghost at top
                Image.asset(
                  'assets/images/snapchat_logo.jpg',
                  height: 80,
                ),
                 SizedBox(height: 32.h),
      
                 Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
      
                const SizedBox(height: 24),
      
                // Name Field
                AuthTextField(
                  hint: 'Full Name',
                  controller: nameController,
                ),
                const SizedBox(height: 12),
      
                // Email Field
                AuthTextField(
                  hint: 'Email',
                  controller: emailController,
                ),
                const SizedBox(height: 12),
      
                // Phone Field
                AuthTextField(
                  hint: 'Phone Number',
                  controller: phoneController,
                ),
                const SizedBox(height: 12),
      
                // Password Field
                AuthTextField(
                  hint: 'Password',
                  controller: passwordController,
                  isPassword: true,
                ),
      
                const SizedBox(height: 24),
      
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context)=>OtpScreen(phoneOrEmail: phoneController.text,)));
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
      
                const SizedBox(height: 16),
      
                // Already have account: go to login
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Already have an account? Log In',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
      
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
