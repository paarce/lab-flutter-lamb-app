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

  @override
  void initState() {
    super.initState();
    // Auto-start session when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_sessionAutoStarted) {
        _sessionAutoStarted = true;
        final provider = context.read<RemoteControlProvider>();
        if (provider.status == RemoteControlStatus.idle ||
            provider.status == RemoteControlStatus.ended ||
            provider.status == RemoteControlStatus.error) {
          _startSession(provider);
        }
      }
    });
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
            ? () => _startSession(provider)
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
    if (!mounted) return;

    // Feedback audible inmediato para usuario con baja visión
    try {
      final ttsService = TTSFactory.getInstance();
      await ttsService.speak(
        'Iniciando sesión remota. Por favor espera mientras se genera el código.',
      );
    } catch (e) {
      // No bloquear el flujo si TTS falla
      developer.log(
        'Failed to play TTS during session start',
        name: 'RemoteControlHostScreen',
        error: e,
      );
    }

    // Iniciar sesión sin diálogo modal - El progreso se muestra en la UI
    try {
      print('🔵 [RemoteControlHostScreen] Starting session...');
      final screenStart = DateTime.now();

      final sessionCode = await provider.startRemoteSession();

      final screenDuration = DateTime.now().difference(screenStart);
      print('🔵 [RemoteControlHostScreen] Session started: $sessionCode');
      print('⏱️  [RemoteControlHostScreen] Total time: ${screenDuration.inMilliseconds}ms');

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
    } catch (e) {
      print('🔴 [RemoteControlHostScreen] Exception: $e');
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
      await provider.endRemoteSession();

      if (mounted) {
        // Mostrar mensaje de confirmación
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

        // Redirigir al Home Screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}
