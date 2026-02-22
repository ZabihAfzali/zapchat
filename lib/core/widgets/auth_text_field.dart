import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthTextField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final bool enabled; // Added enabled parameter

  const AuthTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.enabled = true, // Default to true
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: widget.keyboardType,
      cursorColor: Colors.black,
      enabled: widget.enabled, // Use enabled parameter
      style: TextStyle(
        color: widget.enabled ? Colors.black : Colors.black54, // Dim text when disabled
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: widget.enabled ? Colors.black54 : Colors.black26, // Dim hint when disabled
          fontSize: 15.sp,
        ),
        filled: true,
        fillColor: widget.enabled ? Colors.white70 : Colors.grey.shade200, // Change background when disabled
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        suffixIcon: widget.isPassword
            ? IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minHeight: 24.h,
            minWidth: 24.w,
          ),
          icon: Icon(
            _obscureText
                ? CupertinoIcons.eye_slash
                : CupertinoIcons.eye,
            color: widget.enabled ? Colors.black54 : Colors.black26, // Dim icon when disabled
            size: 22.sp,
          ),
          onPressed: widget.enabled ? () { // Only allow toggle when enabled
            setState(() {
              _obscureText = !_obscureText;
            });
          } : null, // Disable button when text field is disabled
        )
            : null,
      ),
    );
  }
}