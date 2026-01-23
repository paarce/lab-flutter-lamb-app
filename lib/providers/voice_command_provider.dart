import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/command.dart';
import '../screens/remote_control_host_screen.dart';
import '../services/elevenlabs_service.dart';
import '../services/tts/tts_service.dart';
import '../utils/nlp_parser.dart';
import 'theme_provider.dart';

/// Estados del sistema de comandos de voz
enum VoiceCommandState {
  /// Inactivo, esperando que usuario inicie
  idle,

  /// Escuchando audio y transcribiendo
  listening,

  /// Esperando transcripción final del servidor
  waitingTranscription,

  /// Procesando comando reconocido
  processing,

  /// Error durante reconocimiento o ejecución
  error,
}

/// State management provider for voice commands
///
/// Orchestrates:
/// - ElevenLabsService (STT - Speech-to-Text)
/// - TTSService (feedback auditivo)
/// - NLPParser (parsing de comandos)
///
/// Features:
/// - Timeout de 10s (reseteado en cada palabra)
/// - Heurística de 3 palabras para procesar comando
/// - Feedback TTS para todas las acciones
class VoiceCommandProvider extends ChangeNotifier {
  final ElevenLabsService _sttService;
  final TTSService _ttsService;
  final ThemeProvider _themeProvider;

  /// Callback para navegacion (configurado por la screen)
  void Function(Widget screen)? _navigationCallback;

  /// Estado actual del sistema de comandos
  VoiceCommandState _state = VoiceCommandState.idle;

  VoiceCommandState get state => _state;

  /// Transcripción actual en tiempo real
  String _currentTranscript = '';

  String get currentTranscript => _currentTranscript;

  /// Último comando ejecutado
  VoiceCommand? _lastCommand;

  VoiceCommand? get lastCommand => _lastCommand;

  /// Mensaje de error (si aplica)
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  /// Subscription al stream de transcripción
  StreamSubscription<String>? _transcriptionSubscription;

  /// Timer para timeout de 10 segundos
  Timer? _timeoutTimer;

  /// Duración del timeout (10 segundos)
  static const _timeoutDuration = Duration(seconds: 10);

  VoiceCommandProvider({
    required ElevenLabsService sttService,
    required TTSService ttsService,
    required ThemeProvider themeProvider,
  })  : _sttService = sttService,
        _ttsService = ttsService,
        _themeProvider = themeProvider;

  /// Configura el callback de navegacion desde la screen
  void setNavigationCallback(void Function(Widget screen) callback) {
    _navigationCallback = callback;
  }

  /// Inicia el reconocimiento de voz
  ///
  /// - Solicita permiso de micrófono
  /// - Cambia estado a listening
  /// - Inicia timeout de 10s
  /// - Escucha stream de transcripción
  Future<void> startListening() async {
    developer.log('Starting voice recognition', name: 'VoiceCommandProvider');

    try {
      // Solicitar permiso de micrófono
      final micPermission = await Permission.microphone.request();

      if (!micPermission.isGranted) {
        developer.log('Microphone permission denied', name: 'VoiceCommandProvider');
        _handleError('Permiso de micrófono requerido. Por favor, actívalo en Configuración.');
        return;
      }

      _setState(VoiceCommandState.listening);
      _currentTranscript = '';
      _errorMessage = null;
      notifyListeners();

      // Anunciar inicio con TTS

      // Iniciar timeout
      _startTimeout();

      // Escuchar transcripción en tiempo real
      final stream = _sttService.startListening();
      _transcriptionSubscription = stream.listen(
        (transcript) {
          if (transcript.isEmpty) return;

          developer.log('Transcript received: $transcript', name: 'VoiceCommandProvider');

          _currentTranscript = transcript;
          _resetTimeout(); // Reset timeout en cada palabra
          notifyListeners();

          // TODO: Heurística desactivada temporalmente para testing
          // El usuario debe soltar el botón para procesar el comando
          // final wordCount = transcript.trim().split(RegExp(r'\s+')).length;
          // if (wordCount >= 3) {
          //   _processTranscript(transcript);
          // }
        },
        onError: (error) {
          developer.log(
            'Error in transcription stream',
            name: 'VoiceCommandProvider',
            error: error,
          );
          _handleError('Error en reconocimiento de voz');
        },
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to start listening',
        name: 'VoiceCommandProvider',
        error: e,
        stackTrace: stackTrace,
      );
      _handleError('No se pudo iniciar el reconocimiento de voz');
    }
  }

