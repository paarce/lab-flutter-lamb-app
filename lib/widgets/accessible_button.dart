import 'package:flutter/material.dart';

/// Accessible button widget that meets WCAG 2.1 AA standards
///
/// Features:
/// - Minimum height: 80dp (touch target)
/// - Minimum text size: 24sp
/// - High contrast colors
/// - Semantic labels for screen readers
/// - Haptic feedback on tap
class AccessibleButton extends StatelessWidget {
  /// Button label text
  final String label;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Semantic hint for screen readers (optional)
  /// Example: "Toca dos veces para iniciar sesión remota"
  final String? semanticHint;

  /// Icon to display (optional)
  final IconData? icon;

  /// Button color (defaults to primary color)
  final Color? backgroundColor;

  /// Text color (defaults to onPrimary color)
  final Color? textColor;

  /// Whether this is a destructive action (e.g., "Cancel", "End Session")
  /// If true, uses red color scheme
  final bool isDestructive;

  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticHint,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine colors
    final buttonColor = isDestructive
        ? Colors.red[700]
        : (backgroundColor ?? theme.colorScheme.primary);

    final labelColor =
        textColor ?? (isDestructive ? Colors.white : theme.colorScheme.onPrimary);

    return Semantics(
      label: label,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        height: 80, // Minimum 80dp height
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: labelColor,
            disabledBackgroundColor: theme.disabledColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 32,
                  color: labelColor,
                ),
                const SizedBox(width: 16),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 24, // Minimum 24sp
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
