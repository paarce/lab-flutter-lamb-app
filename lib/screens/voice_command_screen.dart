import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/voice_command_provider.dart';
import '../services/error_handler_service.dart';
import '../services/tts/tts_factory.dart';
import '../widgets/accessible_button.dart';
import '../widgets/base_screen_layout.dart';

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
        final isListening = provider.state == VoiceCommandState.listening;
        final isProcessing = provider.state == VoiceCommandState.processing;
        final hasError = provider.state == VoiceCommandState.error;

        return BaseScreenLayout(
          title: 'Comandos de Voz',
          content: [
            // 1. Ícono de micrófono animado
            _buildMicrophoneIcon(isListening, isProcessing),

            const SizedBox(height: 32),

            // 2. Estado actual (con liveRegion para TalkBack)
            _buildStateText(provider.state, hasError, provider.errorMessage),

            const SizedBox(height: 24),

            // 3. Transcripción en vivo (si existe)
            if (provider.currentTranscript.isNotEmpty)
              _buildTranscript(provider.currentTranscript),

            const SizedBox(height: 32),

            // 4. Ayuda de comandos disponibles (cuando idle)
            if (provider.state == VoiceCommandState.idle)
              _buildCommandsHelp(),
          ],
          footerActions: _buildFooterButtons(
            context,
            provider,
            isListening,
            isProcessing,
          ),
        );
      },
    );
  }

  /// Construye el ícono de micrófono animado
  Widget _buildMicrophoneIcon(bool isListening, bool isProcessing) {
    final iconColor = isListening
        ? Colors.red
        : isProcessing
            ? Colors.orange
            : Colors.grey;

    final backgroundColor = isListening
        ? Colors.red.withOpacity(0.2)
        : isProcessing
            ? Colors.orange.withOpacity(0.2)
            : Colors.grey[100];

    final icon = isListening
        ? Icons.mic
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
        child: Icon(
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
      label: 'Reconociendo: $transcript',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reconociendo:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              transcript,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
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
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comandos disponibles:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 16),
            _buildCommandItem('Solicitar ayuda', 'Genera un código para ayuda remota'),
            _buildCommandItem('Abrir WhatsApp', 'Abre la aplicación WhatsApp'),
            _buildCommandItem('Alto contraste', 'Cambia el tema de la aplicación'),
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
            color: Colors.blue[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye los botones del footer
  List<Widget> _buildFooterButtons(
    BuildContext context,
    VoiceCommandProvider provider,
    bool isListening,
    bool isProcessing,
  ) {
    final buttons = <Widget>[];

    // Botón principal: Mantén presionado para hablar
    buttons.add(
      _buildPressAndHoldButton(
        context,
        provider,
        isListening,
        isProcessing,
      ),
    );

    return buttons;
  }

  /// Construye el botón de press-and-hold (mantener presionado)
  Widget _buildPressAndHoldButton(
    BuildContext context,
    VoiceCommandProvider provider,
    bool isListening,
    bool isProcessing,
  ) {
    final buttonColor = isListening
        ? Colors.red
        : isProcessing
            ? Colors.orange
            : Theme.of(context).colorScheme.primary;

    final buttonText = isListening
        ? 'Suelta para detener'
        : isProcessing
            ? 'Procesando...'
            : 'Mantén presionado para hablar';

    final icon = isListening
        ? Icons.mic
        : isProcessing
            ? Icons.hourglass_bottom
            : Icons.mic_none;

    return Semantics(
      button: true,
      label: buttonText,
      hint: 'Mantén presionado para grabar tu comando de voz',
      enabled: !isProcessing,
      child: GestureDetector(
        onLongPressStart: isProcessing
            ? null
            : (_) {
                print('[DEBUG VoiceCommandScreen] 🖐️ Botón presionado, iniciando grabación');
                provider.startListening();
              },
        onLongPressEnd: isProcessing
            ? null
            : (_) {
                print('[DEBUG VoiceCommandScreen] 🖐️ Botón soltado, deteniendo grabación');
                provider.stopListening();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 100,
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
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