  /// Detiene el reconocimiento de voz
  Future<void> stopListening() async {
    developer.log('Stopping listening', name: 'VoiceCommandProvider');

    _cancelTimeout();

    // Cambiar INMEDIATAMENTE a estado de espera para feedback visual
    _setState(VoiceCommandState.waitingTranscription);

    // Enviar commit ANTES de cerrar el stream
    await _sttService.stopListening();

    // Esperar 3 segundos para recibir transcripciones finales
    // ANTES de cancelar la suscripción
    developer.log('Waiting for final transcriptions', name: 'VoiceCommandProvider');
    await Future.delayed(const Duration(seconds: 3));

    // AHORA sí cerrar el stream
    await _transcriptionSubscription?.cancel();
    _transcriptionSubscription = null;

    // Si recibimos una transcripción, procesarla
    if (_currentTranscript.isNotEmpty && _state == VoiceCommandState.waitingTranscription) {
      developer.log('Processing transcript: $_currentTranscript', name: 'VoiceCommandProvider');
      await _processTranscript(_currentTranscript);
    } else if (_currentTranscript.isEmpty) {
      developer.log('No transcription received', name: 'VoiceCommandProvider');
      _setState(VoiceCommandState.idle);
    } else if (_state == VoiceCommandState.waitingTranscription) {
      _setState(VoiceCommandState.idle);
    }

    developer.log('Listening stopped', name: 'VoiceCommandProvider');
  }

  /// Cancela el reconocimiento de voz y anuncia
  Future<void> cancelListening() async {
    developer.log('User cancelled listening', name: 'VoiceCommandProvider');

    await stopListening();
    await _ttsService.speak('Cancelado');

    _currentTranscript = '';
    _setState(VoiceCommandState.idle);
  }

  /// Procesa la transcripción y ejecuta el comando
  Future<void> _processTranscript(String transcript) async {
    developer.log(
      'Processing transcript: $transcript',
      name: 'VoiceCommandProvider',
    );

    _cancelTimeout();

    _setState(VoiceCommandState.processing);

    try {
      // Parsear comando
      final command = NLPParser.parse(transcript);
      _lastCommand = command;

      developer.log(
        'Parsed command: ${command.type}',
        name: 'VoiceCommandProvider',
      );

      // Ejecutar comando
      await _executeCommand(command);

      _setState(VoiceCommandState.idle);
    } catch (e, stackTrace) {
      developer.log(
        'Error processing command',
        name: 'VoiceCommandProvider',
        error: e,
        stackTrace: stackTrace,
      );
      _handleError('Error ejecutando comando');
    }
  }

  /// Ejecuta el comando reconocido
  Future<void> _executeCommand(VoiceCommand command) async {
    developer.log(
      'Executing command: ${command.type}',
      name: 'VoiceCommandProvider',
    );

    switch (command.type) {
      case CommandType.requestHelp:
        await _ttsService.speak('Generando código de sesión para ayuda remota');

        // Navegar a RemoteControlHostScreen usando callback
        if (_navigationCallback != null) {
          _navigationCallback!(const RemoteControlHostScreen());
          developer.log(
            'Navigating to RemoteControlHostScreen',
            name: 'VoiceCommandProvider',
          );
        } else {
          developer.log(
            'Navigation callback not set',
            name: 'VoiceCommandProvider',
          );
        }
        break;

      case CommandType.openWhatsApp:
        await _ttsService.speak('Abriendo WhatsApp');
        // TODO: Llamar platform channel
        // Nota: Este TODO se implementará en Feature 5 (WhatsApp Integration)
        // junto con comandos avanzados como "abrir chat de [nombre]"
        developer.log(
          'TODO: Call platform channel to open WhatsApp',
          name: 'VoiceCommandProvider',
        );
        break;

      case CommandType.toggleContrast:
        // Toggle del tema
        _themeProvider.toggleContrast();

        // Anunciar nuevo estado
        final newMode = _themeProvider.isHighContrast
            ? 'alto contraste'
            : 'contraste normal';
        await _ttsService.speak('Cambiando a $newMode');

        developer.log(
          'Theme toggled to: ${_themeProvider.currentMode}',
          name: 'VoiceCommandProvider',
        );
        break;

      case CommandType.adjustVolumeUp:
        await _ttsService.increaseVolume();
        final percentageUp = (_ttsService.volume * 100).round();
        await _ttsService.speak('Volumen al $percentageUp por ciento');
        developer.log(
          'Volume increased to: ${_ttsService.volume}',
          name: 'VoiceCommandProvider',
        );
        break;

      case CommandType.adjustVolumeDown:
        await _ttsService.decreaseVolume();
        final percentageDown = (_ttsService.volume * 100).round();
        await _ttsService.speak('Volumen al $percentageDown por ciento');
        developer.log(
          'Volume decreased to: ${_ttsService.volume}',
          name: 'VoiceCommandProvider',
        );
        break;

      case CommandType.setVolumeMax:
        await _ttsService.setVolume(1.0);
        await _ttsService.speak('Volumen al máximo');
        developer.log(
          'Volume set to maximum: 1.0',
          name: 'VoiceCommandProvider',
        );
        break;

      case CommandType.setVolumeMin:
        await _ttsService.setVolume(0.0);
        await _ttsService.speak('Volumen en silencio');
        developer.log(
          'Volume set to minimum: 0.0',
          name: 'VoiceCommandProvider',
        );
        break;

      case CommandType.setVolumePercentage:
        final percentage = command.parameters?['percentage'] as int?;
        if (percentage != null) {
          final volume = percentage / 100.0;
          await _ttsService.setVolume(volume);
          await _ttsService.speak('Volumen al $percentage por ciento');
          developer.log(
            'Volume set to percentage: $percentage% ($volume)',
            name: 'VoiceCommandProvider',
          );
        } else {
          developer.log(
            'ERROR: setVolumePercentage without percentage parameter',
            name: 'VoiceCommandProvider',
          );
          await _ttsService.speak('Error al ajustar el volumen');
        }
        break;

      case CommandType.playTutorial:
        await _playTutorial();
        developer.log(
          'Playing tutorial',
          name: 'VoiceCommandProvider',
        );
        break;

      case CommandType.listCommands:
        await _listAvailableCommands();
        developer.log(
          'Listing available commands',
          name: 'VoiceCommandProvider',
        );
        break;

      case CommandType.cancel:
        await _ttsService.speak('Cancelado');
        break;

      case CommandType.unknown:
        await _ttsService.speak('No entendí el comando. Intenta de nuevo.');
        developer.log(
          'Unknown command: ${command.originalText}',
          name: 'VoiceCommandProvider',
        );
        break;
    }
  }

