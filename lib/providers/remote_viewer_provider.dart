import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors/app_error.dart';
import '../errors/error_category.dart';
import '../errors/error_codes.dart';
import '../models/remote_session.dart';
import '../services/firebase_signaling_service.dart';
import '../services/webrtc_client_service.dart';

/// State management provider for remote viewing sessions (CLIENT side)
///
/// Orchestrates:
/// - WebRTCClientService (peer connection & receiving video stream)
/// - FirebaseSignalingService (session management & signaling)
///
/// Exposes simple API for UI:
/// - connectToSession(sessionCode)
/// - sendTouch(x, y)
/// - disconnect()
/// - status, remoteStream, errorMessage
class RemoteViewerProvider extends ChangeNotifier {
  final FirebaseSignalingService _signalingService;
  late final WebRTCClientService _webrtcService;

  /// Current session code
  String? _sessionCode;

  String? get sessionCode => _sessionCode;

  /// Viewer status
  RemoteViewerStatus _status = RemoteViewerStatus.disconnected;

  RemoteViewerStatus get status => _status;

  /// Remote video stream from host
  MediaStream? _remoteStream;

  MediaStream? get remoteStream => _remoteStream;

  /// WebRTC connection state
  RTCPeerConnectionState? _connectionState;

  RTCPeerConnectionState? get connectionState => _connectionState;

  /// Error message (if any)
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  /// Last error that occurred (for detailed error handling)
  AppError? _lastError;

  AppError? get lastError => _lastError;

