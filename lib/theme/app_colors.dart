import 'package:flutter/material.dart';

/// Tokens de color de Stronger (identidad "Neura").
///
/// Es un [ThemeExtension] con dos instancias —[light] y [dark]— que comparten
/// los **mismos nombres** de token con distintos valores. Así las pantallas
/// nunca necesitan saber en qué modo están: leen los tokens vía
/// `AppColors.of(context)` y obtienen el valor correcto según el tema activo.
///
/// Reglas de uso:
///  - El cyan ([accent]) es acento, no fondo: botón primario, estados activos,
///    métricas destacadas, anillos de progreso e iconos activos.
///  - El resto de la UI en superficies neutras para que el cyan resalte.
///  - [accentGlow] solo luce en dark; en light queda vacío (apóyate en sombra).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color canvas; // fondo base / Scaffold
  final Color surface; // cards, sheets
  final Color surfaceRaised; // elementos elevados / fills
  final Color border; // bordes/dividers sutiles
  final Color accent; // electric cyan — acento primario
  final Color onAccent; // texto/icono sobre cyan
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color error;

  /// Gradiente de marca para headers/hero.
  final Gradient brandGradient;

  /// Glow del acento para elementos interactivos clave (vacío en light).
  final List<BoxShadow> accentGlow;

  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.accent,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.error,
    required this.brandGradient,
    required this.accentGlow,
  });

  // ── Dark ───────────────────────────────────────────────────────────────────
  static const AppColors dark = AppColors(
    canvas: Color(0xFF0B0D16),
    surface: Color(0xFF161A2B),
    surfaceRaised: Color(0xFF1F2542),
    border: Color(0x14FFFFFF), // ~8% blanco
    accent: Color.fromARGB(238, 54, 143, 220), // electric cyan
    onAccent: Color(0xFF0B0D16),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA8B0C5),
    textMuted: Color(0xFF6B7388),
    success: Color(0xFF4AF096),
    warning: Color(0xFFFFB13C),
    error: Color(0xFFFF5E62),
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A3052), Color(0xFF0B0D16)],
    ),
    accentGlow: [
      BoxShadow(color: Color(0x5934E0FF), blurRadius: 16), // accent @ 35%
    ],
  );

  // ── Light ──────────────────────────────────────────────────────────────────
  static const AppColors light = AppColors(
    canvas: Color(0xFFF4F6FB), // blanco azulado frío
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEDF1F8),
    border: Color(0x142A3052), // ~8% navy
    accent: Color(0xFF18C6E6), // cyan algo más oscuro para contraste AA
    onAccent: Color(0xFF06222A),
    textPrimary: Color(0xFF0B0D16),
    textSecondary: Color(0xFF4A5268),
    textMuted: Color(0xFF8A92A6),
    success: Color(0xFF12B86C),
    warning: Color(0xFFE0902A),
    error: Color(0xFFE0464B),
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE3E9F6), Color(0xFFF4F6FB)],
    ),
    accentGlow: <BoxShadow>[], // glow nulo en light
  );

  /// Sombra suave para dar profundidad a cards en light (navy ~8%).
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(color: Color(0x142A3052), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Acceso a los tokens del tema activo. Devuelve [dark] como fallback.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? dark;

  @override
  AppColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? accent,
    Color? onAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? error,
    Gradient? brandGradient,
    List<BoxShadow>? accentGlow,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      brandGradient: brandGradient ?? this.brandGradient,
      accentGlow: accentGlow ?? this.accentGlow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      brandGradient:
          Gradient.lerp(brandGradient, other.brandGradient, t) ?? brandGradient,
      accentGlow:
          BoxShadow.lerpList(accentGlow, other.accentGlow, t) ?? accentGlow,
    );
  }
}
