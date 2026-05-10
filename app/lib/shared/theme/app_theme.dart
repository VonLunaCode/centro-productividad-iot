import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryVariant,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  // Glassmorphism Decoration Utility
  static BoxDecoration glassDecoration({
    double blur = 16.0,
    double opacity = 0.1,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.0,
      ),
    );
  }
}

// Widget auxiliar para aplicar el efecto de desenfoque de cristal
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.08,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(24);
    
    return ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: AppTheme.glassDecoration(
            blur: blur,
            opacity: opacity,
            borderRadius: effectiveRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
