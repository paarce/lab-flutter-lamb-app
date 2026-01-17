import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/remote_control_provider.dart';
import '../services/error_handler_service.dart';
import '../services/tts/tts_factory.dart';
import '../widgets/accessible_button.dart';
import '../widgets/base_screen_layout.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/session_code_display.dart';

/// Screen for the host (elderly user) to manage remote control sessions
///
/// Features:
/// - Start/stop remote control sessions
/// - Display session code
/// - Show connection status
/// - Fully accessible with TalkBack
class RemoteControlHostScreen extends StatefulWidget {
  const RemoteControlHostScreen({super.key});

  @override
  State<RemoteControlHostScreen> createState() =>
      _RemoteControlHostScreenState();
}

class _RemoteControlHostScreenState extends State<RemoteControlHostScreen> {
  bool _sessionAutoStarted = false;
  bool _isRepeatingCode = false;
  static bool _userManuallyEndedSession = false;

  @override
  void initState() {
    super.initState();

    // Reset flag when user enters this screen
    _userManuallyEndedSession = false;

    // Auto-start session when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_sessionAutoStarted) {
        _sessionAutoStarted = true;
        final provider = context.read<RemoteControlProvider>();

        // Auto-start session whenever user enters this screen
        // DO NOT auto-start if user just manually ended (to avoid loop during navigation)
        if (!_userManuallyEndedSession) {
          _startSession(provider);
        }
      }
    });

    // Listen for session status changes to handle normal disconnections
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<RemoteControlProvider>();
        provider.addListener(_onSessionStatusChanged);
      }
    });
  }

  @override
  void dispose() {
    // Remove the listener when disposing
    try {
      final provider = context.read<RemoteControlProvider>();
      provider.removeListener(_onSessionStatusChanged);
    } catch (e) {
      // Provider may not be available during dispose
    }
    super.dispose();
  }

  /// Handles session status changes
  /// Automatically navigates to home when session ends normally
  void _onSessionStatusChanged() {
    if (!mounted) return;

    final provider = context.read<RemoteControlProvider>();

    // If session ended normally (no error) and user didn't manually end it
    if (provider.status == RemoteControlStatus.ended &&
        provider.lastError == null &&
        !_userManuallyEndedSession) {
      // Mark that the session was auto-ended (not manually by user)
      _userManuallyEndedSession = true;

      // Navigate to home
      Navigator.of(context).popUntil((route) => route.isFirst);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tu familiar ha terminado la sesión',
            style: TextStyle(fontSize: 20),
          ),
          backgroundColor: Colors.grey[700],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RemoteControlProvider>(
      builder: (context, provider, child) {
        // Check for errors and display them using ErrorHandlerService
        // BUT: Only show error dialog if it's an actual error, not a normal session end
        if (provider.lastError != null &&
            provider.status == RemoteControlStatus.error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && provider.lastError != null) {
              ErrorHandlerService.handleError(
                context: context,
                error: provider.lastError!,
                service: 'RemoteControlProvider',
                canRetry: provider.lastError!.canRetry,
                onRetry: provider.lastError!.canRetry
                    ? () => _startSession(provider)
                    : null,
                // Navigate to home when user dismisses error without retrying
                onDismiss: () {
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              );
              provider.clearError();
            }
          });
        }

        // Determine if session is active for showing footer action
        final isSessionActive = provider.status != RemoteControlStatus.idle &&
            provider.status != RemoteControlStatus.ended &&
            provider.status != RemoteControlStatus.error;

        return BaseScreenLayout(
          title: 'Control Remoto',
          showBackButton: true,
          content: [
            // Connection status indicator
            ConnectionStatusIndicator(status: provider.status),

            const SizedBox(height: 32),

            // Session code display (only when session is active)
            if (provider.sessionCode != null) ...[
              SessionCodeDisplay(sessionCode: provider.sessionCode!),
              const SizedBox(height: 24),

              // Button to repeat session code via speaker
              AccessibleButton(
                label: 'Repetir código en altavoz',
                icon: Icons.volume_up,
                semanticHint:
                    'Toca dos veces para escuchar el código de sesión nuevamente',
                onPressed: _isRepeatingCode
                    ? null
                    : () => _repeatSessionCode(provider.sessionCode!),
              ),
              const SizedBox(height: 24),

              // Instructions for user
              Semantics(
                label:
                    'Comparte el código ${provider.sessionCode} con tu familiar',
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Comparte este código con tu familiar para que pueda conectarse y ayudarte',
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],

            // Error message (if any)
            if (provider.errorMessage != null) ...[
              Semantics(
                label: 'Error: ${provider.errorMessage}',
                liveRegion: true,
                child: Card(
                  elevation: 4,
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 36,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.red[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Help text at the bottom of scrollable content
            const SizedBox(height: 16),
            Semantics(
              label:
                  'Necesitas ayuda de un familiar para resolver un problema en tu dispositivo',
              child: Text(
                '¿Necesitas ayuda de un familiar?',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          // Footer with "End Session" button (only when session is active)
          footerActions: isSessionActive
              ? [
                  AccessibleButton(
                    label: 'Terminar Sesión',
                    icon: Icons.stop,
                    semanticHint:
                        'Toca dos veces para terminar la sesión remota y dejar de compartir tu pantalla',
                    isDestructive: true,
                    onPressed: () => _endSession(provider),
                  ),
                ]
              : [],
        );
      },
    );
  }

  /// Starts a new remote control session
  Future<void> _startSession(RemoteControlProvider provider) async {
    if (!mounted) return;

    // Feedback audible inmediato para usuario con baja visión
    try {
      final ttsService = TTSFactory.getInstance();
      await ttsService.speak(
        'Iniciando sesión remota. Por favor espera mientras se genera el código.',
      );
    } catch (e) {
      // No bloquear el flujo si TTS falla
    }

    // Iniciar sesión sin diálogo modal - El progreso se muestra en la UI
    try {
      final sessionCode = await provider.startRemoteSession();

      // If session was cancelled or failed, stop execution
      if (sessionCode == null) {
        return;
      }

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sesión iniciada: $sessionCode',
              style: const TextStyle(fontSize: 20),
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // El error ya se maneja vía ErrorHandlerService en el Provider
      if (mounted) {
        final errorMessage = provider.errorMessage ?? e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(fontSize: 20),
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Ends the current remote control session
  Future<void> _endSession(RemoteControlProvider provider) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Semantics(
        label: 'Confirmar terminar sesión',
        child: AlertDialog(
          title: const Text(
            '¿Terminar sesión?',
            style: TextStyle(fontSize: 26),
          ),
          content: const Text(
            'Se cerrará la conexión con tu familiar y dejarás de compartir tu pantalla.',
            style: TextStyle(fontSize: 22),
          ),
          actions: [
            AccessibleButton(
              label: 'Cancelar',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 16),
            AccessibleButton(
              label: 'Terminar',
              isDestructive: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      // Mark that user manually ended the session to prevent auto-restart
      _userManuallyEndedSession = true;

      // Wait for session to fully end before navigating
      await provider.endRemoteSession();

      // Give provider a moment to finish all cleanup operations
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Redirigir al Home Screen
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Mostrar mensaje DESPUÉS de navegar (se verá en el home)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Sesión terminada',
              style: TextStyle(fontSize: 20),
            ),
            backgroundColor: Colors.grey[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Repeats the session code via TTS (text-to-speech)
  Future<void> _repeatSessionCode(String sessionCode) async {
    // Prevent multiple simultaneous reproductions
    if (_isRepeatingCode) return;

    setState(() {
      _isRepeatingCode = true;
    });

    try {
      final ttsService = TTSFactory.getInstance();

      // Format code with spaces between digits for clear pronunciation
      // Example: "234567" -> "2, 3, 4, 5, 6, 7"
      final formattedCode = sessionCode.split('').join(', ');

      await ttsService.speak(
        'Código de sesión: $formattedCode',
      );
    } catch (e) {
      // Non-critical feature, continue without logging
    } finally {
      if (mounted) {
        setState(() {
          _isRepeatingCode = false;
        });
      }
    }
  }
}