  /// Reproduce el tutorial de uso de la app
  Future<void> _playTutorial() async {
    const tutorial = '''
Bienvenido al tutorial de la aplicación.

Esta app te ayuda a comunicarte con tu familia y recibir asistencia remota.

Los comandos principales son:

Primero: Di "solicitar ayuda" para que un familiar se conecte a tu pantalla.

Segundo: Di "abrir WhatsApp" para abrir la aplicación de mensajes.

Tercero: Di "alto contraste" para cambiar los colores de la pantalla.

Cuarto: Di "subir volumen" o "bajar volumen" para ajustar el sonido.

Quinto: Di "comandos disponibles" para escuchar esta lista nuevamente.

Para cancelar, di "cancelar" en cualquier momento.

Fin del tutorial.
''';

    await _ttsService.speak(tutorial);
  }

  /// Lista los comandos disponibles por TTS
  Future<void> _listAvailableCommands() async {
    const commands = '''
Los comandos disponibles son:

Solicitar ayuda: Genera un código para que tu familiar se conecte.

Abrir WhatsApp: Abre la aplicación de mensajes.

Alto contraste: Cambia el tema de colores.

Subir volumen o bajar volumen: Ajusta el sonido.

Volumen al máximo o silencio: Establece el volumen.

Volumen al cincuenta por ciento: Establece un nivel específico.

Tutorial: Escucha una guía sobre cómo usar la app.

Cancelar: Detiene el reconocimiento de voz.
''';

    await _ttsService.speak(commands);
  }

  /// Inicia el timer de timeout (10 segundos)
  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_timeoutDuration, () {
      developer.log('Voice command timeout', name: 'VoiceCommandProvider');
      _handleTimeout();
    });
  }

  /// Resetea el timer de timeout (llamado en cada palabra)
  void _resetTimeout() {
    _startTimeout();
  }

  /// Cancela el timer de timeout
  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Maneja el timeout de 10 segundos
  Future<void> _handleTimeout() async {
    developer.log('Handling timeout', name: 'VoiceCommandProvider');

    await stopListening();
    await _ttsService.speak('Tiempo agotado');

    _currentTranscript = '';
    _setState(VoiceCommandState.idle);
  }

  /// Maneja errores durante el reconocimiento
  void _handleError(String message) {
    _errorMessage = message;
    _setState(VoiceCommandState.error);

    _cancelTimeout();
    _transcriptionSubscription?.cancel();
    _transcriptionSubscription = null;

    // Anunciar error via TTS
    _ttsService.speak(message);
  }

  /// Cambia el estado y notifica listeners
  void _setState(VoiceCommandState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Limpia recursos
  @override
  void dispose() {
    developer.log('Disposing VoiceCommandProvider', name: 'VoiceCommandProvider');

    _cancelTimeout();
    _transcriptionSubscription?.cancel();

    super.dispose();
  }
}
