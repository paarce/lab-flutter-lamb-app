import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../errors/app_error.dart';
import '../errors/error_category.dart';
import '../errors/error_codes.dart';
import '../utils/error_messages.dart';
import 'logger_service.dart';
import 'tts/tts_factory.dart';

/// Central error handling service
///
/// Single point where ALL app errors are handled.
/// Responsibilities:
/// 1. Show accessible modal dialog
/// 2. Play error message with TTS (automatically via TTSFactory)
/// 3. Log error
/// 4. Offer options (Retry, Close)
class ErrorHandlerService {
  static final LoggerService _logger = LoggerService();

  /// Main error handler - processes any error and shows accessible dialog
  static Future<void> handleError({
    required BuildContext context,
    required dynamic error,
    required String service,
    bool canRetry = false,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    // Paso 1: Normalizar el error a AppError
    final appError = _normalizeError(error, service);

    // Paso 2: Registrar en logs
    _logger.error(
      'Error en $service',
      tag: 'ErrorHandlerService',
      error: appError,
      stackTrace: appError.stackTrace,
    );

    // Paso 3: Obtener mensaje accesible
    final userMessage = ErrorMessages.getUserMessage(appError);

    // Paso 4: Reproducir con TTS usando TTSFactory
    try {
      final ttsService = TTSFactory.getInstance();
      await ttsService.speak(userMessage);
    } catch (e) {
      _logger.error('Error al reproducir TTS', tag: 'ErrorHandlerService');
      // Continuar incluso si TTS falla
    }

    // Paso 5: Mostrar diálogo modal accesible
    if (context.mounted) {
      await _showAccessibleErrorDialog(
        context: context,
        userMessage: userMessage,
        errorCode: appError.code,
        canRetry: canRetry,
        onRetry: onRetry,
        onDismiss: onDismiss,
      );
    }
  }

  /// Convierte cualquier tipo de error a AppError
  static AppError _normalizeError(dynamic error, String service) {
    // Si ya es AppError, devolverlo
    if (error is AppError) {
      return error;
    }

    // Si es PlatformException (Platform Channel)
    if (error is PlatformException) {
      return AppError(
        category: ErrorCategory.platformChannel,
        code: error.code,
        technicalMessage: error.message,
        userMessage: _getUserMessageForPlatformException(error),
        canRetry: _canRetryPlatformException(error),
      );
    }

    // Si es FirebaseException (verificar por nombre de clase)
    if (error.runtimeType.toString().contains('Firebase') ||
        error.toString().contains('FirebaseException')) {
      return AppError(
        category: ErrorCategory.firebase,
        code: error.toString().contains('permission')
            ? ErrorCodes.fbNetworkError
            : ErrorCodes.fbFirestoreFailed,
        technicalMessage: error.toString(),
        userMessage: 'Error al sincronizar datos.',
        canRetry: true,
      );
    }

    // Si es SocketException (sin internet)
    if (error is SocketException) {
      return AppError(
        category: ErrorCategory.network,
        code: ErrorCodes.netNoInternet,
        technicalMessage: error.toString(),
        userMessage: ErrorMessages.getUserMessage(
          AppError(
            category: ErrorCategory.network,
            code: ErrorCodes.netNoInternet,
            userMessage: '',
          ),
        ),
        canRetry: true,
      );
    }

    // Si es TimeoutException
    if (error is TimeoutException) {
      return AppError(
        category: ErrorCategory.network,
        code: ErrorCodes.netTimeout,
        technicalMessage: error.toString(),
        userMessage: ErrorMessages.getUserMessage(
          AppError(
            category: ErrorCategory.network,
            code: ErrorCodes.netTimeout,
            userMessage: '',
          ),
        ),
        canRetry: true,
      );
    }

    // Error genérico
    return AppError(
      category: ErrorCategory.unknown,
      code: 'UNKNOWN_ERROR',
      technicalMessage: error.toString(),
      userMessage: 'Ha ocurrido un problema. Intenta de nuevo.',
      canRetry: true,
    );
  }

  /// Shows accessible error dialog with TalkBack support
  static Future<void> _showAccessibleErrorDialog({
    required BuildContext context,
    required String userMessage,
    required String errorCode,
    required bool canRetry,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // No cerrar al tocar afuera
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Semantics(
            label: 'Título del error',
            child: const Text(
              ErrorMessages.dialogTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mensaje principal
                Semantics(
                  label: 'Mensaje de error',
                  child: Text(
                    userMessage,
                    style: const TextStyle(
                      fontSize: 24,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),

                // Código de error (para debugging)
                Semantics(
                  label: 'Código de error',
                  child: Text(
                    'Código: $errorCode',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Botón "Cerrar" siempre visible
            Semantics(
              button: true,
              enabled: true,
              label: ErrorMessages.closeButtonText,
              onTap: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              child: SizedBox(
                height: 80,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDismiss?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    ErrorMessages.closeButtonText,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Botón "Reintentar" si aplica
            if (canRetry && onRetry != null)
              Semantics(
                button: true,
                enabled: true,
                label: ErrorMessages.retryButtonText,
                onTap: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: SizedBox(
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      ErrorMessages.retryButtonText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Helpers para Platform Channel
  static String _getUserMessageForPlatformException(PlatformException e) {
    switch (e.code) {
      case ErrorCodes.pcPermissionDenied:
        return ErrorMessages.getUserMessage(
          AppError(
            category: ErrorCategory.platformChannel,
            code: ErrorCodes.pcPermissionDenied,
            userMessage: '',
          ),
        );
      case ErrorCodes.pcAccessibilityServiceInactive:
        return ErrorMessages.getUserMessage(
          AppError(
            category: ErrorCategory.platformChannel,
            code: ErrorCodes.pcAccessibilityServiceInactive,
            userMessage: '',
          ),
        );
      default:
        return ErrorMessages.getUserMessage(
          AppError(
            category: ErrorCategory.platformChannel,
            code: e.code,
            userMessage: '',
          ),
        );
    }
  }

  static bool _canRetryPlatformException(PlatformException e) {
    // No reintentar estos errores
    if (e.code == ErrorCodes.pcAccessibilityServiceInactive ||
        e.code == ErrorCodes.pcPermissionDenied) {
      return false;
    }
    return true;
  }
}
