import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OtpScreen extends StatefulWidget {
  final String phoneOrEmail; // Show where code was sent
  const OtpScreen({super.key, required this.phoneOrEmail});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final int otpLength = 6;
  late List<TextEditingController> otpControllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    otpControllers =
        List.generate(otpLength, (_) => TextEditingController());
    focusNodes = List.generate(otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in otpControllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < otpLength - 1) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  String get _otp =>
      otpControllers.map((controller) => controller.text).join();

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
                // Logo at top
                Image.asset(
                  'assets/images/snapchat_logo.jpg',
                  height: 60.h,
                ),
                 SizedBox(height: 32.h),
                  
                 Text(
                  'Enter Verification Code',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                  
                 SizedBox(height: 12.h),
                  
                Text(
                  'We sent a 6-digit code to ${widget.phoneOrEmail}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 16),
                ),
                  
                 SizedBox(height: 32.h),
                  
                // OTP Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(otpLength, (index) {
                    return SizedBox(
                      width: 45.w,
                      child: TextField(
                        controller: otpControllers[index],
                        focusNode: focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style:  TextStyle(
                            fontSize: 24.sp, fontWeight: FontWeight.bold),
                        decoration:  InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) => _onOtpChanged(index, value),
                      ),
                    );
                  }),
                ),
                  
                 SizedBox(height: 24.h),
                  
                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: () {
                      // OTP Verification Logic
                      if (_otp.length == otpLength) {
                        // Call cubit or usecase
                        print('OTP entered: $_otp');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter complete OTP')),
                        );
                      }
                    },
                    child: const Text('Verify', style: TextStyle(fontSize: 18)),
                  ),
                ),
                  
                 SizedBox(height: 16.h),
                  
                // Resend / Change
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Resend OTP logic
                      },
                      child: const Text(
                        'Resend code',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back to change phone/email
                      },
                      child: const Text(
                        'Change',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
