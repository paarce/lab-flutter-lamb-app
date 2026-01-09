import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/remote_session.dart';
import '../services/elevenlabs_service.dart';
import '../services/firebase_signaling_service.dart';
import '../services/foreground_service.dart';
import '../services/webrtc_service.dart';

/// State management provider for remote control sessions
///
/// Orchestrates:
/// - FirebaseSignalingService (session management & signaling)
/// - WebRTCService (peer connection & MediaProjection via flutter_webrtc)
/// - ElevenLabsService (TTS announcements)
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
  final ElevenLabsService _ttsService;
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

  /// Stream subscription for session updates
  StreamSubscription<RemoteSession?>? _sessionSubscription;

  /// Stream subscription for connection state updates
  StreamSubscription<RTCPeerConnectionState>? _connectionStateSubscription;

  RemoteControlProvider({
    required FirebaseSignalingService signalingService,
    required ElevenLabsService ttsService,
  })  : _signalingService = signalingService,
        _ttsService = ttsService {
    // Initialize WebRTC service
    _webrtcService = WebRTCService(signalingService: _signalingService);

    // Initialize foreground service (required for Android 14+ MediaProjection)
    _foregroundService = ForegroundService();

    // Initialize TTS service
    _ttsService.initialize();
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
      print('🔵 [RemoteControlProvider] STEP 0: Starting remote control session');

      // Clear previous errors
      _errorMessage = null;

      _setStatus(RemoteControlStatus.creatingSession);

      // Step 1: Create session in Firestore
      print('🔵 [RemoteControlProvider] STEP 1: Creating session in Firestore...');
      _currentSession = await _signalingService.createSession();
      print('🔵 [RemoteControlProvider] STEP 1: Session created: ${_currentSession?.sessionCode}');

      if (_currentSession == null) {
        print('🔴 [RemoteControlProvider] STEP 1: Session is null');
        _setError('No se pudo crear la sesión remota. Intenta de nuevo.');
        _setStatus(RemoteControlStatus.error);
        return null;
      }

      _setStatus(RemoteControlStatus.requestingPermission);

      // Step 2: Start foreground service (REQUIRED for Android 14+)
      // Must be started BEFORE MediaProjection is requested
      print('🔵 [RemoteControlProvider] STEP 2a: Starting foreground service (Android 14+ requirement)');
      try {
        await _foregroundService.start();
        print('🔵 [RemoteControlProvider] STEP 2a: Foreground service started');
      } catch (e) {
        print('🔴 [RemoteControlProvider] STEP 2a: Failed to start foreground service: $e');
        throw Exception(
          'No se pudo iniciar el servicio de captura de pantalla. '
          'Por favor, verifica los permisos de la aplicación.'
        );
      }

      // Step 2b: Initialize WebRTC
      // This will trigger MediaProjection permission dialog via flutter_webrtc
      print('🔵 [RemoteControlProvider] STEP 2b: Initializing WebRTC for session: ${_currentSession!.sessionCode}');
      print('⚠️  [RemoteControlProvider] NOTE: flutter_webrtc will request MediaProjection permission now');
      await _webrtcService.initializeAsHost(_currentSession!.sessionCode);
      print('🔵 [RemoteControlProvider] STEP 2b: WebRTC initialized');

      _setStatus(RemoteControlStatus.waitingForClient);

      // Step 3: Listen for session updates (client connection)
      print('🔵 [RemoteControlProvider] STEP 3: Setting up session listeners');
      _listenToSessionUpdates();

      // Step 4: Listen for WebRTC connection state changes
      print('🔵 [RemoteControlProvider] STEP 4: Setting up connection state listeners');
      _listenToConnectionState();

      print('✅ [RemoteControlProvider] SUCCESS: Remote session started: ${_currentSession!.sessionCode}');

      notifyListeners();
      return _currentSession!.sessionCode;
    } on Exception catch (e) {
      print('🔴 [RemoteControlProvider] EXCEPTION caught: $e');

      // Parse user-friendly error messages from exceptions
      String errorMessage = e.toString();

      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      print('🔴 [RemoteControlProvider] Error message: $errorMessage');

      _setError(errorMessage);
      _setStatus(RemoteControlStatus.error);

      // Cleanup on error
      print('🔴 [RemoteControlProvider] Running cleanup...');
      await _cleanup();
      print('🔴 [RemoteControlProvider] Cleanup completed');

      return null;
    } catch (e, stackTrace) {
      print('🔴 [RemoteControlProvider] UNEXPECTED ERROR caught: $e');
      print('🔴 [RemoteControlProvider] Stack trace: $stackTrace');

      // TODO: Implement centralized error reporting service in FUNCIONALIDAD 2.1
      // This should log errors to Firebase Crashlytics or similar service
      // for monitoring production issues.

      _setError(
        'Error inesperado al iniciar la sesión. '
        'Por favor, cierra y vuelve a abrir la aplicación.',
      );
      _setStatus(RemoteControlStatus.error);

      // Cleanup on error
      print('🔴 [RemoteControlProvider] Running cleanup after unexpected error...');
      await _cleanup();
      print('🔴 [RemoteControlProvider] Cleanup completed');

      return null;
    }
  }

  /// Ends the current remote control session
  Future<void> endRemoteSession() async {
    try {
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
        // Session ended or expired
        developer.log(
          'Session ended or expired',
          name: 'RemoteControlProvider',
        );
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
          _setStatus(RemoteControlStatus.ended);
          _cleanup();
          break;
        case RemoteSessionStatus.failed:
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
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _setStatus(RemoteControlStatus.error);
          _setError('Conexión WebRTC fallida');
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
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

    // Announce status change via TTS
    _announceStatus(status);

    notifyListeners();
  }

  /// Announces status changes via TTS
  void _announceStatus(RemoteControlStatus status) {
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
        message = 'Tu familiar se está conectando';
        break;
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

    _ttsService.speak(message);
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
    _ttsService.dispose();
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
