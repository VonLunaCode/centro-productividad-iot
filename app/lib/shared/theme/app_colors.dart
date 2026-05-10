import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF000000); // AMOLED
  static const Color surface = Color(0xFF121212); // Slightly lighter for cards
  
  // Primary Palette (Purples)
  static const Color primary = Color(0xFF7B2FBE);
  static const Color primaryVariant = Color(0xFF4A00E0);
  
  // Accent Colors
  static const Color accent = Color(0xFF00E5FF); // Teal/Cyan for highlights
  static const Color error = Color(0xFFFF5252);
  static const Color success = Color(0xFF69F0AE);
  
  // Glassmorphism helpers
  static const Color glassBase = Color(0x1AFFFFFF); // 10% White
  static const Color glassBorder = Color(0x33FFFFFF); // 20% White
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% White
}
