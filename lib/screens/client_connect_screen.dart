import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/remote_viewer_provider.dart';
import '../services/error_handler_service.dart';
import 'client_viewer_screen.dart';

/// Screen for entering session code to connect to host
///
/// Features:
/// - 6-digit code input (only 2-9)
/// - Real-time validation
/// - "Connect" button (disabled until valid code)
/// - Error display
/// - Loading state during connection
/// - High contrast UI for accessibility
class ClientConnectScreen extends StatefulWidget {
  const ClientConnectScreen({super.key});

  @override
  State<ClientConnectScreen> createState() => _ClientConnectScreenState();
}

class _ClientConnectScreenState extends State<ClientConnectScreen> {
  final _codeController = TextEditingController();
  bool _isConnecting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Remoto - Cliente'),
        centerTitle: true,
      ),
      body: Consumer<RemoteViewerProvider>(
        builder: (context, provider, child) {
          // Check for errors and display them using ErrorHandlerService
          if (provider.lastError != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && provider.lastError != null) {
                ErrorHandlerService.handleError(
                  context: context,
                  error: provider.lastError!,
                  service: 'RemoteViewerProvider',
                  canRetry: provider.lastError!.canRetry,
                  onRetry: provider.lastError!.canRetry
                      ? () => _connectToSession(provider)
                      : null,
                );
                provider.clearError();
              }
            });
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    const Text(
                      'Ingresa el código de sesión',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtitle/Instructions
                    Text(
                      'Solicita el código de 6 dígitos al adulto mayor',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Code input field
                    Semantics(
                      label: 'Código de sesión',
                      hint: 'Ingresa el código de 6 dígitos',
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                          // Filter to only allow 2-9
                          FilteringTextInputFormatter.allow(RegExp(r'[2-9]')),
                        ],
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '234567',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            letterSpacing: 12,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Rebuild to enable/disable button
                        },
                        autofocus: true,
                        enabled: !_isConnecting,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error message
                    if (provider.errorMessage != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Card(
                          color: Colors.red[50],
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
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
                                      color: Colors.red[900],
                                      fontSize: 20,
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

                    // Connect button
                    Semantics(
                      label: 'Conectar',
                      hint: 'Toca para conectar con el código ingresado',
                      button: true,
                      enabled: _codeController.text.length == 6 &&
                          !_isConnecting,
                      child: SizedBox(
                        height: 70,
                        child: ElevatedButton(
                          onPressed: _codeController.text.length == 6 &&
                                  !_isConnecting
                              ? () => _connectToSession(provider)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isConnecting
                              ? const SizedBox(
                                  height: 32,
                                  width: 32,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'Conectar',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Help text
                    Text(
                      '¿No tienes un código? Solicítalo al adulto mayor que necesita ayuda.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Connects to the session with the entered code
  Future<void> _connectToSession(RemoteViewerProvider provider) async {
    setState(() => _isConnecting = true);

    final success = await provider.connectToSession(_codeController.text);

    setState(() => _isConnecting = false);

    if (success && mounted) {
      // Navigate to viewer screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ClientViewerScreen(),
        ),
      );
    }
  }
}
