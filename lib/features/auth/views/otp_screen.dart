import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zapchat/features/auth/bloc/auth_bloc.dart';

import '../bloc/auth_events.dart';
import '../bloc/auth_state.dart';

class OtpScreen extends StatefulWidget {
  final String phoneOrEmail; // Show where code was sent
  final String? verificationId; // For OTP verification

  const OtpScreen({
    super.key,
    required this.phoneOrEmail,
    this.verificationId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final int otpLength = 6;
  late List<TextEditingController> otpControllers;
  late List<FocusNode> focusNodes;
  String? _verificationId;
  bool _isResendEnabled = false;
  int _resendTimer = 30;

  @override
  void initState() {
    super.initState();
    otpControllers = List.generate(otpLength, (_) => TextEditingController());
    focusNodes = List.generate(otpLength, (_) => FocusNode());
    _verificationId = widget.verificationId;

    // Start resend timer
    _startResendTimer();
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

    // Auto verify when all fields are filled
    if (_getOtp().length == otpLength && _verificationId != null) {
      _handleVerify();
    }
  }

  String _getOtp() => otpControllers.map((controller) => controller.text).join();

  void _handleVerify() {
    final otp = _getOtp();

    if (otp.length != otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification ID missing. Please resend OTP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthOtpVerificationRequested(
        otp: otp,
        verificationId: _verificationId!,
      ),
    );
  }

  void _handleResendOtp() {
    if (!_isResendEnabled) return;

    context.read<AuthBloc>().add(
      AuthSendOtpRequested(phoneNumber: widget.phoneOrEmail),
    );

    // Reset timer
    setState(() {
      _isResendEnabled = false;
      _resendTimer = 30;
    });

    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _resendTimer--;
          if (_resendTimer <= 0) {
            _isResendEnabled = true;
          } else {
            _startResendTimer();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is OtpSent) {
          setState(() {
            _verificationId = state.verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully!'),
              backgroundColor: Colors.green,
            ),
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

        if (state is OtpVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFFFFFC00), // Snapchat yellow
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.sp),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 10.h),
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(CupertinoIcons.back, size: 30),
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

                  SizedBox(height: 8.h),

                  // Show formatted phone number
                  Text(
                    'Formatted for Firebase: +33${widget.phoneOrEmail.replaceAll(RegExp(r'[^0-9]'), '').substring(1)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 24.h),

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
                          style: TextStyle(
                              fontSize: 24.sp, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            border: const OutlineInputBorder(
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
                          onPressed: isLoading ? null : _handleVerify,
                          child: isLoading
                              ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Verify',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 16.h),

                  // Resend / Change
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _isResendEnabled ? _handleResendOtp : null,
                        child: Text(
                          _isResendEnabled
                              ? 'Resend code'
                              : 'Resend code ($_resendTimer)',
                          style: TextStyle(
                            color: _isResendEnabled ? Colors.black : Colors.black54,
                          ),
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

                  SizedBox(height: 20.h),

                  // Testing information
                  if (_verificationId != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        'Verification ID: ${_verificationId!.substring(0, 20)}...',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}