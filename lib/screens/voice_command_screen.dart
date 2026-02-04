import 'dart:async';

import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/voice_command_provider.dart';
import '../services/error_handler_service.dart';
import '../services/tts/tts_factory.dart';
import '../services/tts/tts_service.dart';
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

  /// Timer para duración mínima de presión (200ms)
  Timer? _minimumPressTimer;

  /// Indica si estamos esperando que el timer de 200ms expire
  bool _isWaitingMinimumPress = false;

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
  void dispose() {
    _minimumPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceCommandProvider>(
      builder: (context, provider, child) {
        // Configurar callbacks (solo una vez)
        if (!_callbackConfigured) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Navigation callback for voice commands
            provider.setNavigationCallback((screen) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => screen),
              );
            });

            // Error context for WhatsApp errors
            provider.setErrorContext(context);
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

  /// Construye la ayuda de comandos disponibles agrupados por categoría
  Widget _buildCommandsHelp() {
    return Semantics(
      label: 'Comandos disponibles organizados en 5 categorías',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título principal
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Comandos disponibles:',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),

          // Nota sobre cómo escuchar por categoría
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Di "comandos de" seguido de una categoría para escucharla.',
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),

          // Categoría: Asistencia
          _buildCategorySection(
            icon: Icons.support_agent,
            title: 'ASISTENCIA',
            commands: [
              ('Compartir pantalla', 'Ayuda remota de un familiar'),
              ('Tutorial', 'Guía de uso de la app'),
            ],
          ),
          const SizedBox(height: 16),

          // Categoría: WhatsApp
          _buildCategorySection(
            icon: Icons.chat,
            title: 'WHATSAPP',
            commands: [
              ('Abrir WhatsApp', 'Abre la aplicación de mensajes'),
              ('Chat de [nombre]', 'Abre chat de un contacto favorito'),
            ],
          ),
          const SizedBox(height: 16),

          // Categoría: Volumen
          _buildCategorySection(
            icon: Icons.volume_up,
            title: 'VOLUMEN',
            commands: [
              ('Subir / Bajar volumen', 'Ajusta el sonido'),
              ('Volumen al máximo', 'Volumen al 100%'),
              ('Silencio', 'Volumen al 0%'),
              ('Volumen al 50%', 'Porcentaje específico'),
            ],
          ),
          const SizedBox(height: 16),

          // Categoría: Información
          _buildCategorySection(
            icon: Icons.info_outline,
            title: 'INFORMACIÓN',
            commands: [
              ('Qué hora es', 'Hora actual'),
              ('Qué día es hoy', 'Fecha actual'),
              ('Cuánta batería', 'Nivel de batería'),
            ],
          ),
          const SizedBox(height: 16),

          // Categoría: Ajustes
          _buildCategorySection(
            icon: Icons.settings,
            title: 'AJUSTES',
            commands: [
              ('Alto contraste', 'Cambia los colores'),
              ('Cancelar', 'Detiene el reconocimiento'),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye una sección de categoría con icono, título y comandos
  Widget _buildCategorySection({
    required IconData icon,
    required String title,
    required List<(String, String)> commands,
  }) {
    return Semantics(
      container: true,
      label: 'Categoría $title',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con icono y título
            Row(
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Comandos de la categoría
            ...commands.map((cmd) => _buildCommandItem(cmd.$1, cmd.$2)),
          ],
        ),
      ),
    );
  }

  /// Construye un item de comando individual
  Widget _buildCommandItem(String command, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_forward,
            size: 22,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
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
  ///
  /// Mejoras UX implementadas:
  /// - Ignora toques mientras TTS habla (sin deshabilitar visualmente)
  /// - Requiere 200ms de presión mínima antes de iniciar escucha
  /// - Feedback háptico diferenciado: medio al presionar, fuerte al activar/soltar
  /// - Usa paquete haptic_feedback para mejor compatibilidad con Samsung/OneUI
  Widget _buildCustomPressAndHoldButton(
    BuildContext context,
    VoiceCommandProvider provider,
    bool isListening,
    bool isBusy,
  ) {
    final ttsService = TTSFactory.getInstance();

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
        onPointerDown: (_) async {
          // Ignorar si TTS está hablando (sin feedback para no confundir)
          if (ttsService.isSpeaking) {
            debugPrint('Ignoring touch - TTS is speaking');
            return;
          }

          if (!isBusy) {
            // Feedback inmediato de que registró el toque (intensidad media)
            // Usa haptic_feedback package para mejor compatibilidad con Samsung
            await Haptics.vibrate(HapticsType.medium);
            _isWaitingMinimumPress = true;

            // Timer de 200ms antes de iniciar escucha
            _minimumPressTimer = Timer(const Duration(milliseconds: 200), () async {
              if (_isWaitingMinimumPress && mounted) {
                // Feedback fuerte de que AHORA sí está escuchando
                await Haptics.vibrate(HapticsType.heavy);
                provider.startListening();
                _isWaitingMinimumPress = false;
              }
            });
          }
        },
        onPointerUp: (_) async {
          // Cancelar timer si suelta antes de 200ms
          _minimumPressTimer?.cancel();
          _isWaitingMinimumPress = false;

          // Solo procesar si estaba escuchando
          if (isListening) {
            // Feedback fuerte al detener la escucha
            await Haptics.vibrate(HapticsType.heavy);
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
