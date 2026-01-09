import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
      print('🔵 [RemoteViewer] connectToSession: Starting connection to $sessionCode');

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
      print('🔵 [RemoteViewer] connectToSession: Joining WebRTC session...');
      await _webrtcService.joinSession(sessionCode);
      print('🔵 [RemoteViewer] connectToSession: WebRTC session joined');

      // Listen for remote stream
      print('🔵 [RemoteViewer] connectToSession: Setting up stream listener...');
      _streamSubscription =
          _webrtcService.remoteStreamStream.listen((stream) {
        print('🔵 [RemoteViewer] Remote stream received: ${stream.id}');
        _remoteStream = stream;
        notifyListeners();
      });

      // Listen for connection state changes
      print('🔵 [RemoteViewer] connectToSession: Setting up connection state listener...');
      _connectionStateSubscription =
          _webrtcService.connectionStateStream.listen((state) {
        print('🔵 [RemoteViewer] Connection state changed: $state');
        _connectionState = state;

        switch (state) {
          case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
            _setStatus(RemoteViewerStatus.connecting);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
            _setStatus(RemoteViewerStatus.connected);
            break;
          case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
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
      print('🔵 [RemoteViewer] connectToSession: Setting up session listener...');
      _listenToSessionUpdates();

      print('✅ [RemoteViewer] connectToSession: Connection setup complete');

      notifyListeners();
      return true;
    } on Exception catch (e) {
      print('🔴 [RemoteViewer] connectToSession: Exception caught: $e');

      // Parse user-friendly error messages from exceptions
      String errorMessage = e.toString();

      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      print('🔴 [RemoteViewer] connectToSession: Error message: $errorMessage');

      _setError(errorMessage);
      _setStatus(RemoteViewerStatus.failed);

      // Cleanup on error
      print('🔴 [RemoteViewer] connectToSession: Running cleanup...');
      await _cleanup();
      print('🔴 [RemoteViewer] connectToSession: Cleanup completed');

      return false;
    } catch (e, stackTrace) {
      print('🔴 [RemoteViewer] connectToSession: Unexpected error caught: $e');
      print('🔴 [RemoteViewer] connectToSession: Stack trace: $stackTrace');

      _setError(
        'Error inesperado al conectar. Por favor, intenta de nuevo.',
      );
      _setStatus(RemoteViewerStatus.failed);

      // Cleanup on error
      print('🔴 [RemoteViewer] connectToSession: Running cleanup after unexpected error...');
      await _cleanup();
      print('🔴 [RemoteViewer] connectToSession: Cleanup completed');

      return false;
    }
  }

  /// Sends touch event to host
  ///
  /// [normalizedX] X coordinate normalized to 0.0-1.0
  /// [normalizedY] Y coordinate normalized to 0.0-1.0
  Future<void> sendTouch(double normalizedX, double normalizedY) async {
    try {
      print('🔵 [RemoteViewer] sendTouch: Sending touch at ($normalizedX, $normalizedY)');

      await _webrtcService.sendTouchEvent(normalizedX, normalizedY);

      developer.log(
        'Touch sent: ($normalizedX, $normalizedY)',
        name: 'RemoteViewerProvider',
      );
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
      print('🔵 [RemoteViewer] disconnect: Disconnecting from session...');

      developer.log(
        'Disconnecting from remote session',
        name: 'RemoteViewerProvider',
      );

      _setStatus(RemoteViewerStatus.disconnected);

      // Cleanup resources
      await _cleanup();

      print('✅ [RemoteViewer] disconnect: Disconnected successfully');

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
        print('🔴 [RemoteViewer] Session ended or expired');

        developer.log(
          'Session ended or expired',
          name: 'RemoteViewerProvider',
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
          _setStatus(RemoteViewerStatus.disconnected);
          _setError('El host terminó la sesión');
          _cleanup();
          break;
        case RemoteSessionStatus.failed:
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

    print('🔵 [RemoteViewer] Status changed: $status');

    developer.log(
      'Status changed: $status',
      name: 'RemoteViewerProvider',
    );

    notifyListeners();
  }

  /// Sets an error message
  void _setError(String message) {
    _errorMessage = message;

    print('🔴 [RemoteViewer] Error: $message');

    developer.log(
      'Error: $message',
      name: 'RemoteViewerProvider',
    );
  }

  /// Cleans up all resources
  Future<void> _cleanup() async {
    try {
      print('🔵 [RemoteViewer] _cleanup: Cleaning up resources...');

      developer.log(
        'Cleaning up resources',
        name: 'RemoteViewerProvider',
      );

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

      print('✅ [RemoteViewer] _cleanup: Resources cleaned up');

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
    print('🔵 [RemoteViewer] dispose: Disposing provider...');

    developer.log(
      'Disposing RemoteViewerProvider',
      name: 'RemoteViewerProvider',
    );

    _cleanup();
    super.dispose();

    print('✅ [RemoteViewer] dispose: Provider disposed');
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
