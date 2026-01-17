import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors/app_error.dart';
import '../errors/error_category.dart';
import '../errors/error_codes.dart';
import '../models/remote_session.dart';
import 'error_handler_service.dart';
import 'firebase_signaling_service.dart';

/// Service for managing WebRTC peer connections
///
/// Handles:
/// - RTCPeerConnection setup and configuration
/// - Screen capture video track creation
/// - ICE candidate exchange
/// - SDP offer/answer creation and exchange
/// - Connection state monitoring
class WebRTCService {
  final FirebaseSignalingService _signalingService;

  /// WebRTC peer connection instance
  RTCPeerConnection? _peerConnection;

  /// Local video stream (screen capture)
  MediaStream? _localStream;

  /// Data channel for receiving touch events from client
  RTCDataChannel? _controlDataChannel;

  /// Session code for the current connection
  String? _currentSessionCode;

  /// Stream controller for connection state changes
  late StreamController<RTCPeerConnectionState> _connectionStateController;

  /// Stream of connection state changes
  Stream<RTCPeerConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Current connection state
  RTCPeerConnectionState? _connectionState;

  RTCPeerConnectionState? get connectionState => _connectionState;

  /// Flag to track if answer from client has been processed
  bool _answerReceived = false;

  /// Platform channel for native Android functionality
  static const _platform =
      MethodChannel('com.accessibilityapp/foreground_service');

  WebRTCService({required FirebaseSignalingService signalingService})
      : _signalingService = signalingService {
    // Initialize the stream controller
    _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  }

