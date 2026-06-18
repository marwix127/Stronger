import 'package:flutter/material.dart';
import 'package:stronger/theme/app_colors.dart';

/// Temas de la app. [lightTheme] y [darkTheme] comparten la misma estructura
/// (construida por [_buildTheme]); solo cambian los tokens de [AppColors].
class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme =
      _buildTheme(AppColors.light, Brightness.light);
  static final ThemeData darkTheme =
      _buildTheme(AppColors.dark, Brightness.dark);

  static ThemeData _buildTheme(AppColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base =
        isDark ? const ColorScheme.dark() : const ColorScheme.light();

    final colorScheme = base.copyWith(
      primary: c.accent, // cyan — acento primario
      onPrimary: c.onAccent,
      primaryContainer: c.surfaceRaised,
      onPrimaryContainer: c.textPrimary,
      secondary: c.surfaceRaised, // neutral elevado
      onSecondary: c.textPrimary,
      secondaryContainer: c.surface,
      onSecondaryContainer: c.textSecondary,
      tertiary: c.accent,
      onTertiary: c.onAccent,
      tertiaryContainer: c.surfaceRaised,
      onTertiaryContainer: c.textPrimary,
      error: c.error,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      surfaceContainerHighest: c.surfaceRaised,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[c],
      scaffoldBackgroundColor: c.canvas,
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: c.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: c.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          letterSpacing: 0.15,
          color: c.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          letterSpacing: 0.25,
          color: c.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 2,
        shadowColor: isDark ? Colors.black.withValues(alpha: 0.4) : c.border,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: c.surfaceRaised,
        hintStyle: TextStyle(color: c.textMuted),
        labelStyle: TextStyle(color: c.textSecondary),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        elevation: 0,
      ),
      iconTheme: IconThemeData(color: c.textSecondary, size: 24),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? c.onAccent : c.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.accent
              : c.surfaceRaised,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : c.textMuted,
        ),
      ),
    );
  }
}
