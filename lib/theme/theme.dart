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

  // Radios de forma (identidad Neura).
  static const double _cardRadius = 18;
  static const double _buttonRadius = 12;
  static const double _inputRadius = 12;

  static ThemeData _buildTheme(AppColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? const ColorScheme.dark() : const ColorScheme.light();

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

    final textTheme = _buildTextTheme(c, brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[c],
      scaffoldBackgroundColor: c.canvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.textPrimary,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 20),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 2,
        shadowColor: isDark ? Colors.black.withValues(alpha: 0.4) : c.border,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: c.border),
        ),
        filled: true,
        fillColor: c.surfaceRaised,
        hintStyle: TextStyle(color: c.textMuted),
        labelStyle: TextStyle(color: c.textSecondary),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
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

  /// TextTheme de marca con la fuente por defecto (Material/Roboto):
  /// titulares w800 / -0.5, cuerpo w400-w500.
  static TextTheme _buildTextTheme(AppColors c, Brightness brightness) {
    final t = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;

    TextStyle? heading(TextStyle? s) => s?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: c.textPrimary,
    );

    return t.copyWith(
      displayLarge: heading(t.displayLarge),
      displayMedium: heading(t.displayMedium),
      displaySmall: heading(t.displaySmall),
      headlineLarge: heading(t.headlineLarge),
      headlineMedium: heading(t.headlineMedium),
      headlineSmall: heading(t.headlineSmall),
      titleLarge: heading(t.titleLarge)?.copyWith(fontSize: 22),
      titleMedium: t.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: c.textPrimary,
      ),
      titleSmall: t.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      bodyLarge: t.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: c.textPrimary,
      ),
      bodyMedium: t.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: c.textSecondary,
      ),
      bodySmall: t.bodySmall?.copyWith(
        fontWeight: FontWeight.w400,
        color: c.textMuted,
      ),
      labelLarge: t.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: c.textPrimary,
      ),
    );
  }
}
