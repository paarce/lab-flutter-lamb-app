import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../errors/app_error.dart';
import '../../errors/error_category.dart';
import '../../errors/error_codes.dart';
import '../../models/image_description.dart';

/// Interfaz abstracta para servicios de IA de visión
///
/// Mismo patrón que `TTSService`: la app depende de esta interfaz y la
/// implementación concreta se elige en `VisionServiceFactory` según
/// `ImageReaderConfig.provider`.
///
/// Implementaciones:
/// - `AnthropicVisionService` (default, Claude)
/// - `OpenAICompatibleVisionService` (OpenAI, DeepSeek, Gemini, Ollama...)
abstract class VisionService {
  /// Nombre del proveedor (para logs)
  String get providerName;

  /// Interpreta una imagen JPEG y devuelve un texto listo para TTS.
  ///
  /// Lanza [AppError] (categoría `llm`) si:
  /// - Falta la API key (`VISION_API_KEY_MISSING`, no reintentable)
  /// - La API responde con error o timeout (`VISION_REQUEST_FAILED`, `LLM_TIMEOUT`)
  /// - La respuesta no tiene texto utilizable (`VISION_EMPTY_RESPONSE`)
  Future<ImageDescription> describeImage(Uint8List jpegBytes);

  /// Libera recursos (cliente HTTP)
  void dispose();
}

/// Helpers compartidos por las implementaciones
abstract class VisionErrors {
  static AppError apiKeyMissing(String provider) => AppError(
        category: ErrorCategory.llm,
        code: ErrorCodes.visionApiKeyMissing,
        technicalMessage: 'API key not configured for $provider',
        userMessage: '',
        canRetry: false,
      );

  static AppError emptyResponse(String provider) => AppError(
        category: ErrorCategory.llm,
        code: ErrorCodes.visionEmptyResponse,
        technicalMessage: '$provider returned no usable text',
        userMessage: '',
        canRetry: true,
      );

  /// Traduce un código HTTP de error a [AppError]
  static AppError fromHttpStatus(String provider, int status, String body) {
    final String code;
    final bool canRetry;
    if (status == 401 || status == 403) {
      code = ErrorCodes.llmApiKeyInvalid;
      canRetry = false;
    } else if (status == 429) {
      code = ErrorCodes.llmRateLimitExceeded;
      canRetry = true;
    } else {
      code = ErrorCodes.visionRequestFailed;
      canRetry = true;
    }
    return AppError(
      category: ErrorCategory.llm,
      code: code,
      technicalMessage: '$provider HTTP $status: ${_truncate(body)}',
      userMessage: code == ErrorCodes.llmRateLimitExceeded
          ? 'El lector de fotos está ocupado. Espera un momento e intenta de nuevo.'
          : '',
      canRetry: canRetry,
    );
  }

  /// Envuelve errores de red/timeout. Los [AppError] pasan tal cual.
  static Object wrap(String provider, Object error, StackTrace stackTrace) {
    if (error is AppError) return error;
    if (error is TimeoutException) {
      return AppError(
        category: ErrorCategory.llm,
        code: ErrorCodes.llmTimeout,
        technicalMessage: '$provider timeout: $error',
        userMessage: 'El lector de fotos tardó demasiado. Intenta de nuevo.',
        canRetry: true,
        stackTrace: stackTrace,
      );
    }
    if (error is SocketException) {
      return AppError(
        category: ErrorCategory.network,
        code: ErrorCodes.netNoInternet,
        technicalMessage: '$provider network error: $error',
        userMessage: '',
        canRetry: true,
        stackTrace: stackTrace,
      );
    }
    return AppError(
      category: ErrorCategory.llm,
      code: ErrorCodes.visionRequestFailed,
      technicalMessage: '$provider unexpected error: $error',
      userMessage: '',
      canRetry: true,
      stackTrace: stackTrace,
    );
  }

  static String _truncate(String text) =>
      text.length > 300 ? '${text.substring(0, 300)}...' : text;
}
