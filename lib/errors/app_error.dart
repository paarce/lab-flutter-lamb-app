import 'error_category.dart';

/// Modelo unificado para TODOS los errores de la app
///
/// Permite mantener consistencia en manejo de errores
/// sin importar de dónde viene (Firebase, ElevenLabs, Platform Channel, etc)
class AppError implements Exception {
  /// Categoría del error (Platform Channel, Firebase, etc)
  final ErrorCategory category;

  /// Código técnico del error (para logging/debugging)
  final String code;

  /// Mensaje técnico (sin traducir)
  final String? technicalMessage;

  /// Mensaje para usuario (accesible, en español, simple)
  final String userMessage;

  /// ¿Se puede reintentar automáticamente?
  final bool canRetry;

  /// Stack trace para debugging
  final StackTrace? stackTrace;

  /// Timestamp del error
  final DateTime timestamp;

  AppError({
    required this.category,
    required this.code,
    this.technicalMessage,
    required this.userMessage,
    this.canRetry = false,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'AppError[$category - $code]: $technicalMessage ($userMessage)';
}
