import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../errors/app_error.dart';
import '../errors/error_category.dart';
import '../errors/error_codes.dart';
import '../models/remote_session.dart';
import 'error_handler_service.dart';
import 'firebase_signaling_service.dart';

/// Service for managing WebRTC peer connections (CLIENT side)
///
/// Handles:
/// - RTCPeerConnection setup and configuration
/// - Receiving remote video stream from host
/// - ICE candidate exchange
/// - SDP offer/answer exchange (client creates answer)
/// - Connection state monitoring
/// - Data channel for touch control
class WebRTCClientService {
  final FirebaseSignalingService _signalingService;

  /// WebRTC peer connection instance
  RTCPeerConnection? _peerConnection;

  /// Remote video stream (from host)
  MediaStream? _remoteStream;

  /// Data channel for sending touch events to host
  RTCDataChannel? _dataChannel;

  /// Session code for the current connection
  String? _currentSessionCode;

  /// Stream controller for remote stream updates
  final _remoteStreamController = StreamController<MediaStream>.broadcast();

  /// Stream of remote stream updates
  Stream<MediaStream> get remoteStreamStream =>
      _remoteStreamController.stream;

  /// Current remote stream (if available)
  /// Use this to get the stream immediately if it's already set
  MediaStream? get currentRemoteStream => _remoteStream;

  /// Stream controller for connection state changes
  final _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();

  /// Stream of connection state changes
  Stream<RTCPeerConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Current connection state
  RTCPeerConnectionState? _connectionState;

  RTCPeerConnectionState? get connectionState => _connectionState;

  /// Subscription for session updates
  StreamSubscription<RemoteSession?>? _sessionSubscription;

  /// Set to track which ICE candidates have been processed
  final Set<String> _processedCandidates = {};

  WebRTCClientService({required FirebaseSignalingService signalingService})
      : _signalingService = signalingService;

  /// STUN server configuration (same as host)
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

