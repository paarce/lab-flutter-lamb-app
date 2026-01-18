import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../models/command.dart';
import '../services/elevenlabs_service.dart';
import '../services/tts/tts_service.dart';
import '../utils/nlp_parser.dart';

/// Estados del sistema de comandos de voz
enum VoiceCommandState {
  /// Inactivo, esperando que usuario inicie
  idle,

  /// Escuchando audio y transcribiendo
  listening,

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
  })  : _sttService = sttService,
        _ttsService = ttsService;

  /// Inicia el reconocimiento de voz
  ///
  /// - Cambia estado a listening
  /// - Inicia timeout de 10s
  /// - Escucha stream de transcripción
  /// - Anuncia "Escuchando" via TTS
  Future<void> startListening() async {
    developer.log('Starting voice command listening', name: 'VoiceCommandProvider');

    try {
      _setState(VoiceCommandState.listening);
      _currentTranscript = '';
      _errorMessage = null;
      notifyListeners();

      // Anunciar inicio con TTS
      await _ttsService.speak('Escuchando');

      // Iniciar timeout
      _startTimeout();

      // Escuchar transcripción en tiempo real
      final stream = _sttService.startListening();
      _transcriptionSubscription = stream.listen(
        (transcript) {
          if (transcript.isEmpty) return;

          developer.log(
            'Transcript received: $transcript',
            name: 'VoiceCommandProvider',
          );

          _currentTranscript = transcript;
          _resetTimeout(); // Reset timeout en cada palabra
          notifyListeners();

          // Heurística: 3+ palabras = frase completa, procesar
          final wordCount = transcript.trim().split(RegExp(r'\s+')).length;
          if (wordCount >= 3) {
            developer.log(
              'Transcript has $wordCount words, processing command',
              name: 'VoiceCommandProvider',
            );
            _processTranscript(transcript);
          }
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
    developer.log('Stopping voice command listening', name: 'VoiceCommandProvider');

    _cancelTimeout();
    await _transcriptionSubscription?.cancel();
    _transcriptionSubscription = null;

    await _sttService.stopListening();

    if (_state != VoiceCommandState.processing) {
      _setState(VoiceCommandState.idle);
    }
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
    await stopListening();

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
        // TODO: Navegar a RemoteControlHostScreen
        developer.log(
          'TODO: Navigate to RemoteControlHostScreen',
          name: 'VoiceCommandProvider',
        );
        break;

      case CommandType.openWhatsApp:
        await _ttsService.speak('Abriendo WhatsApp');
        // TODO: Llamar platform channel
        developer.log(
          'TODO: Call platform channel to open WhatsApp',
          name: 'VoiceCommandProvider',
        );
        break;

      case CommandType.toggleContrast:
        await _ttsService.speak('Cambiando contraste');
        // TODO: Cambiar tema via ThemeProvider
        developer.log(
          'TODO: Toggle theme via ThemeProvider',
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
