import 'package:flutter/material.dart';
import 'package:stronger/theme/app_colors.dart';

/// Botón secundario: fondo [AppColors.surfaceRaised], borde sutil y texto
/// [AppColors.textPrimary]. Sin glow; se apoya en la superficie elevada.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Ocupa todo el ancho disponible (por defecto sí).
  final bool expand;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final Widget button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: colors.surfaceRaised,
        foregroundColor: colors.textPrimary,
        disabledForegroundColor: colors.textMuted,
        side: BorderSide(color: colors.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
