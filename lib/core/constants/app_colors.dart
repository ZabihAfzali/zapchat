import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Snapchat Yellow/Black Theme)
  static const Color primary = Color(0xFFFFFC00); // Snapchat Yellow
  static const Color secondary = Color(0xFF000000); // Black
  static const Color accent = Color(0xFFFF0050); // Pink/Red for notifications

  // Background Colors
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color card = Color(0xFF252525);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF6D6D6D);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // UI Elements
  static const Color divider = Color(0xFF3A3A3A);
  static const Color border = Color(0xFF404040);
  static const Color shadow = Color(0x1A000000);

  // Chat Colors
  static const Color sentMessage = Color(0xFF2B5278);
  static const Color receivedMessage = Color(0xFF2F3437);
  static const Color storyRing = Color(0xFFFF0050);
  static const Color onlineStatus = Color(0xFF4CAF50);

  // Gradients
  static const List<Color> storyGradient = [
    Color(0xFFFF0050),
    Color(0xFFFF5C00),
    Color(0xFFFFFC00),
  ];

  // Transparent Colors
  static const Color transparent = Colors.transparent;
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color black50 = Color(0x80000000);
}