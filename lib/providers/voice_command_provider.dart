import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/command.dart';
import '../screens/remote_control_host_screen.dart';
import '../services/elevenlabs_service.dart';
import '../services/llm_parser_service.dart';
import '../services/system_info_service.dart';
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
  final SystemInfoService _systemInfoService;
  final LLMParserService? _llmParserService;

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

  /// Contador de comandos unknown consecutivos
  int _consecutiveUnknownCommands = 0;

  /// Máximo de comandos unknown antes de ayuda proactiva
  static const int _maxUnknownBeforeHelp = 3;

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
    required SystemInfoService systemInfoService,
    LLMParserService? llmParserService,
  })  : _sttService = sttService,
        _ttsService = ttsService,
        _themeProvider = themeProvider,
        _systemInfoService = systemInfoService,
        _llmParserService = llmParserService;

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
  ///
  /// Flujo de parsing híbrido:
  /// 1. Parser local de keywords (rápido, <50ms)
  /// 2. Si unknown, intentar LLM fallback (<3s timeout)
  Future<void> _processTranscript(String transcript) async {
    developer.log(
      'Processing transcript: $transcript',
      name: 'VoiceCommandProvider',
    );
    // TEMPORAL DEBUG
    debugPrint('🎤 [VoiceCommandProvider] Processing transcript: "$transcript"');

    _cancelTimeout();

    _setState(VoiceCommandState.processing);

    try {
      // Paso 1: Parser local de keywords (rápido, <50ms)
      var command = NLPParser.parse(transcript);

      developer.log(
        'Local parser result: ${command.type}',
        name: 'VoiceCommandProvider',
      );
      // TEMPORAL DEBUG
      debugPrint('🔍 [VoiceCommandProvider] Local parser result: ${command.type}');

      // Paso 2: Si unknown, intentar LLM fallback (si está disponible)
      if (command.type == CommandType.unknown && _llmParserService != null) {
        developer.log(
          'Local parser returned unknown, trying LLM fallback',
          name: 'VoiceCommandProvider',
        );
        // TEMPORAL DEBUG - Para testing TC-LLM-001
        debugPrint('🔵 [VoiceCommandProvider] Local parser returned unknown, trying LLM fallback');
        debugPrint('🔵 [VoiceCommandProvider] Transcript: "$transcript"');

        final llmCommand = await _llmParserService!.parse(transcript);
        if (llmCommand != null && llmCommand.type != CommandType.unknown) {
          command = llmCommand;
          developer.log(
            'LLM parsed command: ${command.type} with params: ${command.parameters}',
            name: 'VoiceCommandProvider',
          );
          // TEMPORAL DEBUG
          debugPrint('✅ [VoiceCommandProvider] LLM parsed command: ${command.type} with params: ${command.parameters}');
        } else {
          developer.log(
            'LLM also returned unknown or null',
            name: 'VoiceCommandProvider',
          );
          // TEMPORAL DEBUG
          debugPrint('❌ [VoiceCommandProvider] LLM also returned unknown or null');
        }
      }

      _lastCommand = command;

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
        // Reproducir tutorial directamente
        await _playTutorial();
        developer.log(
          'Playing tutorial as help response',
          name: 'VoiceCommandProvider',
        );
        _resetUnknownCounter();
        break;

      case CommandType.shareScreen:
        await _ttsService.speak('Abriendo control remoto para compartir pantalla');

        // Navegar a RemoteControlHostScreen usando callback
        if (_navigationCallback != null) {
          _navigationCallback!(const RemoteControlHostScreen());
          developer.log(
            'Navigating to RemoteControlHostScreen for screen sharing',
            name: 'VoiceCommandProvider',
          );
        } else {
          developer.log(
            'Navigation callback not set',
            name: 'VoiceCommandProvider',
          );
        }
        _resetUnknownCounter();
        break;

      case CommandType.openWhatsApp:
        final contact = command.parameters?['contact'] as String?;
        if (contact != null && contact.isNotEmpty) {
          await _ttsService.speak('Abriendo chat de $contact');
          developer.log(
            'Opening WhatsApp chat for contact: $contact',
            name: 'VoiceCommandProvider',
          );
        } else {
          await _ttsService.speak('Abriendo WhatsApp');
          developer.log(
            'Opening WhatsApp (no specific contact)',
            name: 'VoiceCommandProvider',
          );
        }
        // TODO: Llamar platform channel para abrir WhatsApp
        // Nota: Este TODO se implementará en Feature 5 (WhatsApp Integration)
        developer.log(
          'TODO: Call platform channel to open WhatsApp',
          name: 'VoiceCommandProvider',
        );
        _resetUnknownCounter();
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
        _resetUnknownCounter();
        break;

      case CommandType.adjustVolumeUp:
        await _ttsService.increaseVolume();
        final percentageUp = (_ttsService.volume * 100).round();
        await _ttsService.speak('Volumen al $percentageUp por ciento');
        developer.log(
          'Volume increased to: ${_ttsService.volume}',
          name: 'VoiceCommandProvider',
        );
        _resetUnknownCounter();
        break;

      case CommandType.adjustVolumeDown:
        await _ttsService.decreaseVolume();
        final percentageDown = (_ttsService.volume * 100).round();
        await _ttsService.speak('Volumen al $percentageDown por ciento');
        developer.log(
          'Volume decreased to: ${_ttsService.volume}',
          name: 'VoiceCommandProvider',
        );
        _resetUnknownCounter();
        break;

      case CommandType.setVolumeMax:
        await _ttsService.setVolume(1.0);
        await _ttsService.speak('Volumen al máximo');
        developer.log(
          'Volume set to maximum: 1.0',
          name: 'VoiceCommandProvider',
        );
        _resetUnknownCounter();
        break;

      case CommandType.setVolumeMin:
        await _ttsService.setVolume(0.0);
        await _ttsService.speak('Volumen en silencio');
        developer.log(
          'Volume set to minimum: 0.0',
          name: 'VoiceCommandProvider',
        );
        _resetUnknownCounter();
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
          _resetUnknownCounter();
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
        _resetUnknownCounter();
        break;

      case CommandType.listCommands:
        await _listAvailableCommands();
        developer.log(
          'Listing available commands',
          name: 'VoiceCommandProvider',
        );
        _resetUnknownCounter();
        break;

      // Comandos de Sistema (NUEVO)
      case CommandType.getTime:
        try {
          final time = await _systemInfoService.getTime();
          await _ttsService.speak('Son las $time');
          developer.log('Time announced: $time', name: 'VoiceCommandProvider');
          _resetUnknownCounter();
        } catch (e) {
          developer.log(
            'Failed to get time',
            name: 'VoiceCommandProvider',
            error: e,
          );
          await _ttsService.speak('No pude obtener la hora');
        }
        break;

      case CommandType.getDate:
        try {
          final date = await _systemInfoService.getDate();
          await _ttsService.speak('Hoy es $date');
          developer.log('Date announced: $date', name: 'VoiceCommandProvider');
          _resetUnknownCounter();
        } catch (e) {
          developer.log(
            'Failed to get date',
            name: 'VoiceCommandProvider',
            error: e,
          );
          await _ttsService.speak('No pude obtener la fecha');
        }
        break;

      case CommandType.getBatteryLevel:
        try {
          final level = await _systemInfoService.getBatteryLevel();
          await _ttsService.speak('Tienes $level por ciento de batería');
          developer.log(
            'Battery level: $level%',
            name: 'VoiceCommandProvider',
          );
          _resetUnknownCounter();
        } catch (e) {
          developer.log(
            'Failed to get battery level',
            name: 'VoiceCommandProvider',
            error: e,
          );
          await _ttsService.speak('No pude obtener el nivel de batería');
        }
        break;

      // Respuestas Sociales (LIMITADO - NUEVO)
      case CommandType.thankYou:
        await _ttsService.speak('De nada, para eso estoy');
        developer.log('User said thanks', name: 'VoiceCommandProvider');
        _resetUnknownCounter();
        break;

      case CommandType.goodbye:
        await _ttsService.speak('Hasta luego');
        developer.log('User said goodbye', name: 'VoiceCommandProvider');
        _resetUnknownCounter();
        break;

      // Conversación Rechazada (NUEVO)
      case CommandType.conversationRejected:
        // DEBUG: Mostrar que se ejecuta este caso
        debugPrint('🚫 [VoiceCommandProvider] CONVERSATION REJECTED for: "${command.originalText}"');
        debugPrint('🚫 [VoiceCommandProvider] Counter BEFORE: $_consecutiveUnknownCommands');

        await _ttsService.speak(
          'Hola. No puedo mantener conversaciones, pero puedo ayudarte con comandos. '
          'Di "comandos disponibles" para escuchar qué puedo hacer.',
        );
        developer.log(
          'Conversation attempt rejected',
          name: 'VoiceCommandProvider',
        );
        _incrementUnknownCounter();

        // DEBUG: Mostrar contador después
        debugPrint('🚫 [VoiceCommandProvider] Counter AFTER: $_consecutiveUnknownCommands');
        break;

      case CommandType.cancel:
        await _ttsService.speak('Cancelado');
        _resetUnknownCounter();
        break;

      case CommandType.unknown:
        // DEBUG: Mostrar que se ejecuta este caso
        debugPrint('❓ [VoiceCommandProvider] UNKNOWN COMMAND for: "${command.originalText}"');
        debugPrint('❓ [VoiceCommandProvider] Counter BEFORE: $_consecutiveUnknownCommands');

        _incrementUnknownCounter();

        // DEBUG: Mostrar contador después
        debugPrint('❓ [VoiceCommandProvider] Counter AFTER: $_consecutiveUnknownCommands');

        if (_consecutiveUnknownCommands >= _maxUnknownBeforeHelp) {
          // Ayuda proactiva después de 3 fallos
          debugPrint('🆘 [VoiceCommandProvider] PROACTIVE HELP TRIGGERED! Counter = $_consecutiveUnknownCommands');
          await _ttsService.speak(
            'No he podido entender tus últimos comandos. '
            'Voy a reproducir la lista de comandos disponibles.',
          );
          await _listAvailableCommands();
          _resetUnknownCounter();
        } else {
          await _ttsService.speak('No entendí el comando. Intenta de nuevo.');
        }

        developer.log(
          'Unknown command: ${command.originalText} (count: $_consecutiveUnknownCommands)',
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

Primero: Di "compartir pantalla" para que un familiar vea tu pantalla y te ayude.

Segundo: Di "abrir WhatsApp" para abrir la aplicación de mensajes.

Tercero: Di "alto contraste" para cambiar los colores de la pantalla.

Cuarto: Di "subir volumen" o "bajar volumen" para ajustar el sonido.

Quinto: Di "qué hora es" o "cuánta batería tengo" para información del sistema.

Sexto: Di "comandos disponibles" para escuchar la lista completa.

Para cancelar, di "cancelar" en cualquier momento.

Fin del tutorial.
''';

    await _ttsService.speak(tutorial);
  }

  /// Lista los comandos disponibles por TTS
  Future<void> _listAvailableCommands() async {
    const commands = '''
Los comandos disponibles son:

Compartir pantalla: Abre el control remoto para que alguien vea tu pantalla.

Solicitar ayuda: Reproduce el tutorial de la aplicación.

Abrir WhatsApp: Abre la aplicación de mensajes.

Alto contraste: Cambia el tema de colores.

Subir volumen o bajar volumen: Ajusta el sonido.

Volumen al máximo o silencio: Establece el volumen.

Volumen al cincuenta por ciento: Establece un nivel específico.

Información del sistema:
"Qué hora es" para saber la hora actual.
"Qué día es hoy" para saber la fecha.
"Cuánta batería tengo" para conocer el nivel de batería.

Comandos sociales:
"Gracias" cuando quieras agradecer.
"Adiós" cuando termines de usar la aplicación.

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

  /// Incrementa el contador de comandos unknown
  void _incrementUnknownCounter() {
    _consecutiveUnknownCommands++;
    developer.log(
      'Unknown counter: $_consecutiveUnknownCommands/$_maxUnknownBeforeHelp',
      name: 'VoiceCommandProvider',
    );
  }

  /// Resetea el contador de comandos unknown
  void _resetUnknownCounter() {
    if (_consecutiveUnknownCommands > 0) {
      developer.log(
        'Resetting unknown counter from $_consecutiveUnknownCommands to 0',
        name: 'VoiceCommandProvider',
      );
      _consecutiveUnknownCommands = 0;
    }
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
    _llmParserService?.dispose();

    super.dispose();
  }
}