  /// STUN server configuration (Google public STUN servers)
  ///
  /// STUN servers help establish P2P connections by discovering
  /// the public IP address of devices behind NAT
  static const Map<String, dynamic> _stunConfiguration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      }
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// Media constraints for screen capture
  ///
  /// Configures video quality (adaptative based on network)
  static const Map<String, dynamic> _mediaConstraints = {
    'audio': false, // No audio for now (v1.0)
    'video': {
      'mandatory': {
        'minWidth': '360', // Minimum resolution (slow network)
        'minHeight': '640',
        'minFrameRate': '15',
      },
      'optional': [
        {'maxWidth': '720'}, // Maximum resolution (good network)
        {'maxHeight': '1280'},
        {'maxFrameRate': '30'},
      ],
    }
  };

  /// Initializes WebRTC as host (screen sharing)
  ///
  /// Creates peer connection, adds screen capture track,
  /// and sets up event listeners.
  ///
  /// [sessionCode] The session code for signaling
  /// [context] BuildContext for error handling (optional)
  ///
  /// Throws [Exception] if initialization fails
  Future<void> initializeAsHost(
    String sessionCode, {
    BuildContext? context,
  }) async {
    try {
      _currentSessionCode = sessionCode;
      _answerReceived = false; // Reset flag for new session

      // Reset stream controller if it was previously closed
      if (_connectionStateController.isClosed) {
        _connectionStateController =
            StreamController<RTCPeerConnectionState>.broadcast();
      }

      // Create peer connection
      await _createPeerConnection();

      // Create and add local screen capture track
      await _createLocalScreenTrack();

      // Create data channel for touch control
      await _createDataChannel();

      // Setup signaling listeners (for answer and ICE candidates from client)
      _listenForSignaling(sessionCode);

      // Create and send offer
      await _createOffer();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to initialize WebRTC',
        name: 'WebRTCService',
        error: e,
        stackTrace: stackTrace,
      );

      // Show user-friendly error if context available
      if (context != null && context.mounted) {
        await ErrorHandlerService.handleError(
          context: context,
          error: AppError(
            category: ErrorCategory.webRTC,
            code: ErrorCodes.wrtcConnectionFailed,
            technicalMessage: e.toString(),
            userMessage: 'No pudimos iniciar la sesión remota.',
            canRetry: true,
            stackTrace: stackTrace,
          ),
          service: 'WebRTCService',
          canRetry: true,
          onRetry: () => initializeAsHost(sessionCode, context: context),
        );
      }

      await dispose();
      rethrow;
    }
  }

  /// Creates the RTCPeerConnection instance
  Future<void> _createPeerConnection() async {
    try {
      developer.log(
        'Creating peer connection',
        name: 'WebRTCService',
      );

      _peerConnection = await createPeerConnection(_stunConfiguration);

      // Setup event listeners
      _peerConnection!.onIceCandidate = _onIceCandidate;
      _peerConnection!.onIceConnectionState = _onIceConnectionStateChange;
      _peerConnection!.onConnectionState = _onConnectionStateChange;

      developer.log(
        'Peer connection created',
        name: 'WebRTCService',
      );
    } catch (e) {
      throw Exception('Failed to create peer connection: $e');
    }
  }

  /// Creates local screen capture video track
  ///
  /// Uses display media (screen capture) instead of camera
  Future<void> _createLocalScreenTrack() async {
    try {
      // Create screen capture stream
      // Note: On Android, this requires MediaProjection permission
      _localStream = await navigator.mediaDevices.getDisplayMedia(
        _mediaConstraints,
      );

      if (_localStream == null) {
        throw Exception('Failed to get display media stream');
      }

      // Add video track to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    } catch (e) {
      developer.log(
        'Failed to create screen track',
        name: 'WebRTCService',
        error: e,
      );
      throw Exception('Failed to create screen track: $e');
    }
  }

  /// Creates data channel for receiving touch control events from client
  Future<void> _createDataChannel() async {
    try {
      // Create data channel configuration
      final dataChannelInit = RTCDataChannelInit()
        ..id = 1
        ..ordered = true
        ..maxRetransmitTime = -1
        ..maxRetransmits = -1
        ..protocol = 'sctp'
        ..negotiated = false;

      _controlDataChannel = await _peerConnection!.createDataChannel(
        'control',
        dataChannelInit,
      );

      // Setup data channel event listeners
      _controlDataChannel!.onMessage = (RTCDataChannelMessage message) {
        _onDataChannelMessage(message);
      };

      developer.log(
        'Data channel created',
        name: 'WebRTCService',
      );
    } catch (e) {
      // Don't throw - data channel is optional feature
      developer.log(
        'Failed to create data channel (non-critical)',
        name: 'WebRTCService',
        error: e,
      );
    }
  }

  /// Handles incoming messages on data channel
  void _onDataChannelMessage(RTCDataChannelMessage message) {
    try {
      final data = json.decode(message.text);

      if (data['type'] == 'tap') {
        final x = data['x'] as double;
        final y = data['y'] as double;

        _handleRemoteTap(x, y);
      }
    } catch (e) {
      developer.log(
        'Failed to handle data channel message',
        name: 'WebRTCService',
        error: e,
      );
    }
  }

  /// Obtains the actual screen dimensions from Android DisplayMetrics
  ///
  /// Returns a map with 'width' and 'height' keys in pixels.
  /// Falls back to 1080x2340 if Platform Channel fails.
  Future<Map<String, int>> _getScreenDimensions() async {
    try {
      final result = await _platform.invokeMethod('getScreenDimensions');
      return {
        'width': result['width'] as int,
        'height': result['height'] as int,
      };
    } on PlatformException catch (e) {
      developer.log(
        'Failed to get screen dimensions, using defaults',
        name: 'WebRTCService',
        error: e,
      );
      // Fallback to common Android resolution
      return {'width': 1080, 'height': 2340};
    } catch (e) {
      developer.log(
        'Unexpected error getting screen dimensions, using defaults',
        name: 'WebRTCService',
        error: e,
      );
      // Fallback to common Android resolution
      return {'width': 1080, 'height': 2340};
    }
  }

  /// Handles remote tap event from client
  ///
  /// Converts normalized coordinates to pixel coordinates and
  /// simulates tap via AccessibilityService
  Future<void> _handleRemoteTap(double normalizedX, double normalizedY) async {
    try {
      // Get actual screen dimensions from Android
      final dimensions = await _getScreenDimensions();
      final screenWidth = dimensions['width']!.toDouble();
      final screenHeight = dimensions['height']!.toDouble();

      // Convert normalized coordinates to pixel coordinates
      final pixelX = (normalizedX * screenWidth).toInt();
      final pixelY = (normalizedY * screenHeight).toInt();

      developer.log(
        'Remote tap: normalized($normalizedX, $normalizedY) -> pixels($pixelX, $pixelY) on ${screenWidth.toInt()}x${screenHeight.toInt()}',
        name: 'WebRTCService',
      );

      // Call Platform Channel to simulate tap
      await _simulateTap(pixelX.toDouble(), pixelY.toDouble());
    } catch (e) {
      developer.log(
        'Failed to handle remote tap',
        name: 'WebRTCService',
        error: e,
      );
    }
  }

  /// Simulates a tap at the given pixel coordinates via Platform Channel
  ///
  /// Calls the native Android MainActivity to perform the tap using
  /// AccessibilityService
  ///
  /// Throws [AppError] if:
  /// - Accessibility service is not enabled (PERMISSION_DENIED)
  /// - Tap simulation fails (TAP_SIMULATION_FAILED)
  Future<void> _simulateTap(double x, double y) async {
    try {
      await _platform.invokeMethod('simulateTap', {
        'x': x,
        'y': y,
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        throw AppError(
          category: ErrorCategory.platformChannel,
          code: ErrorCodes.pcPermissionDenied,
          technicalMessage: e.message ?? 'Accessibility service not enabled',
          userMessage:
              'El servicio de accesibilidad no está habilitado. Por favor, habilítalo en la configuración.',
          canRetry: false, // Requires manual action
          stackTrace: StackTrace.current,
        );
      }
      throw AppError(
        category: ErrorCategory.platformChannel,
        code: ErrorCodes.pcNativeException,
        technicalMessage: e.message ?? 'Failed to simulate tap',
        userMessage: 'No se pudo realizar el toque remoto.',
        canRetry: true,
        stackTrace: StackTrace.current,
      );
    } catch (e) {
      developer.log(
        'Unexpected error simulating tap',
        name: 'WebRTCService',
        error: e,
      );
      throw AppError(
        category: ErrorCategory.platformChannel,
        code: ErrorCodes.unknownError,
        technicalMessage: e.toString(),
        userMessage: 'Error inesperado al simular el toque.',
        canRetry: true,
        stackTrace: StackTrace.current,
      );
    }
  }

  /// Creates SDP offer and sends it via signaling
  Future<void> _createOffer() async {
    try {
      // Create offer
      final RTCSessionDescription offer =
          await _peerConnection!.createOffer();

      // Set as local description
      await _peerConnection!.setLocalDescription(offer);

      // Send offer via signaling service
      await _signalingService.setOffer(
        _currentSessionCode!,
        offer.sdp!,
      );
    } catch (e) {
      developer.log(
        'Failed to create offer',
        name: 'WebRTCService',
        error: e,
      );
      throw Exception('Failed to create offer: $e');
    }
  }

  /// Listens for signaling messages (answer and ICE candidates from client)
  void _listenForSignaling(String sessionCode) {
    developer.log(
      'Listening for signaling messages',
      name: 'WebRTCService',
    );

    _signalingService.watchSession(sessionCode).listen((session) {
      if (session == null) {
        developer.log(
          'Session ended or expired',
          name: 'WebRTCService',
        );
        return;
      }

      // Handle answer from client
      if (session.answerSdp != null && _peerConnection != null) {
        _handleAnswer(session.answerSdp!);
      }

      // Handle ICE candidates from client
      if (session.clientIceCandidates != null) {
        _handleRemoteIceCandidates(session.clientIceCandidates!);
      }
    });
  }

  /// Handles SDP answer from client
  Future<void> _handleAnswer(String sdp) async {
    try {
      // Only process answer once
      if (_answerReceived) {
        return;
      }

      final RTCSessionDescription answer = RTCSessionDescription(
        sdp,
        'answer',
      );

      await _peerConnection!.setRemoteDescription(answer);

      // Mark answer as received
      _answerReceived = true;

      developer.log(
        'Remote description (answer) set',
        name: 'WebRTCService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to handle answer',
        name: 'WebRTCService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handles ICE candidates from client
  Future<void> _handleRemoteIceCandidates(
    List<Map<String, dynamic>> candidates,
  ) async {
    for (final candidateMap in candidates) {
      try {
        final RTCIceCandidate candidate = RTCIceCandidate(
          candidateMap['candidate'] as String,
          candidateMap['sdpMid'] as String,
          candidateMap['sdpMLineIndex'] as int,
        );

        await _peerConnection!.addCandidate(candidate);

        developer.log(
          'Added remote ICE candidate',
          name: 'WebRTCService',
        );
      } catch (e) {
        developer.log(
          'Failed to add remote ICE candidate',
          name: 'WebRTCService',
          error: e,
        );
        // Don't throw - some candidates may fail, connection may still work
      }
    }
  }

  /// Event handler for ICE candidate events
  void _onIceCandidate(RTCIceCandidate candidate) {
    developer.log(
      'ICE candidate generated: ${candidate.candidate}',
      name: 'WebRTCService',
    );

    // Send ICE candidate to client via signaling
    if (_currentSessionCode != null) {
      _signalingService.addIceCandidate(
        _currentSessionCode!,
        {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
        isHost: true,
      );
    }
  }

  /// Event handler for ICE connection state changes
  void _onIceConnectionStateChange(RTCIceConnectionState state) {
    developer.log(
      'ICE connection state: $state',
      name: 'WebRTCService',
    );

    // Update session status in Firestore based on ICE state
    if (_currentSessionCode != null) {
      RemoteSessionStatus? sessionStatus;

      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          sessionStatus = RemoteSessionStatus.connected;
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
        case RTCIceConnectionState.RTCIceConnectionStateClosed:
          sessionStatus = RemoteSessionStatus.failed;
          break;
        default:
          break;
      }

      if (sessionStatus != null) {
        _signalingService.updateSessionStatus(
          _currentSessionCode!,
          sessionStatus,
        );
      }
    }
  }

  /// Event handler for peer connection state changes
  void _onConnectionStateChange(RTCPeerConnectionState state) {
    developer.log(
      'Peer connection state: $state',
      name: 'WebRTCService',
    );

    _connectionState = state;
    
    // Prevent adding events to a closed stream controller
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }

    // Update session status in Firestore
    if (_currentSessionCode != null) {
      RemoteSessionStatus? sessionStatus;

      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          sessionStatus = RemoteSessionStatus.connected;
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          sessionStatus = RemoteSessionStatus.failed;
          break;
        default:
          break;
      }

      if (sessionStatus != null) {
        _signalingService.updateSessionStatus(
          _currentSessionCode!,
          sessionStatus,
        );
      }
    }
  }

  /// Closes the WebRTC connection and cleans up resources
  Future<void> dispose() async {
    try {
      developer.log(
        'Disposing WebRTC service',
        name: 'WebRTCService',
      );

      // Close data channel
      _controlDataChannel?.close();
      _controlDataChannel = null;

      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;

      // Dispose local stream
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      await _localStream?.dispose();
      _localStream = null;

      // Clear session code
      _currentSessionCode = null;

      // Reset answer flag
      _answerReceived = false;

      // Close stream controller
      await _connectionStateController.close();

      developer.log(
        'WebRTC service disposed',
        name: 'WebRTCService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error disposing WebRTC service',
        name: 'WebRTCService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