  /// Clears the last error
  void clearError() {
    _lastError = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Stream subscription for remote stream updates
  StreamSubscription<MediaStream>? _streamSubscription;

  /// Stream subscription for connection state updates
  StreamSubscription<RTCPeerConnectionState>? _connectionStateSubscription;

  /// Stream subscription for session updates
  StreamSubscription<RemoteSession?>? _sessionSubscription;

  RemoteViewerProvider({
    required FirebaseSignalingService signalingService,
  }) : _signalingService = signalingService {
    // Initialize WebRTC client service
    _webrtcService = WebRTCClientService(signalingService: _signalingService);
  }

  /// Connects to a remote session using session code
  ///
  /// Steps:
  /// 1. Validate session code format
  /// 2. Join session via WebRTCClientService
  /// 3. Setup listeners for stream and connection state
  ///
  /// Returns true if successful, false otherwise
  Future<bool> connectToSession(String sessionCode) async {
    try {
      // Clear previous errors
      _errorMessage = null;

      // Validate session code format
      if (sessionCode.length != 6) {
        throw Exception('El código debe tener 6 dígitos');
      }

      if (!RegExp(r'^[2-9]+$').hasMatch(sessionCode)) {
        throw Exception('El código solo puede contener dígitos del 2 al 9');
      }

      _sessionCode = sessionCode;
      _setStatus(RemoteViewerStatus.connecting);

      // Join session via WebRTC service
      await _webrtcService.joinSession(sessionCode);

      // Check if stream is already available (may have been set during joinSession)
      if (_webrtcService.currentRemoteStream != null) {
        _remoteStream = _webrtcService.currentRemoteStream;
        notifyListeners();
      }

      // Listen for remote stream updates
      _streamSubscription =
          _webrtcService.remoteStreamStream.listen((stream) {
        _remoteStream = stream;
        notifyListeners();
      });

      // Listen for connection state changes
      _connectionStateSubscription =
          _webrtcService.connectionStateStream.listen((state) {
        _connectionState = state;

        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
            _setStatus(RemoteViewerStatus.connecting);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _setStatus(RemoteViewerStatus.connected);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            _lastError = AppError(
              category: ErrorCategory.webRTC,
              code: ErrorCodes.wrtcConnectionFailed,
              technicalMessage: 'Peer connection state failed',
              userMessage: 'Conexión WebRTC fallida',
              canRetry: true,
            );
            _setStatus(RemoteViewerStatus.failed);
            _setError('Conexión WebRTC fallida');
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
            _setStatus(RemoteViewerStatus.disconnected);
            break;
          default:
            break;
        }

        notifyListeners();
      });

      // Listen for session updates (e.g., host disconnect)
      _listenToSessionUpdates();

      notifyListeners();
      return true;
    } on Exception catch (e) {
      // Parse user-friendly error messages from exceptions
      String errorMessage = e.toString();

      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      // Create AppError instance for detailed error handling
      _lastError = AppError(
        category: ErrorCategory.webRTC,
        code: ErrorCodes.wrtcConnectionFailed,
        technicalMessage: e.toString(),
        userMessage: errorMessage,
        canRetry: true,
      );

      _setError(errorMessage);
      _setStatus(RemoteViewerStatus.failed);

      // Cleanup on error
      await _cleanup();

      return false;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error connecting to session',
        name: 'RemoteViewerProvider',
        error: e,
        stackTrace: stackTrace,
      );

      // Create AppError instance for detailed error handling
      _lastError = AppError(
        category: ErrorCategory.unknown,
        code: ErrorCodes.unknownError,
        technicalMessage: e.toString(),
        userMessage: 'Error inesperado al conectar. Por favor, intenta de nuevo.',
        canRetry: true,
        stackTrace: stackTrace,
      );

      _setError(
        'Error inesperado al conectar. Por favor, intenta de nuevo.',
      );
      _setStatus(RemoteViewerStatus.failed);

      // Cleanup on error
      await _cleanup();

      return false;
    }
  }

  /// Sends touch event to host
  ///
  /// [normalizedX] X coordinate normalized to 0.0-1.0
  /// [normalizedY] Y coordinate normalized to 0.0-1.0
  Future<void> sendTouch(double normalizedX, double normalizedY) async {
    try {
      await _webrtcService.sendTouchEvent(normalizedX, normalizedY);
    } catch (e) {
      developer.log(
        'Failed to send touch',
        name: 'RemoteViewerProvider',
        error: e,
      );
    }
  }

  /// Disconnects from the current session
  Future<void> disconnect() async {
    try {
      _setStatus(RemoteViewerStatus.disconnected);

      // Cleanup resources
      await _cleanup();

      developer.log(
        'Disconnected from remote session',
        name: 'RemoteViewerProvider',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error disconnecting from remote session',
        name: 'RemoteViewerProvider',
        error: e,
        stackTrace: stackTrace,
      );

      // Cleanup anyway
      await _cleanup();
    }
  }

  /// Listens for session updates from Firestore
  void _listenToSessionUpdates() {
    if (_sessionCode == null) return;

    _sessionSubscription?.cancel();

    _sessionSubscription = _signalingService
        .watchSession(_sessionCode!)
        .listen((session) {
      if (session == null) {
        // Session ended or expired
        developer.log(
          'Session ended or expired',
          name: 'RemoteViewerProvider',
        );

        _lastError = AppError(
          category: ErrorCategory.webRTC,
          code: ErrorCodes.wrtcSessionExpired,
          technicalMessage: 'Session document no longer exists in Firestore',
          userMessage: 'La sesión ha terminado',
          canRetry: false,
        );
        _setStatus(RemoteViewerStatus.disconnected);
        _setError('La sesión ha terminado');
        _cleanup();
        return;
      }

      // Update status based on session status
      switch (session.status) {
        case RemoteSessionStatus.waiting:
          // Host is waiting for client (shouldn't happen after we connect)
          break;
        case RemoteSessionStatus.connecting:
          _setStatus(RemoteViewerStatus.connecting);
          break;
        case RemoteSessionStatus.connected:
          _setStatus(RemoteViewerStatus.connected);
          break;
        case RemoteSessionStatus.ended:
          _lastError = AppError(
            category: ErrorCategory.webRTC,
            code: ErrorCodes.wrtcSessionExpired,
            technicalMessage: 'Host ended the session',
            userMessage: 'El host terminó la sesión',
            canRetry: false,
          );
          _setStatus(RemoteViewerStatus.disconnected);
          _setError('El host terminó la sesión');
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
          _setStatus(RemoteViewerStatus.failed);
          _setError('Conexión fallida');
          _cleanup();
          break;
      }

      notifyListeners();
    });
  }

  /// Sets the current status
  void _setStatus(RemoteViewerStatus status) {
    _status = status;
    notifyListeners();
  }

  /// Sets an error message
  void _setError(String message) {
    _errorMessage = message;
  }

  /// Cleans up all resources
  Future<void> _cleanup() async {
    try {
      // Cancel subscriptions
      await _streamSubscription?.cancel();
      _streamSubscription = null;

      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription = null;

      await _sessionSubscription?.cancel();
      _sessionSubscription = null;

      // Dispose WebRTC service
      await _webrtcService.dispose();

      // Clear state
      _sessionCode = null;
      _remoteStream = null;
      _connectionState = null;

      notifyListeners();
    } catch (e, stackTrace) {
      developer.log(
        'Error during cleanup',
        name: 'RemoteViewerProvider',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

/// Status of the remote viewer (for UI)
enum RemoteViewerStatus {
  /// Not connected to any session
  disconnected,

  /// Attempting to connect to session
  connecting,

  /// Connected and receiving video stream
  connected,

  /// Connection failed
  failed,
}
