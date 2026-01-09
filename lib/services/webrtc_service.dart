import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/remote_session.dart';
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
  final _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();

  /// Stream of connection state changes
  Stream<RTCPeerConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Current connection state
  RTCPeerConnectionState? _connectionState;

  RTCPeerConnectionState? get connectionState => _connectionState;

  /// Platform channel for native Android functionality
  static const _platform =
      MethodChannel('com.accessibilityapp/foreground_service');

  WebRTCService({required FirebaseSignalingService signalingService})
      : _signalingService = signalingService;

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
  ///
  /// Throws [Exception] if initialization fails
  Future<void> initializeAsHost(String sessionCode) async {
    try {
      print('🟢 [WebRTCService] INIT: Starting WebRTC initialization for session: $sessionCode');

      _currentSessionCode = sessionCode;

      // Create peer connection
      print('🟢 [WebRTCService] INIT: Step 1 - Creating peer connection...');
      await _createPeerConnection();
      print('🟢 [WebRTCService] INIT: Step 1 - Peer connection created');

      // Create and add local screen capture track
      print('🟢 [WebRTCService] INIT: Step 2 - Creating local screen track...');
      await _createLocalScreenTrack();
      print('🟢 [WebRTCService] INIT: Step 2 - Local screen track created');

      // Create data channel for touch control
      print('🟢 [WebRTCService] INIT: Step 2.5 - Creating data channel for touch control...');
      await _createDataChannel();
      print('🟢 [WebRTCService] INIT: Step 2.5 - Data channel created');

      // Setup signaling listeners (for answer and ICE candidates from client)
      print('🟢 [WebRTCService] INIT: Step 3 - Setting up signaling listeners...');
      _listenForSignaling(sessionCode);
      print('🟢 [WebRTCService] INIT: Step 3 - Signaling listeners setup');

      // Create and send offer
      print('🟢 [WebRTCService] INIT: Step 4 - Creating and sending offer...');
      await _createOffer();
      print('🟢 [WebRTCService] INIT: Step 4 - Offer created and sent');

      print('✅ [WebRTCService] INIT: WebRTC initialized successfully as host');
    } catch (e, stackTrace) {
      print('🔴 [WebRTCService] INIT: Failed to initialize WebRTC');
      print('🔴 [WebRTCService] ERROR: $e');
      print('🔴 [WebRTCService] STACK: $stackTrace');

      await dispose();
      throw Exception('Failed to initialize WebRTC: $e');
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
      print('🟢 [WebRTCService] _createLocalScreenTrack: Starting...');
      final totalStart = DateTime.now();

      // Create screen capture stream
      // Note: On Android, this requires MediaProjection permission
      print('🟢 [WebRTCService] _createLocalScreenTrack: Calling getDisplayMedia()...');
      print('⚠️  [WebRTCService] NOTE: If permission dialog appears, this might request MediaProjection again');
      final getMediaStart = DateTime.now();

      _localStream = await navigator.mediaDevices.getDisplayMedia(
        _mediaConstraints,
      );

      final getMediaDuration = DateTime.now().difference(getMediaStart);
      print('⏱️  [WebRTCService] _createLocalScreenTrack: getDisplayMedia() took ${getMediaDuration.inMilliseconds}ms (${(getMediaDuration.inMilliseconds / 1000).toStringAsFixed(1)}s)');

      if (_localStream == null) {
        throw Exception('Failed to get display media stream');
      }

      // Add video track to peer connection
      print('🟢 [WebRTCService] _createLocalScreenTrack: Adding tracks to peer connection...');
      int trackCount = 0;
      _localStream!.getTracks().forEach((track) {
        trackCount++;
        print('🟢 [WebRTCService] _createLocalScreenTrack: Adding track #$trackCount: ${track.kind} (id: ${track.id})');
        _peerConnection!.addTrack(track, _localStream!);
      });

      final totalDuration = DateTime.now().difference(totalStart);
      print('✅ [WebRTCService] _createLocalScreenTrack: Completed in ${totalDuration.inMilliseconds}ms (${(totalDuration.inMilliseconds / 1000).toStringAsFixed(1)}s) - $trackCount tracks added');
    } catch (e) {
      print('🔴 [WebRTCService] _createLocalScreenTrack: Failed - $e');
      throw Exception('Failed to create screen track: $e');
    }
  }

  /// Creates data channel for receiving touch control events from client
  Future<void> _createDataChannel() async {
    try {
      print('🟢 [WebRTCService] _createDataChannel: Creating data channel...');

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

      _controlDataChannel!.stateChangeStream.listen((state) {
        print('🟢 [WebRTCService] Data channel state: $state');
      });

      print('✅ [WebRTCService] _createDataChannel: Data channel created');

      developer.log(
        'Data channel created',
        name: 'WebRTCService',
      );
    } catch (e) {
      print('🔴 [WebRTCService] _createDataChannel: Failed - $e');
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
      print('🟢 [WebRTCService] _onDataChannelMessage: Received message');

      final data = json.decode(message.text);
      print('🟢 [WebRTCService] _onDataChannelMessage: Message type: ${data['type']}');

      if (data['type'] == 'tap') {
        final x = data['x'] as double;
        final y = data['y'] as double;
        print('🟢 [WebRTCService] _onDataChannelMessage: Touch at ($x, $y)');

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

  /// Handles remote tap event from client
  ///
  /// Converts normalized coordinates to pixel coordinates and
  /// simulates tap via AccessibilityService
  Future<void> _handleRemoteTap(double normalizedX, double normalizedY) async {
    try {
      print('🟢 [WebRTCService] _handleRemoteTap: Processing tap at ($normalizedX, $normalizedY)');

      // TODO: Get actual screen dimensions from MediaProjection
      // For now, using common Android resolutions
      // This should be obtained dynamically in production
      const screenWidth = 1080.0; // HD resolution width
      const screenHeight = 2340.0; // Common 19.5:9 aspect ratio

      // Convert normalized coordinates to pixel coordinates
      final pixelX = (normalizedX * screenWidth).toInt();
      final pixelY = (normalizedY * screenHeight).toInt();

      print('🟢 [WebRTCService] _handleRemoteTap: Pixel coordinates: ($pixelX, $pixelY)');

      // Call Platform Channel to simulate tap
      await _simulateTap(pixelX.toDouble(), pixelY.toDouble());

      developer.log(
        'Remote tap: normalized=($normalizedX, $normalizedY), pixels=($pixelX, $pixelY)',
        name: 'WebRTCService',
      );
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
  Future<void> _simulateTap(double x, double y) async {
    try {
      print('🟢 [WebRTCService] _simulateTap: Calling platform channel with ($x, $y)');

      await _platform.invokeMethod('simulateTap', {
        'x': x,
        'y': y,
      });

      print('✅ [WebRTCService] _simulateTap: Platform channel call successful');

      developer.log(
        'Tap simulated at ($x, $y)',
        name: 'WebRTCService',
      );
    } on PlatformException catch (e) {
      print('🔴 [WebRTCService] _simulateTap: Platform exception: ${e.code} - ${e.message}');

      developer.log(
        'Failed to simulate tap via platform channel',
        name: 'WebRTCService',
        error: e,
      );
    } catch (e) {
      print('🔴 [WebRTCService] _simulateTap: Unexpected error: $e');

      developer.log(
        'Unexpected error simulating tap',
        name: 'WebRTCService',
        error: e,
      );
    }
  }

  /// Creates SDP offer and sends it via signaling
  Future<void> _createOffer() async {
    try {
      print('🟢 [WebRTCService] _createOffer: Starting...');
      final totalStart = DateTime.now();

      // Create offer
      print('🟢 [WebRTCService] _createOffer: Step 4.1 - Calling createOffer()...');
      final step1Start = DateTime.now();
      final RTCSessionDescription offer =
          await _peerConnection!.createOffer();
      final step1Duration = DateTime.now().difference(step1Start);
      print('⏱️  [WebRTCService] _createOffer: Step 4.1 - createOffer() took ${step1Duration.inMilliseconds}ms (${(step1Duration.inMilliseconds / 1000).toStringAsFixed(1)}s)');

      // Set as local description
      print('🟢 [WebRTCService] _createOffer: Step 4.2 - Calling setLocalDescription()...');
      final step2Start = DateTime.now();
      await _peerConnection!.setLocalDescription(offer);
      final step2Duration = DateTime.now().difference(step2Start);
      print('⏱️  [WebRTCService] _createOffer: Step 4.2 - setLocalDescription() took ${step2Duration.inMilliseconds}ms (${(step2Duration.inMilliseconds / 1000).toStringAsFixed(1)}s)');

      print('🟢 [WebRTCService] _createOffer: SDP offer created (${offer.sdp?.length} chars)');

      // Send offer via signaling service
      print('🟢 [WebRTCService] _createOffer: Step 4.3 - Sending offer to Firestore...');
      final step3Start = DateTime.now();
      await _signalingService.setOffer(
        _currentSessionCode!,
        offer.sdp!,
      );
      final step3Duration = DateTime.now().difference(step3Start);
      print('⏱️  [WebRTCService] _createOffer: Step 4.3 - Firestore setOffer() took ${step3Duration.inMilliseconds}ms (${(step3Duration.inMilliseconds / 1000).toStringAsFixed(1)}s)');

      final totalDuration = DateTime.now().difference(totalStart);
      print('✅ [WebRTCService] _createOffer: Completed in ${totalDuration.inMilliseconds}ms (${(totalDuration.inMilliseconds / 1000).toStringAsFixed(1)}s) total');
    } catch (e) {
      print('🔴 [WebRTCService] _createOffer: Failed - $e');
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
      developer.log(
        'Handling SDP answer from client',
        name: 'WebRTCService',
      );

      final RTCSessionDescription answer = RTCSessionDescription(
        sdp,
        'answer',
      );

      await _peerConnection!.setRemoteDescription(answer);

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
