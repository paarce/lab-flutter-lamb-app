import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors/app_error.dart';
import '../errors/error_category.dart';
import '../errors/error_codes.dart';
import '../models/remote_session.dart';
import '../services/firebase_signaling_service.dart';
import '../services/foreground_service.dart';
import '../services/webrtc_service.dart';
import '../services/tts/tts_factory.dart';

/// State management provider for remote control sessions
///
/// Orchestrates:
/// - FirebaseSignalingService (session management & signaling)
/// - WebRTCService (peer connection & MediaProjection via flutter_webrtc)
///
/// Note: Screen capture and MediaProjection are now handled entirely by
/// flutter_webrtc plugin in WebRTCService.
///
/// Exposes simple API for UI:
/// - startRemoteSession()
/// - endRemoteSession()
/// - sessionCode, connectionStatus, etc.
class RemoteControlProvider extends ChangeNotifier {
  final FirebaseSignalingService _signalingService;
  late final WebRTCService _webrtcService;
  late final ForegroundService _foregroundService;

  /// Current remote session
  RemoteSession? _currentSession;

  RemoteSession? get currentSession => _currentSession;

  /// Current session code (6 digits)
  String? get sessionCode => _currentSession?.sessionCode;

  /// Connection status
  RemoteControlStatus _status = RemoteControlStatus.idle;

  RemoteControlStatus get status => _status;

  /// WebRTC connection state
  RTCPeerConnectionState? _connectionState;

  RTCPeerConnectionState? get connectionState => _connectionState;

  /// Error message (if any)
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  /// Flag to cancel ongoing operations
  bool _isCancelled = false;

  /// Flag to track if client intentionally disconnected (vs error)
  bool _clientInitiatedDisconnect = false;

  /// Last error that occurred (for detailed error handling)
  AppError? _lastError;

  AppError? get lastError => _lastError;

  /// Clears the last error
  void clearError() {
    _lastError = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Stream subscription for session updates
  StreamSubscription<RemoteSession?>? _sessionSubscription;

  /// Stream subscription for connection state updates
  StreamSubscription<RTCPeerConnectionState>? _connectionStateSubscription;

  RemoteControlProvider({
    required FirebaseSignalingService signalingService,
  })  : _signalingService = signalingService {
    // Initialize WebRTC service
    _webrtcService = WebRTCService(signalingService: _signalingService);

    // Initialize foreground service (required for Android 14+ MediaProjection)
    _foregroundService = ForegroundService();

    // TTS service is now auto-initialized via TTSFactory singleton
  }

  /// Starts a new remote control session
  ///
  /// Steps:
  /// 1. Create session in Firestore
  /// 2. Initialize WebRTC (which will request MediaProjection permission via flutter_webrtc)
  /// 3. Setup listeners for session and connection state
  ///
  /// Note: MediaProjection permission is requested automatically by flutter_webrtc
  /// when getDisplayMedia() is called inside WebRTCService.
  ///
  /// Returns session code if successful, null otherwise
  Future<String?> startRemoteSession() async {
    try {
      // Clear previous errors and reset cancellation flag
      _errorMessage = null;
      _isCancelled = false;

      _setStatus(RemoteControlStatus.creatingSession);

      // Step 1: Create session in Firestore
      _currentSession = await _signalingService.createSession();

      // Check if cancelled after async operation
      if (_isCancelled) {
        _currentSession = null;
        await _cleanup();
        return null;
      }

      if (_currentSession == null) {
        _setError('No se pudo crear la sesión remota. Intenta de nuevo.');
        _setStatus(RemoteControlStatus.error);
        return null;
      }

      _setStatus(RemoteControlStatus.requestingPermission);

      // Step 2a: Start foreground service (REQUIRED for Android 14+)
      try {
        await _foregroundService.start();

        if (_isCancelled) {
          await _cleanup();
          return null;
        }
      } catch (e) {
        developer.log(
          'Failed to start foreground service',
          name: 'RemoteControlProvider',
          error: e,
        );
        throw Exception(
          'No se pudo iniciar el servicio de captura de pantalla. '
          'Por favor, verifica los permisos de la aplicación.'
        );
      }

      // Step 2b: Initialize WebRTC (triggers MediaProjection permission)
      await _webrtcService.initializeAsHost(_currentSession!.sessionCode);

      if (_isCancelled) {
        await _cleanup();
        return null;
      }

      _setStatus(RemoteControlStatus.waitingForClient);

      // Step 3: Listen for session updates (client connection)
      _listenToSessionUpdates();

      // Step 4: Listen for WebRTC connection state changes
      _listenToConnectionState();

      developer.log(
        'Remote session started: ${_currentSession!.sessionCode}',
        name: 'RemoteControlProvider',
      );

      notifyListeners();
      return _currentSession!.sessionCode;
    } on Exception catch (e) {
      // Parse user-friendly error messages from exceptions
      String errorMessage = e.toString();

      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      _lastError = AppError(
        category: ErrorCategory.webRTC,
        code: ErrorCodes.wrtcConnectionFailed,
        technicalMessage: e.toString(),
        userMessage: errorMessage,
        canRetry: true,
      );

      _setError(errorMessage);
      _setStatus(RemoteControlStatus.error);
      await _cleanup();

      return null;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error starting session',
        name: 'RemoteControlProvider',
        error: e,
        stackTrace: stackTrace,
      );

      _lastError = AppError(
        category: ErrorCategory.unknown,
        code: ErrorCodes.unknownError,
        technicalMessage: e.toString(),
        userMessage: 'Error inesperado al iniciar la sesión. '
            'Por favor, cierra y vuelve a abrir la aplicación.',
        canRetry: false,
        stackTrace: stackTrace,
      );

      _setError(
        'Error inesperado al iniciar la sesión. '
        'Por favor, cierra y vuelve a abrir la aplicación.',
      );
      _setStatus(RemoteControlStatus.error);
      await _cleanup();

      return null;
    }
  }

