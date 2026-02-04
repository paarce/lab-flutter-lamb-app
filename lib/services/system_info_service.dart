import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import '../errors/app_error.dart';
import '../errors/error_category.dart';

/// Servicio para obtener información del sistema Android
///
/// Usa Platform Channel para comunicarse con código nativo Kotlin
/// que obtiene hora, fecha y nivel de batería.
class SystemInfoService {
  static const _platform = MethodChannel('com.accessibilityapp/system_info');

  /// Obtiene la hora actual formateada para TTS
  ///
  /// Formato: "2:30 de la tarde" (accesible para adultos mayores)
  ///
  /// Throws [AppError] si falla la llamada al platform channel
  Future<String> getTime() async {
    developer.log('Getting current time', name: 'SystemInfoService');

    try {
      final result = await _platform.invokeMethod<String>('getTime');
      developer.log('Time obtained: $result', name: 'SystemInfoService');
      return result ?? 'Hora no disponible';
    } on PlatformException catch (e) {
      developer.log(
        'Failed to get time: ${e.code} - ${e.message}',
        name: 'SystemInfoService',
        error: e,
      );

      throw AppError(
        category: ErrorCategory.platformChannel,
        code: e.code,
        technicalMessage: e.message,
        userMessage: 'No se pudo obtener la hora',
        stackTrace: e.stacktrace != null ? StackTrace.fromString(e.stacktrace!) : null,
      );
    } catch (e) {
      developer.log(
        'Unexpected error getting time: $e',
        name: 'SystemInfoService',
        error: e,
      );
      rethrow;
    }
  }

  /// Obtiene la fecha actual formateada para TTS
  ///
  /// Formato: "25 de enero de 2026" (accesible para adultos mayores)
  ///
  /// Throws [AppError] si falla la llamada al platform channel
  Future<String> getDate() async {
    developer.log('Getting current date', name: 'SystemInfoService');

    try {
      final result = await _platform.invokeMethod<String>('getDate');
      developer.log('Date obtained: $result', name: 'SystemInfoService');
      return result ?? 'Fecha no disponible';
    } on PlatformException catch (e) {
      developer.log(
        'Failed to get date: ${e.code} - ${e.message}',
        name: 'SystemInfoService',
        error: e,
      );

      throw AppError(
        category: ErrorCategory.platformChannel,
        code: e.code,
        technicalMessage: e.message,
        userMessage: 'No se pudo obtener la fecha',
        stackTrace: e.stacktrace != null ? StackTrace.fromString(e.stacktrace!) : null,
      );
    } catch (e) {
      developer.log(
        'Unexpected error getting date: $e',
        name: 'SystemInfoService',
        error: e,
      );
      rethrow;
    }
  }

  /// Obtiene el nivel de batería actual
  ///
  /// Returns porcentaje de 0 a 100
  ///
  /// Throws [AppError] si falla la llamada al platform channel
  Future<int> getBatteryLevel() async {
    developer.log('Getting battery level', name: 'SystemInfoService');

    try {
      final result = await _platform.invokeMethod<int>('getBatteryLevel');
      developer.log('Battery level obtained: $result%', name: 'SystemInfoService');
      return result ?? 0;
    } on PlatformException catch (e) {
      developer.log(
        'Failed to get battery level: ${e.code} - ${e.message}',
        name: 'SystemInfoService',
        error: e,
      );

      throw AppError(
        category: ErrorCategory.platformChannel,
        code: e.code,
        technicalMessage: e.message,
        userMessage: 'No se pudo obtener el nivel de batería',
        stackTrace: e.stacktrace != null ? StackTrace.fromString(e.stacktrace!) : null,
      );
    } catch (e) {
      developer.log(
        'Unexpected error getting battery level: $e',
        name: 'SystemInfoService',
        error: e,
      );
      rethrow;
    }
  }
}
