import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/remote_control_provider.dart';
import '../services/error_handler_service.dart';
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
    // Show loading dialog (cancelable)
    if (!mounted) return;

    // Track if dialog is still showing
    bool dialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => WillPopScope(
        // Allow back button to dismiss
        onWillPop: () async => true,
        child: Semantics(
          label: 'Iniciando sesión remota',
          liveRegion: true,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 4),
                    const SizedBox(height: 24),
                    const Text(
                      'Iniciando sesión...',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Cancelar inicio de sesión',
                      button: true,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          dialogShowing = false;
                        },
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Start session without timeout to measure real performance
    String? sessionCode;
    try {
      print('🔵 [RemoteControlHostScreen] Starting session (NO TIMEOUT - measuring real time)...');
      final screenStart = DateTime.now();

      sessionCode = await provider.startRemoteSession();

      final screenDuration = DateTime.now().difference(screenStart);
      print('🔵 [RemoteControlHostScreen] startRemoteSession completed. Result: $sessionCode');
      print('⏱️  [RemoteControlHostScreen] Total time: ${screenDuration.inMilliseconds}ms (${(screenDuration.inMilliseconds / 1000).toStringAsFixed(1)}s)');
    } catch (e) {
      print('🔴 [RemoteControlHostScreen] Exception caught: $e');
      // Handle any exceptions
      if (mounted && dialogShowing) {
        Navigator.of(context).pop();
        dialogShowing = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(fontSize: 20),
            ),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Close loading dialog if still showing
    if (mounted && dialogShowing) {
      Navigator.of(context).pop();
      dialogShowing = false;

      if (sessionCode != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sesión iniciada: $sessionCode',
              style: const TextStyle(fontSize: 20),
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Show error message (timeout or failure)
        final errorMessage = provider.errorMessage ??
            'No se pudo iniciar la sesión. '
                'Verifica tu conexión a internet y que Firestore esté habilitado.';

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
}
