import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/remote_session.dart';
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
  ///
  /// Throws [Exception] if session not found or connection fails
  Future<void> joinSession(String sessionCode) async {
    try {
      print('🔵 [WebRTCClient] JOIN: Starting to join session: $sessionCode');
      _currentSessionCode = sessionCode;

      // Step 1: Fetch session from Firestore
      print('🔵 [WebRTCClient] JOIN: Step 1 - Fetching session from Firestore...');
      final session = await _signalingService.getSession(sessionCode);

      if (session == null) {
        throw Exception('Código de sesión no encontrado o expirado');
      }

      if (session.status == RemoteSessionStatus.ended) {
        throw Exception('La sesión ha terminado');
      }

      if (session.offerSdp == null) {
        throw Exception(
          'La sesión aún no tiene oferta. Por favor, espera unos segundos e intenta de nuevo.',
        );
      }

      print('🔵 [WebRTCClient] JOIN: Step 1 - Session found with offer (${session.offerSdp!.length} chars)');

      // Step 2: Create peer connection
      print('🔵 [WebRTCClient] JOIN: Step 2 - Creating peer connection...');
      await _createPeerConnection();
      print('🔵 [WebRTCClient] JOIN: Step 2 - Peer connection created');

      // Step 3: Set remote description (offer from host)
      print('🔵 [WebRTCClient] JOIN: Step 3 - Setting remote offer...');
      await _setRemoteOffer(session.offerSdp!);
      print('🔵 [WebRTCClient] JOIN: Step 3 - Remote offer set');

      // Step 4: Create and send answer
      print('🔵 [WebRTCClient] JOIN: Step 4 - Creating answer...');
      await _createAnswer();
      print('🔵 [WebRTCClient] JOIN: Step 4 - Answer created and sent');

      // Step 5: Add host's ICE candidates (if any)
      if (session.hostIceCandidates != null &&
          session.hostIceCandidates!.isNotEmpty) {
        print('🔵 [WebRTCClient] JOIN: Step 5 - Adding ${session.hostIceCandidates!.length} host ICE candidates...');
        await _addHostIceCandidates(session.hostIceCandidates!);
        print('🔵 [WebRTCClient] JOIN: Step 5 - Host ICE candidates added');
      } else {
        print('🔵 [WebRTCClient] JOIN: Step 5 - No host ICE candidates yet');
      }

      // Step 6: Listen for new host ICE candidates
      print('🔵 [WebRTCClient] JOIN: Step 6 - Setting up signaling listeners...');
      _listenForSignaling(sessionCode);
      print('🔵 [WebRTCClient] JOIN: Step 6 - Signaling listeners setup');

      print('✅ [WebRTCClient] JOIN: Successfully joined session');
    } catch (e, stackTrace) {
      print('🔴 [WebRTCClient] JOIN: Failed to join session');
      print('🔴 [WebRTCClient] ERROR: $e');
      print('🔴 [WebRTCClient] STACK: $stackTrace');

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
      print('🔵 [WebRTCClient] _setRemoteOffer: Starting...');

      final RTCSessionDescription offer = RTCSessionDescription(
        sdp,
        'offer',
      );

      await _peerConnection!.setRemoteDescription(offer);

      print('✅ [WebRTCClient] _setRemoteOffer: Remote offer set');

      developer.log(
        'Remote offer set',
        name: 'WebRTCClient',
      );
    } catch (e) {
      print('🔴 [WebRTCClient] _setRemoteOffer: Failed - $e');
      throw Exception('Failed to set remote offer: $e');
    }
  }

  /// Creates SDP answer and sends it via signaling
  Future<void> _createAnswer() async {
    try {
      print('🔵 [WebRTCClient] _createAnswer: Starting...');

      // Create answer
      print('🔵 [WebRTCClient] _createAnswer: Calling createAnswer()...');
      final RTCSessionDescription answer =
          await _peerConnection!.createAnswer();
      print('🔵 [WebRTCClient] _createAnswer: Answer created (${answer.sdp?.length} chars)');

      // Set as local description
      print('🔵 [WebRTCClient] _createAnswer: Calling setLocalDescription()...');
      await _peerConnection!.setLocalDescription(answer);
      print('🔵 [WebRTCClient] _createAnswer: Local description set');

      // Send answer via signaling service
      print('🔵 [WebRTCClient] _createAnswer: Sending answer to Firestore...');
      await _signalingService.setAnswer(
        _currentSessionCode!,
        answer.sdp!,
      );
      print('✅ [WebRTCClient] _createAnswer: Answer sent to Firestore');

      developer.log(
        'Answer created and sent',
        name: 'WebRTCClient',
      );
    } catch (e) {
      print('🔴 [WebRTCClient] _createAnswer: Failed - $e');
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
    print('🔵 [WebRTCClient] _onTrack: Track received');
    print('🔵 [WebRTCClient] _onTrack: Track kind: ${event.track.kind}');
    print('🔵 [WebRTCClient] _onTrack: Track id: ${event.track.id}');
    print('🔵 [WebRTCClient] _onTrack: Streams count: ${event.streams.length}');

    developer.log(
      'Track received: ${event.track.kind}',
      name: 'WebRTCClient',
    );

    if (event.track.kind == 'video' && event.streams.isNotEmpty) {
      _remoteStream = event.streams.first;
      _remoteStreamController.add(_remoteStream!);

      print('✅ [WebRTCClient] _onTrack: Remote stream set (id: ${_remoteStream!.id})');

      developer.log(
        'Remote stream set: ${_remoteStream!.id}',
        name: 'WebRTCClient',
      );
    }
  }

  /// Event handler for receiving data channel from host
  void _onDataChannel(RTCDataChannel channel) {
    print('🔵 [WebRTCClient] _onDataChannel: Data channel received');
    print('🔵 [WebRTCClient] _onDataChannel: Channel label: ${channel.label}');

    developer.log(
      'Data channel received: ${channel.label}',
      name: 'WebRTCClient',
    );

    if (channel.label == 'control') {
      _dataChannel = channel;
      print('✅ [WebRTCClient] _onDataChannel: Control data channel ready');
    }
  }

  /// Event handler for ICE candidate events
  void _onIceCandidate(RTCIceCandidate candidate) {
    print('🔵 [WebRTCClient] _onIceCandidate: ICE candidate generated');

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
    print('🔵 [WebRTCClient] _onIceConnectionStateChange: ICE state: $state');

    developer.log(
      'ICE connection state: $state',
      name: 'WebRTCClient',
    );
  }

  /// Event handler for peer connection state changes
  void _onConnectionStateChange(RTCPeerConnectionState state) {
    print('🔵 [WebRTCClient] _onConnectionStateChange: Connection state: $state');

    developer.log(
      'Peer connection state: $state',
      name: 'WebRTCClient',
    );

    _connectionState = state;
    _connectionStateController.add(state);

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

      print('🔵 [WebRTCClient] sendTouchEvent: Sent touch at ($normalizedX, $normalizedY)');

      developer.log(
        'Sent touch event: ($normalizedX, $normalizedY)',
        name: 'WebRTCClient',
      );
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
      print('🔵 [WebRTCClient] dispose: Disposing client service...');

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

      print('✅ [WebRTCClient] dispose: Client service disposed');

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
