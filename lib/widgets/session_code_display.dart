import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget to display the 6-digit session code
///
/// Features:
/// - Extra large text (48sp minimum)
/// - High contrast background
/// - Copy to clipboard functionality
/// - Accessible to screen readers
class SessionCodeDisplay extends StatelessWidget {
  /// The 6-digit session code to display
  final String sessionCode;

  const SessionCodeDisplay({
    super.key,
    required this.sessionCode,
  });

  /// Copies the session code to clipboard
  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: sessionCode));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Código copiado: $sessionCode',
            style: const TextStyle(fontSize: 20),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Código de sesión: ${_formatCodeForSpeech(sessionCode)}',
      hint: 'Comparte este código con tu familiar para que se conecte',
      child: Card(
        elevation: 8,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary,
            width: 3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Código de Sesión',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 16),

              // Session code with extra large text
              SelectableText(
                _formatCodeDisplay(sessionCode),
                style: TextStyle(
                  fontSize: 56, // Extra large for visibility
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  color: theme.colorScheme.primary,
                  fontFeatures: const [
                    FontFeature.tabularFigures(), // Monospaced numbers
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Copy button
              Semantics(
                label: 'Copiar código de sesión',
                hint: 'Toca dos veces para copiar el código al portapapeles',
                button: true,
                child: InkWell(
                  onTap: () => _copyToClipboard(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy,
                          size: 24,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Copiar código',
                          style: TextStyle(
                            fontSize: 20,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formats the code for display (adds spacing)
  /// Example: "234567" → "234 567"
  String _formatCodeDisplay(String code) {
    if (code.length != 6) return code;

    return '${code.substring(0, 3)} ${code.substring(3)}';
  }

  /// Formats the code for speech (reads each digit separately)
  /// Example: "234567" → "2, 3, 4, 5, 6, 7"
  String _formatCodeForSpeech(String code) {
    return code.split('').join(', ');
  }
}
