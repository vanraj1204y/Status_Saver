import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Builds the light and dark [ThemeData] used across the app.
///
/// The theme system is intentionally centralized so additional themes can be
/// added later by composing a new [ThemeData] here and exposing it through
/// the settings screen.
abstract final class AppTheme {
  static const String headingFont = 'Poppins';

  static TextTheme _textTheme(Color text, Color secondary) {
    return TextTheme(
      headlineMedium: TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w700,
          fontSize: 26,
          color: text),
      titleLarge: TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: text),
      titleMedium: TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: text),
      titleSmall: TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: text),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: text),
      bodySmall: TextStyle(fontSize: 12, height: 1.35, color: secondary),
      labelLarge: TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: text),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
    );
  }

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scaffold: AppColors.lightScaffold,
        surface: AppColors.lightSurface,
        card: AppColors.lightSurface,
        text: AppColors.lightText,
        textSecondary: AppColors.lightTextSecondary,
        outline: AppColors.lightOutline,
        chip: AppColors.lightChip,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scaffold: AppColors.darkScaffold,
        surface: AppColors.darkSurface,
        card: AppColors.darkCard,
        text: AppColors.darkText,
        textSecondary: AppColors.darkTextSecondary,
        outline: AppColors.darkOutline,
        chip: AppColors.darkSurface,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color card,
    required Color text,
    required Color textSecondary,
    required Color outline,
    required Color chip,
  }) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: chip,
      outline: outline,
      outlineVariant: outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      cardColor: card,
      dividerColor: outline,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(text, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: headingFont,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: text,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: headingFont,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primary : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : textSecondary,
            )),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontFamily: headingFont, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: AppColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontFamily: headingFont, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
              fontFamily: headingFont, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : null),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? const Color(0xFF2B3138) : AppColors.darkCard,
        contentTextStyle: const TextStyle(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: text),
        contentTextStyle: TextStyle(fontSize: 14.5, height: 1.45, color: text),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: null,
        dividerColor: Colors.transparent,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        titleTextStyle: TextStyle(
            fontFamily: headingFont,
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: text),
        subtitleTextStyle: TextStyle(fontSize: 12.5, color: textSecondary),
      ),
    );
  }
}