  /// Ends the current remote control session
  Future<void> endRemoteSession() async {
    try {
      // Cancel any ongoing startRemoteSession operation
      _isCancelled = true;

      developer.log(
        'Ending remote control session',
        name: 'RemoteControlProvider',
      );

      if (_currentSession != null) {
        // Mark session as ended in Firestore
        await _signalingService.endSession(_currentSession!.sessionCode);
      }

      _setStatus(RemoteControlStatus.ended);

      // Cleanup resources
      await _cleanup();

      developer.log(
        'Remote session ended',
        name: 'RemoteControlProvider',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error ending remote session',
        name: 'RemoteControlProvider',
        error: e,
        stackTrace: stackTrace,
      );

      // Cleanup anyway
      await _cleanup();
    }
  }

  /// Listens for session updates from Firestore
  void _listenToSessionUpdates() {
    if (_currentSession == null) return;

    _sessionSubscription?.cancel();

    _sessionSubscription = _signalingService
        .watchSession(_currentSession!.sessionCode)
        .listen((session) {
      if (session == null) {
        // Session ended or expired - this is normal
        developer.log(
          'Session ended or expired',
          name: 'RemoteControlProvider',
        );
        _clientInitiatedDisconnect = true;
        _setStatus(RemoteControlStatus.ended);
        _cleanup();
        return;
      }

      _currentSession = session;

      // Update status based on session status
      switch (session.status) {
        case RemoteSessionStatus.waiting:
          _setStatus(RemoteControlStatus.waitingForClient);
          break;
        case RemoteSessionStatus.connecting:
          _setStatus(RemoteControlStatus.connecting);
          break;
        case RemoteSessionStatus.connected:
          _setStatus(RemoteControlStatus.connected);
          break;
        case RemoteSessionStatus.ended:
          // Client ended session normally - not an error
          _clientInitiatedDisconnect = true;
          _setStatus(RemoteControlStatus.ended);
          _cleanup();
          break;
        case RemoteSessionStatus.failed:
          _lastError = AppError(
            category: ErrorCategory.webRTC,
            code: ErrorCodes.wrtcConnectionFailed,
            technicalMessage: 'Session status changed to failed',
            userMessage: 'Conexión fallida',
            canRetry: true,
          );
          _setStatus(RemoteControlStatus.error);
          _setError('Conexión fallida');
          _cleanup();
          break;
      }

      notifyListeners();
    });
  }

