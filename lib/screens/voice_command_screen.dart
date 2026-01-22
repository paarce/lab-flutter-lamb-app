import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/voice_command_provider.dart';
import '../services/error_handler_service.dart';
import '../services/tts/tts_factory.dart';
import '../widgets/accessible_button.dart';
import '../widgets/base_screen_layout.dart';
import 'remote_control_host_screen.dart';

/// Pantalla de comandos de voz con reconocimiento en tiempo real
///
/// Features:
/// - Reconocimiento de voz vía ElevenLabs STT
/// - Indicador visual animado (micrófono)
/// - Transcripción en vivo
/// - Lista de comandos disponibles
/// - Timeout de 10 segundos (reseteado por palabra)
/// - Totalmente accesible (TalkBack/VoiceOver)
class VoiceCommandScreen extends StatefulWidget {
  const VoiceCommandScreen({super.key});

  @override
  State<VoiceCommandScreen> createState() => _VoiceCommandScreenState();
}

class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
  bool _callbackConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkMicrophonePermission();
  }

  /// Verifica y solicita permiso de micrófono
  Future<void> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;

    if (!status.isGranted) {
      final result = await Permission.microphone.request();

      if (!result.isGranted && mounted) {
        await ErrorHandlerService.handleError(
          context: context,
          error: Exception('Permiso de micrófono denegado'),
          service: 'VoiceCommandScreen',
          canRetry: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceCommandProvider>(
      builder: (context, provider, child) {
        // Configurar callback de navegacion (solo una vez)
        if (!_callbackConfigured) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.setNavigationCallback((screen) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => screen),
              );
            });
          });
          _callbackConfigured = true;
        }

        final isListening = provider.state == VoiceCommandState.listening;
        final isWaiting = provider.state == VoiceCommandState.waitingTranscription;
        final isProcessing = provider.state == VoiceCommandState.processing;
        final hasError = provider.state == VoiceCommandState.error;
        final isBusy = isListening || isWaiting || isProcessing;

        return BaseScreenLayout(
          title: 'Comandos de Voz',
          content: [
            // 1. Transcripción en vivo (si existe)
            if (provider.currentTranscript.isNotEmpty)
              _buildTranscript(provider.currentTranscript),

            const SizedBox(height: 16),

            // 2. Ícono de micrófono animado
            _buildMicrophoneIcon(isListening, isWaiting, isProcessing),

            const SizedBox(height: 8),

            // 3. Estado actual (con liveRegion para TalkBack)
            _buildStateText(provider.state, hasError, provider.errorMessage),

            const SizedBox(height: 24),

            // 4. Ayuda de comandos disponibles (cuando idle)
            if (provider.state == VoiceCommandState.idle)
              _buildCommandsHelp(),

            // Espaciado para que el contenido no quede detrás del botón sticky
            const SizedBox(height: 140),
          ],
          footerActions: [
            // Botón STICKY en footer (posición fija)
            _buildCustomPressAndHoldButton(
              context,
              provider,
              isListening,
              isBusy,
            ),
          ],
        );
      },
    );
  }

  /// Construye el ícono de micrófono animado
  Widget _buildMicrophoneIcon(bool isListening, bool isWaiting, bool isProcessing) {
    final iconColor = isListening
        ? Colors.red
        : isWaiting
            ? Colors.blue
            : isProcessing
                ? Colors.orange
                : Colors.grey;

    final backgroundColor = isListening
        ? Colors.red.withOpacity(0.2)
        : isWaiting
            ? Colors.blue.withOpacity(0.2)
            : isProcessing
                ? Colors.orange.withOpacity(0.2)
                : Colors.grey[100];

    final icon = isListening
        ? Icons.mic
        : isWaiting
            ? Icons.sync
            : isProcessing
                ? Icons.hourglass_bottom
                : Icons.mic_off;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
        ),
        child: isWaiting
            ? RotationTransition(
                turns: const AlwaysStoppedAnimation(0.5),
                child: Icon(
                  icon,
                  size: 80,
                  color: iconColor,
                  semanticLabel: 'Esperando respuesta',
                ),
              )
            : Icon(
                icon,
                size: 80,
                color: iconColor,
                semanticLabel: isListening
                    ? 'Escuchando'
                    : isProcessing
                        ? 'Procesando'
                        : 'Micrófono apagado',
              ),
      ),
    );
  }

  /// Construye el texto de estado (con liveRegion para TalkBack)
  Widget _buildStateText(
    VoiceCommandState state,
    bool hasError,
    String? errorMessage,
  ) {
    String stateText;

    switch (state) {
      case VoiceCommandState.idle:
        stateText = 'Listo para escuchar';
        break;
      case VoiceCommandState.listening:
        stateText = 'Escuchando...';
        break;
      case VoiceCommandState.waitingTranscription:
        stateText = 'Esperando respuesta...';
        break;
      case VoiceCommandState.processing:
        stateText = 'Procesando comando...';
        break;
      case VoiceCommandState.error:
        stateText = errorMessage ?? 'Error';
        break;
    }

    return Semantics(
      liveRegion: true,
      child: Center(
        child: Text(
          stateText,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: hasError ? Colors.red[700] : null,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Construye la transcripción en vivo
  Widget _buildTranscript(String transcript) {
    return Semantics(
      liveRegion: true,
      label: 'Frase reconocida: $transcript',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reconociendo:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              transcript,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la ayuda de comandos disponibles
  Widget _buildCommandsHelp() {
    return Semantics(
      label: 'Comandos disponibles',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comandos disponibles:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildCommandItem('Solicitar ayuda', 'Genera un código para ayuda remota'),
            _buildCommandItem('Abrir WhatsApp', 'Abre la aplicación WhatsApp'),
            _buildCommandItem('Cambiar contraste', 'Cambia el tema de la aplicación'),
            _buildCommandItem('Cancelar', 'Detiene el reconocimiento de voz'),
          ],
        ),
      ),
    );
  }

  /// Construye un item de comando individual
  Widget _buildCommandItem(String command, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_forward,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el botón custom de press-and-hold (USAR ESTE)
  Widget _buildCustomPressAndHoldButton(
    BuildContext context,
    VoiceCommandProvider provider,
    bool isListening,
    bool isBusy,
  ) {
    final buttonColor = isListening
        ? Colors.red
        : isBusy
            ? Colors.grey
            : Theme.of(context).colorScheme.primary;

    // Color del texto: blanco para rojo/gris, onPrimary para botón normal
    final textColor = isListening || isBusy
        ? Colors.white
        : Theme.of(context).colorScheme.onPrimary;

    final buttonText = isListening
        ? 'Suelta para detener'
        : isBusy
            ? 'Esperando...'
            : 'Mantén presionado para hablar';

    final icon = isListening
        ? Icons.mic
        : isBusy
            ? Icons.hourglass_bottom
            : Icons.mic_none;

    return Semantics(
      button: true,
      label: buttonText,
      hint: 'Mantén presionado para grabar',
      enabled: !isBusy || isListening,
      child: Listener(
        onPointerDown: (_) {
          if (!isBusy) {
            HapticFeedback.mediumImpact();
            provider.startListening();
          }
        },
        onPointerUp: (_) {
          if (isListening) {
            HapticFeedback.mediumImpact();
            provider.stopListening();
          }
        },
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isListening
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: textColor,
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
