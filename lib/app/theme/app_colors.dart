import 'package:flutter/material.dart';

/// Central design tokens taken from the UI reference (UI.png).
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF00BFA5);
  static const Color primaryPressed = Color(0xFF00A88F);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color primarySoft = Color(0xFFE0F7F2);

  // Light theme
  static const Color lightScaffold = Color(0xFFF5F7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF333333);
  static const Color lightTextSecondary = Color(0xFF7B8794);
  static const Color lightOutline = Color(0xFFDDE0E3);
  static const Color lightChip = Color(0xFFF0F2F5);

  // Dark theme
  static const Color darkScaffold = Color(0xFF10151A);
  static const Color darkSurface = Color(0xFF1A2129);
  static const Color darkCard = Color(0xFF1E262E);
  static const Color darkText = Color(0xFFECF1F4);
  static const Color darkTextSecondary = Color(0xFF93A2AE);
  static const Color darkOutline = Color(0xFF2C3640);

  // Media viewer is always dark, like the reference.
  static const Color viewerBackground = Color(0xFF0B0F13);

  static const Color success = Color(0xFF2E9E6B);
  static const Color danger = Color(0xFFE05B4B);
}