  /// Listens for WebRTC connection state changes
  void _listenToConnectionState() {
    _connectionStateSubscription?.cancel();

    _connectionStateSubscription =
        _webrtcService.connectionStateStream.listen((state) {
      _connectionState = state;

      developer.log(
        'WebRTC connection state: $state',
        name: 'RemoteControlProvider',
      );

      // Update UI status based on WebRTC state
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          _setStatus(RemoteControlStatus.connecting);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _setStatus(RemoteControlStatus.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          // Client disconnected - treat as normal session end, not error
          // The client should have marked the session as "ended" in Firestore
          developer.log(
            'Client disconnected - treating as normal session end',
            name: 'RemoteControlProvider',
          );
          _clientInitiatedDisconnect = true;
          _setStatus(RemoteControlStatus.ended);
          _cleanup();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          // Only set error if not already marked as normal disconnect
          if (!_clientInitiatedDisconnect) {
            _lastError = AppError(
              category: ErrorCategory.webRTC,
              code: ErrorCodes.wrtcConnectionFailed,
              technicalMessage: 'Peer connection state failed',
              userMessage: 'Conexión WebRTC fallida',
              canRetry: true,
            );
            _setStatus(RemoteControlStatus.error);
            _setError('Conexión WebRTC fallida');
          }
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          // Connection closed - only treat as error if not normal disconnect
          if (!_clientInitiatedDisconnect) {
            _clientInitiatedDisconnect = true;
          }
          _setStatus(RemoteControlStatus.ended);
          break;
        default:
          break;
      }

      notifyListeners();
    });
  }

  /// Sets the current status and announces it via TTS
  void _setStatus(RemoteControlStatus status) {
    _status = status;
    developer.log(
      'Status changed: $status',
      name: 'RemoteControlProvider',
    );

    _announceStatus(status);
    notifyListeners();
  }

  /// Announces status changes via TTS
  Future<void> _announceStatus(RemoteControlStatus status) async {
    String message;

    switch (status) {
      case RemoteControlStatus.idle:
        return; // Don't announce idle
      case RemoteControlStatus.requestingPermission:
        message = 'Solicitando permiso de captura de pantalla';
        break;
      case RemoteControlStatus.creatingSession:
        message = 'Creando sesión remota';
        break;
      case RemoteControlStatus.waitingForClient:
        if (_currentSession != null) {
          // Announce session code digit by digit
          final code = _currentSession!.sessionCode;
          final digits = code.split('').join(', ');
          message = 'Sesión remota iniciada. Código: $digits. '
              'Comparte este código con tu familiar para que se conecte.';
        } else {
          message = 'Esperando conexión de tu familiar';
        }
        break;
      case RemoteControlStatus.connecting:
        return;
      case RemoteControlStatus.connected:
        message = 'Conectado. Tu familiar ahora puede ver tu pantalla y ayudarte.';
        break;
      case RemoteControlStatus.ended:
        message = 'Sesión remota terminada. Gracias por usar el servicio.';
        break;
      case RemoteControlStatus.error:
        message = 'Ocurrió un error. ${_errorMessage ?? "Intenta nuevamente"}';
        break;
    }

    // TTS is now handled via TTSFactory singleton, not through provider
      final ttsService = TTSFactory.getInstance();
      await ttsService.speak(message);
  }

  /// Sets an error message
  void _setError(String message) {
    _errorMessage = message;
    developer.log(
      'Error: $message',
      name: 'RemoteControlProvider',
    );
  }

  /// Cleans up all resources
  Future<void> _cleanup() async {
    try {
      developer.log(
        'Cleaning up resources',
        name: 'RemoteControlProvider',
      );

      // Cancel subscriptions
      await _sessionSubscription?.cancel();
      _sessionSubscription = null;

      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;

      // Dispose WebRTC (this will also stop screen capture via flutter_webrtc)
      await _webrtcService.dispose();

      // Stop foreground service
      try {
        await _foregroundService.stop();
        developer.log(
          'Foreground service stopped',
          name: 'RemoteControlProvider',
        );
      } catch (e) {
        developer.log(
          'Error stopping foreground service',
          name: 'RemoteControlProvider',
          error: e,
        );
        // Continue cleanup even if stopping service fails
      }

      // Clear session
      _currentSession = null;
      _connectionState = null;

      notifyListeners();
    } catch (e, stackTrace) {
      developer.log(
        'Error during cleanup',
        name: 'RemoteControlProvider',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    developer.log(
      'Disposing RemoteControlProvider',
      name: 'RemoteControlProvider',
    );

    _cleanup();
    TTSFactory.getInstance().stop();
    super.dispose();
  }
}

/// Status of the remote control session (for UI)
enum RemoteControlStatus {
  /// No session active
  idle,

  /// Requesting screen capture permission
  requestingPermission,

  /// Creating session in Firestore
  creatingSession,

  /// Waiting for client to connect
  waitingForClient,

  /// Establishing WebRTC connection
  connecting,

  /// WebRTC connection established
  connected,

  /// Session ended normally
  ended,

  /// Error occurred
  error,
}