  /// Joins an existing remote session as client
  ///
  /// [sessionCode] The 6-digit session code from host
  /// [context] BuildContext for error handling (optional)
  ///
  /// Throws [Exception] if session not found or connection fails
  Future<void> joinSession(
    String sessionCode, {
    BuildContext? context,
  }) async {
    try {
      _currentSessionCode = sessionCode;

      // Fetch session from Firestore
      final session = await _signalingService.getSession(sessionCode);

      if (session == null) {
        throw AppError(
          category: ErrorCategory.webRTC,
          code: ErrorCodes.wrtcPeerNotFound,
          technicalMessage: 'Session $sessionCode not found in Firestore',
          userMessage: 'Código de sesión no encontrado o expirado',
          canRetry: false,
        );
      }

      if (session.status == RemoteSessionStatus.ended) {
        throw AppError(
          category: ErrorCategory.webRTC,
          code: ErrorCodes.wrtcConnectionFailed,
          technicalMessage: 'Session $sessionCode has ended',
          userMessage: 'La sesión ha terminado',
          canRetry: false,
        );
      }

      if (session.offerSdp == null) {
        throw AppError(
          category: ErrorCategory.webRTC,
          code: ErrorCodes.wrtcConnectionFailed,
          technicalMessage: 'Session $sessionCode has no offer SDP yet',
          userMessage:
              'La sesión aún no tiene oferta. Por favor, espera unos segundos e intenta de nuevo.',
          canRetry: true,
        );
      }

      // Create peer connection
      await _createPeerConnection();

      // Set remote description (offer from host)
      await _setRemoteOffer(session.offerSdp!);

      // Create and send answer
      await _createAnswer();

      // Add host's ICE candidates (if any)
      if (session.hostIceCandidates != null &&
          session.hostIceCandidates!.isNotEmpty) {
        await _addHostIceCandidates(session.hostIceCandidates!);
      }

      // Listen for new host ICE candidates
      _listenForSignaling(sessionCode);
    } catch (e, stackTrace) {
      developer.log(
        'Failed to join session',
        name: 'WebRTCClient',
        error: e,
        stackTrace: stackTrace,
      );

      // Show user-friendly error if context available
      if (context != null && context.mounted) {
        await ErrorHandlerService.handleError(
          context: context,
          error: e is AppError
              ? e
              : AppError(
                  category: ErrorCategory.webRTC,
                  code: ErrorCodes.wrtcConnectionFailed,
                  technicalMessage: e.toString(),
                  userMessage: 'No pudimos conectar con la sesión remota.',
                  canRetry: true,
                  stackTrace: stackTrace,
                ),
          service: 'WebRTCClientService',
          canRetry: e is AppError ? e.canRetry : true,
          onRetry: () => joinSession(sessionCode, context: context),
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
        name: 'WebRTCClient',
      );

      _peerConnection = await createPeerConnection(_stunConfiguration);

      // Setup event listeners
      _peerConnection!.onIceCandidate = _onIceCandidate;
      _peerConnection!.onIceConnectionState = _onIceConnectionStateChange;
      _peerConnection!.onConnectionState = _onConnectionStateChange;
      _peerConnection!.onTrack = _onTrack; // Important: receive remote stream
      _peerConnection!.onDataChannel = _onDataChannel; // Receive data channel from host

      developer.log(
        'Peer connection created',
        name: 'WebRTCClient',
      );
    } catch (e) {
      throw Exception('Failed to create peer connection: $e');
    }
  }

  /// Sets the remote offer from host
  Future<void> _setRemoteOffer(String sdp) async {
    try {
      final RTCSessionDescription offer = RTCSessionDescription(
        sdp,
        'offer',
      );

      await _peerConnection!.setRemoteDescription(offer);

      developer.log(
        'Remote offer set',
        name: 'WebRTCClient',
      );
    } catch (e) {
      developer.log(
        'Failed to set remote offer',
        name: 'WebRTCClient',
        error: e,
      );
      throw Exception('Failed to set remote offer: $e');
    }
  }

  /// Creates SDP answer and sends it via signaling
  Future<void> _createAnswer() async {
    try {
      // Create answer
      final RTCSessionDescription answer =
          await _peerConnection!.createAnswer();

      // Set as local description
      await _peerConnection!.setLocalDescription(answer);

      // Send answer via signaling service
      await _signalingService.setAnswer(
        _currentSessionCode!,
        answer.sdp!,
      );

      developer.log(
        'Answer created and sent',
        name: 'WebRTCClient',
      );
    } catch (e) {
      developer.log(
        'Failed to create answer',
        name: 'WebRTCClient',
        error: e,
      );
      throw Exception('Failed to create answer: $e');
    }
  }

  /// Adds ICE candidates from host
  Future<void> _addHostIceCandidates(
    List<Map<String, dynamic>> candidates,
  ) async {
    for (final candidateMap in candidates) {
      try {
        final candidateString = candidateMap['candidate'] as String;

        // Skip if already processed
        if (_processedCandidates.contains(candidateString)) {
          continue;
        }

        final RTCIceCandidate candidate = RTCIceCandidate(
          candidateString,
          candidateMap['sdpMid'] as String,
          candidateMap['sdpMLineIndex'] as int,
        );

        await _peerConnection!.addCandidate(candidate);
        _processedCandidates.add(candidateString);

        developer.log(
          'Added host ICE candidate',
          name: 'WebRTCClient',
        );
      } catch (e) {
        developer.log(
          'Failed to add host ICE candidate',
          name: 'WebRTCClient',
          error: e,
        );
        // Don't throw - some candidates may fail, connection may still work
      }
    }
  }

  /// Listens for signaling messages (new ICE candidates from host)
  void _listenForSignaling(String sessionCode) {
    developer.log(
      'Listening for signaling messages',
      name: 'WebRTCClient',
    );

    _sessionSubscription =
        _signalingService.watchSession(sessionCode).listen((session) {
      if (session == null) {
        developer.log(
          'Session ended or expired',
          name: 'WebRTCClient',
        );
        return;
      }

      // Handle new ICE candidates from host
      if (session.hostIceCandidates != null) {
        _addHostIceCandidates(session.hostIceCandidates!);
      }
    });
  }

  /// Event handler for receiving remote track (video stream from host)
  void _onTrack(RTCTrackEvent event) {
    developer.log(
      'Track received: ${event.track.kind}',
      name: 'WebRTCClient',
    );

    if (event.track.kind == 'video' && event.streams.isNotEmpty) {
      _remoteStream = event.streams.first;

      // Only add to controller if not closed
      if (!_remoteStreamController.isClosed) {
        _remoteStreamController.add(_remoteStream!);
      }

      developer.log(
        'Remote stream set: ${_remoteStream!.id}',
        name: 'WebRTCClient',
      );
    }
  }

  /// Event handler for receiving data channel from host
  void _onDataChannel(RTCDataChannel channel) {
    developer.log(
      'Data channel received: ${channel.label}',
      name: 'WebRTCClient',
    );

    if (channel.label == 'control') {
      _dataChannel = channel;
    }
  }

  /// Event handler for ICE candidate events
  void _onIceCandidate(RTCIceCandidate candidate) {
    developer.log(
      'ICE candidate generated: ${candidate.candidate}',
      name: 'WebRTCClient',
    );

    // Send ICE candidate to host via signaling
    if (_currentSessionCode != null) {
      _signalingService.addIceCandidate(
        _currentSessionCode!,
        {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
        isHost: false, // Client candidate
      );
    }
  }

  /// Event handler for ICE connection state changes
  void _onIceConnectionStateChange(RTCIceConnectionState state) {
    developer.log(
      'ICE connection state: $state',
      name: 'WebRTCClient',
    );
  }

  /// Event handler for peer connection state changes
  void _onConnectionStateChange(RTCPeerConnectionState state) {
    developer.log(
      'Peer connection state: $state',
      name: 'WebRTCClient',
    );

    _connectionState = state;

    // Only add to controller if not closed
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

  /// Sends touch event via data channel
  ///
  /// [normalizedX] X coordinate normalized to 0.0-1.0
  /// [normalizedY] Y coordinate normalized to 0.0-1.0
  Future<void> sendTouchEvent(double normalizedX, double normalizedY) async {
    if (_dataChannel == null) {
      developer.log(
        'Data channel not ready',
        name: 'WebRTCClient',
      );
      return;
    }

    try {
      final message = json.encode({
        'type': 'tap',
        'x': normalizedX,
        'y': normalizedY,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      _dataChannel!.send(RTCDataChannelMessage(message));
    } catch (e) {
      developer.log(
        'Failed to send touch event',
        name: 'WebRTCClient',
        error: e,
      );
    }
  }

  /// Closes the WebRTC connection and cleans up resources
  Future<void> dispose() async {
    try {
      developer.log(
        'Disposing WebRTC client service',
        name: 'WebRTCClient',
      );

      // Cancel session subscription
      await _sessionSubscription?.cancel();
      _sessionSubscription = null;

      // Close data channel
      _dataChannel?.close();
      _dataChannel = null;

      // Close peer connection
      await _peerConnection?.close();
      _peerConnection = null;

      // Dispose remote stream
      _remoteStream?.getTracks().forEach((track) {
        track.stop();
      });
      await _remoteStream?.dispose();
      _remoteStream = null;

      // Clear session code
      _currentSessionCode = null;

      // Clear processed candidates
      _processedCandidates.clear();

      // Close stream controllers
      await _remoteStreamController.close();
      await _connectionStateController.close();

      developer.log(
        'WebRTC client service disposed',
        name: 'WebRTCClient',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error disposing WebRTC client service',
        name: 'WebRTCClient',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
