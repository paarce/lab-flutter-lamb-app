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
        userMessage: _getUserMessage(e.code),
        originalError: e,
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
        userMessage: 'Error al abrir WhatsApp',
        originalError: e,
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

  /// Convierte códigos de error a mensajes para usuario
  String _getUserMessage(String code) {
    switch (code) {
      case 'NOT_FOUND':
        return 'WhatsApp no está instalado en este dispositivo';
      case 'PERMISSION_DENIED':
        return 'Se requiere permiso de Accesibilidad para usar WhatsApp';
      default:
        return 'Error al abrir WhatsApp';
    }
  }
}
