import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../tts_service.dart';
import '../tts_config.dart';

/// Implementación de TTSService usando flutter_tts (motor nativo Android/iOS)
///
/// Características:
/// - Gratis y totalmente offline
/// - Bajo latencia (50-200ms)
/// - Voces sintetizadas de calidad aceptable
/// - Soporta español y múltiples idiomas
///
/// Parámetros específicos (no configurables desde fuera):
/// - Motor: Usar motor TTS nativo del sistema Android/iOS
/// - Voces disponibles: Las del sistema operativo
class FlutterTtsService extends TTSService {
  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  double _currentVolume = TTSConfig.volume;
  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  /// Constructor por defecto
  FlutterTtsService() {
    _initialize();
  }

  /// Inicializa el motor TTS nativo
  Future<void> _initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      _flutterTts = FlutterTts();
      await _flutterTts.setLanguage(TTSConfig.language);
      await _flutterTts.setPitch(TTSConfig.pitch);
      await _flutterTts.setSpeechRate(TTSConfig.speed);
      await _flutterTts.setVolume(TTSConfig.volume);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error inicializando FlutterTts: $e');
      rethrow;
    }
  }

  @override
  Future<void> speak(
    String text, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
    Function(String)? onError,
  }) async {
    if (!_isInitialized) {
      await _initialize();
    }

    try {
      // Configurar callback de inicio (más preciso que llamar onStart directamente)
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        WakelockPlus.enable();
        debugPrint('TTS started - wakelock enabled');
        onStart?.call();
      });

      // Configurar callback de completado
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        WakelockPlus.disable();
        debugPrint('TTS completed - wakelock disabled');
        onComplete?.call();
      });

      // Configurar callback de cancelación
      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        WakelockPlus.disable();
        debugPrint('TTS cancelled - wakelock disabled');
      });

      // Configurar callback de error
      _flutterTts.setErrorHandler((message) {
        _isSpeaking = false;
        WakelockPlus.disable();
        debugPrint('TTS error: $message - wakelock disabled');
        onError?.call(message.toString());
      });

      // Reproducir
      await _flutterTts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      await WakelockPlus.disable();
      debugPrint('Error en TTS speak: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    try {
      _isSpeaking = false;
      await WakelockPlus.disable();
      await _flutterTts.stop();
      debugPrint('TTS stopped - wakelock disabled');
    } catch (e) {
      debugPrint('Error deteniendo TTS: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint('Error pausando TTS: $e');
    }
  }

  @override
  Future<void> resume() async {
    try {
      // flutter_tts no tiene resume en todas las versiones
      // Por ahora, volver a hablar el último texto sería la alternativa
      // pero requeriría guardar estado, así que lo dejamos como no-op
      debugPrint('Resume no es soportado por flutter_tts');
    } catch (e) {
      debugPrint('Error en resume TTS: $e');
    }
  }

  @override
  double get volume => _currentVolume;

  @override
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) {
      await _initialize();
    }

    try {
      _currentVolume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_currentVolume);
      debugPrint('TTS volume set to: $_currentVolume');
    } catch (e) {
      debugPrint('Error setting TTS volume: $e');
    }
  }

  @override
  Future<void> increaseVolume({double step = 0.1}) async {
    await setVolume(_currentVolume + step);
  }

  @override
  Future<void> decreaseVolume({double step = 0.1}) async {
    await setVolume(_currentVolume - step);
  }
}
