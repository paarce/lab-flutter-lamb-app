import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import '../errors/app_error.dart';
import '../errors/error_category.dart';

/// Service for WhatsApp automation via platform channel
///
/// Comunicación Flutter ↔ Kotlin para:
/// - Abrir WhatsApp
/// - Abrir chat específico (futuro)
/// - Enviar mensajes (futuro)
/// - Leer mensajes (futuro)
///
/// Nota: Requiere AccessibilityService en Android
class WhatsAppService {
  static const _platform = MethodChannel('com.accessibilityapp/whatsapp');

  /// Abre la aplicación WhatsApp
  ///
  /// Throws [AppError] si:
  /// - WhatsApp no está instalado (code: 'NOT_FOUND')
  /// - Error del platform channel
  Future<void> openWhatsApp() async {
    developer.log('Opening WhatsApp', name: 'WhatsAppService');

    try {
      await _platform.invokeMethod('openWhatsApp');

      developer.log('WhatsApp opened successfully', name: 'WhatsAppService');
    } on PlatformException catch (e) {
      developer.log(
        'Failed to open WhatsApp',
        name: 'WhatsAppService',
        error: e,
      );

      throw AppError(
        category: ErrorCategory.platformChannel,
        code: e.code,
        technicalMessage: e.message,
        userMessage: _getUserMessage(e.code),
        stackTrace: e.stacktrace != null ? StackTrace.fromString(e.stacktrace!) : null,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error opening WhatsApp',
        name: 'WhatsAppService',
        error: e,
        stackTrace: stackTrace,
      );

      throw AppError(
        category: ErrorCategory.platformChannel,
        code: 'UNKNOWN_ERROR',
        technicalMessage: e.toString(),
        userMessage: 'Error al abrir WhatsApp',
        stackTrace: stackTrace,
      );
    }
  }

  /// Verifica si WhatsApp está instalado
  ///
  /// Returns [true] si está instalado, [false] si no
  Future<bool> isInstalled() async {
    developer.log('Checking if WhatsApp is installed', name: 'WhatsAppService');

    try {
      final result = await _platform.invokeMethod<bool>('isWhatsAppInstalled');
      final isInstalled = result ?? false;

      developer.log(
        'WhatsApp installed: $isInstalled',
        name: 'WhatsAppService',
      );

      return isInstalled;
    } catch (e) {
      developer.log(
        'Error checking WhatsApp installation',
        name: 'WhatsAppService',
        error: e,
      );
      return false;
    }
  }

  /// Abre un chat de WhatsApp con un número de teléfono específico
  ///
  /// [phoneNumber] Número de teléfono con código de país (e.g., +525512345678)
  ///
  /// Uses wa.me deep link to open the chat directly
  ///
  /// Throws [AppError] si:
  /// - WhatsApp no está instalado (code: 'NOT_FOUND')
  /// - Número inválido (code: 'INVALID_PHONE')
  /// - Error del platform channel
  Future<void> openChatByPhone(String phoneNumber) async {
    // Sanitize phone number: remove spaces, dashes, parentheses
    final sanitized = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    developer.log(
      'Opening WhatsApp chat for phone: $sanitized',
      name: 'WhatsAppService',
    );

    try {
      await _platform.invokeMethod('openChatByPhone', {
        'phone': sanitized,
      });

      developer.log(
        'WhatsApp chat opened successfully',
        name: 'WhatsAppService',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Failed to open WhatsApp chat',
        name: 'WhatsAppService',
        error: e,
      );

      throw AppError(
        category: ErrorCategory.platformChannel,
        code: e.code,
        technicalMessage: e.message,
        userMessage: _getUserMessage(e.code),
        stackTrace: e.stacktrace != null ? StackTrace.fromString(e.stacktrace!) : null,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error opening WhatsApp chat',
        name: 'WhatsAppService',
        error: e,
        stackTrace: stackTrace,
      );

      throw AppError(
        category: ErrorCategory.platformChannel,
        code: 'UNKNOWN_ERROR',
        technicalMessage: e.toString(),
        userMessage: 'Error al abrir el chat de WhatsApp',
        stackTrace: stackTrace,
      );
    }
  }

  /// Convierte códigos de error a mensajes para usuario
  String _getUserMessage(String code) {
    switch (code) {
      case 'NOT_FOUND':
        return 'WhatsApp no está instalado en este dispositivo';
      case 'PERMISSION_DENIED':
        return 'Se requiere permiso de Accesibilidad para usar WhatsApp';
      case 'INVALID_PHONE':
        return 'El número de teléfono no es válido';
      case 'CHAT_OPEN_FAILED':
        return 'No se pudo abrir el chat de WhatsApp';
      default:
        return 'Error al abrir WhatsApp';
    }
  }
}
