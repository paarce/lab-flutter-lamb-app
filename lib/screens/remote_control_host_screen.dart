import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/remote_control_provider.dart';
import '../services/error_handler_service.dart';
import '../services/tts/tts_factory.dart';
import '../widgets/accessible_button.dart';
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
    print(
      '🟢 [RemoteControlHostScreen] initState called'
    );

    // Auto-start session when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_sessionAutoStarted) {
        _sessionAutoStarted = true;
        final provider = context.read<RemoteControlProvider>();

        print(
          '🟢 [RemoteControlHostScreen] Auto-start check: status=${provider.status}, userManuallyEnded=$_userManuallyEndedSession'
        );

        // Only auto-start if:
        // - Status is idle (first time since app started)
        // - User has NOT manually ended a session previously
        // DO NOT auto-start if:
        // - Status is ended (user terminated session)
        // - Status is error (user must manually retry to avoid infinite loop)
        // - User previously ended a session manually (to avoid annoying re-starts)
        if (provider.status == RemoteControlStatus.idle &&
            !_userManuallyEndedSession) {
          print(
            '🟢 [RemoteControlHostScreen] Auto-starting session'
          );
          _startSession(provider);
        } else {
          print(
            '🟡 [RemoteControlHostScreen] NOT auto-starting (status=${provider.status}, userManuallyEnded=$_userManuallyEndedSession)'
          );
        }
      }
    });
  }

  @override
  void dispose() {
    print(
      '🟠 [RemoteControlHostScreen] dispose called'
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Control Remoto',
          style: TextStyle(fontSize: 24),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: Consumer<RemoteControlProvider>(
        builder: (context, provider, child) {
          // Check for errors and display them using ErrorHandlerService
          if (provider.lastError != null) {
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
                );
                provider.clearError();
              }
            });
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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

                  // Spacer replaced with fixed height for scrollable content
                  const SizedBox(height: 48),

                  // Action buttons
                  _buildActionButtons(provider),

                  const SizedBox(height: 16),

                  // Help text
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
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds action buttons based on current status
  Widget _buildActionButtons(RemoteControlProvider provider) {
    final isSessionActive = provider.status != RemoteControlStatus.idle &&
        provider.status != RemoteControlStatus.ended &&
        provider.status != RemoteControlStatus.error;

    if (!isSessionActive) {
      // Show "Start Session" button
      return AccessibleButton(
        label: 'Iniciar Sesión Remota',
        icon: Icons.phonelink,
        semanticHint:
            'Toca dos veces para generar un código y permitir que tu familiar se conecte',
        onPressed: provider.status == RemoteControlStatus.idle ||
                provider.status == RemoteControlStatus.ended ||
                provider.status == RemoteControlStatus.error
            ? () {
                // Reset flag when user manually starts a session
                _userManuallyEndedSession = false;
                _startSession(provider);
              }
            : null,
      );
    } else {
      // Show "End Session" button
      return AccessibleButton(
        label: 'Terminar Sesión',
        icon: Icons.stop,
        semanticHint:
            'Toca dos veces para terminar la sesión remota y dejar de compartir tu pantalla',
        isDestructive: true,
        onPressed: () => _endSession(provider),
      );
    }
  }

  /// Starts a new remote control session
  Future<void> _startSession(RemoteControlProvider provider) async {
    if (!mounted) {
      print(
        '⚠️  [RemoteControlHostScreen] _startSession skipped: widget not mounted'
      );
      return;
    }

    print(
      '🔵 [RemoteControlHostScreen] _startSession called (status=${provider.status})'
    );

    // Feedback audible inmediato para usuario con baja visión
    try {
      final ttsService = TTSFactory.getInstance();
      await ttsService.speak(
        'Iniciando sesión remota. Por favor espera mientras se genera el código.',
      );
    } catch (e) {
      // No bloquear el flujo si TTS falla
      print(
        'Failed to play TTS during session start'
      );
    }

    // Iniciar sesión sin diálogo modal - El progreso se muestra en la UI
    try {
      print(
        '🔵 [RemoteControlHostScreen] Calling provider.startRemoteSession()...'
      );
      final screenStart = DateTime.now();

      final sessionCode = await provider.startRemoteSession();

      final screenDuration = DateTime.now().difference(screenStart);
      print(
        '✅ [RemoteControlHostScreen] Session started successfully: $sessionCode (took ${screenDuration.inMilliseconds}ms)'
      );

      // Mostrar mensaje de éxito solo si la sesión se inició correctamente
      if (mounted && sessionCode != null) {
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
    } catch (e, stackTrace) {
      print(
        '❌ [RemoteControlHostScreen] Exception in _startSession'
      );
      // El error ya se maneja vía ErrorHandlerService en el Provider
      // Solo mostramos mensaje si es necesario
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
    print(
      '🔴 [RemoteControlHostScreen] _endSession called (status=${provider.status})'
    );

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
              // TODO: The error is still here, the navigation to home is happening before the session ends.
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      print(
        '🔴 [RemoteControlHostScreen] User confirmed end session, calling endRemoteSession()...'
      );

      // Mark that user manually ended the session to prevent auto-restart
      _userManuallyEndedSession = true;

      // Wait for session to fully end before navigating
      await provider.endRemoteSession();

      print(
        '🔴 [RemoteControlHostScreen] endRemoteSession() completed, status=${provider.status}'
      );

      // Give provider a moment to finish all cleanup operations
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        print(
          '🔴 [RemoteControlHostScreen] Navigating to home...'
        );

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

        print(
          '🔴 [RemoteControlHostScreen] Navigation to home completed'
        );
      } else {
        print(
          '⚠️  [RemoteControlHostScreen] Widget not mounted, skipping navigation'
        );
      }
    } else {
      print(
        '🟡 [RemoteControlHostScreen] User cancelled end session'
      );
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
      // Log error but don't block UI (non-critical feature)
      print(
        'Failed to repeat session code via TTS'
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRepeatingCode = false;
        });
      }
    }
  }
}
