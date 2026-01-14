import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// Service for managing the foreground service required for MediaProjection
///
/// Android 14+ (API 34+) requires a foreground service with type
/// FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION to be running before
/// MediaProjection can be started.
///
/// This service communicates with the native ScreenCaptureService via
/// Platform Channel to start/stop the foreground service.
///
/// Usage:
/// ```dart
/// final service = ForegroundService();
///
/// // Start before initializing WebRTC with screen capture
/// await service.start();
///
/// // ... use WebRTC screen capture ...
///
/// // Stop when done
/// await service.stop();
/// ```
class ForegroundService {
  static const _platform =
      MethodChannel('com.accessibilityapp/foreground_service');

  /// Starts the foreground service for screen capture
  ///
  /// This MUST be called before attempting to use MediaProjection via
  /// flutter_webrtc's getDisplayMedia().
  ///
  /// Throws [PlatformException] if service fails to start
  Future<void> start() async {
    try {
      developer.log(
        'Starting foreground service',
        name: 'ForegroundService',
      );

      final result = await _platform.invokeMethod<bool>('startForegroundService');

      if (result == true) {
        developer.log(
          'Foreground service started successfully',
          name: 'ForegroundService',
        );
      } else {
        throw Exception('Failed to start foreground service: returned false');
      }
    } on PlatformException catch (e) {
      developer.log(
        'Platform error starting foreground service',
        name: 'ForegroundService',
        error: e,
      );
      rethrow;
    } catch (e) {
      developer.log(
        'Unexpected error starting foreground service',
        name: 'ForegroundService',
        error: e,
      );
      rethrow;
    }
  }

  /// Stops the foreground service
  ///
  /// Should be called when screen capture is no longer needed to free
  /// system resources and remove the notification.
  ///
  /// Throws [PlatformException] if service fails to stop
  Future<void> stop() async {
    try {
      developer.log(
        'Stopping foreground service',
        name: 'ForegroundService',
      );

      final result = await _platform.invokeMethod<bool>('stopForegroundService');

      if (result == true) {
        developer.log(
          'Foreground service stopped successfully',
          name: 'ForegroundService',
        );
      } else {
        throw Exception('Failed to stop foreground service: returned false');
      }
    } on PlatformException catch (e) {
      developer.log(
        'Platform error stopping foreground service',
        name: 'ForegroundService',
        error: e,
      );
      rethrow;
    } catch (e) {
      developer.log(
        'Unexpected error stopping foreground service',
        name: 'ForegroundService',
        error: e,
      );
      rethrow;
    }
  }

  /// Opens the Android Accessibility Settings screen
  ///
  /// Use this to guide users to enable the AssistantAccessibilityService
  /// which is required for remote tap simulation.
  ///
  /// Throws [PlatformException] if settings cannot be opened
  Future<void> openAccessibilitySettings() async {
    try {
      developer.log(
        'Opening accessibility settings',
        name: 'ForegroundService',
      );

      await _platform.invokeMethod('openAccessibilitySettings');

      developer.log(
        'Accessibility settings opened',
        name: 'ForegroundService',
      );
    } on PlatformException catch (e) {
      developer.log(
        'Failed to open accessibility settings',
        name: 'ForegroundService',
        error: e,
      );
      rethrow;
    } catch (e) {
      developer.log(
        'Unexpected error opening accessibility settings',
        name: 'ForegroundService',
        error: e,
      );
      rethrow;
    }
  }
}
