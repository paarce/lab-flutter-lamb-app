/// Represents a WebRTC signaling message
///
/// Used for exchanging SDP offers/answers and ICE candidates
/// between host and client via Firestore.
class WebRTCSignalingMessage {
  /// Type of the signaling message
  final SignalingMessageType type;

  /// Sender of the message (host or client)
  final SignalingSender sender;

  /// SDP (Session Description Protocol) data for offer/answer
  final String? sdp;

  /// ICE candidate data
  final Map<String, dynamic>? iceCandidate;

  /// Timestamp when the message was created
  final DateTime timestamp;

  WebRTCSignalingMessage({
    required this.type,
    required this.sender,
    this.sdp,
    this.iceCandidate,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates an offer message from the host
  factory WebRTCSignalingMessage.offer({
    required String sdp,
  }) {
    return WebRTCSignalingMessage(
      type: SignalingMessageType.offer,
      sender: SignalingSender.host,
      sdp: sdp,
    );
  }

  /// Creates an answer message from the client
  factory WebRTCSignalingMessage.answer({
    required String sdp,
  }) {
    return WebRTCSignalingMessage(
      type: SignalingMessageType.answer,
      sender: SignalingSender.client,
      sdp: sdp,
    );
  }

  /// Creates an ICE candidate message
  factory WebRTCSignalingMessage.iceCandidate({
    required SignalingSender sender,
    required Map<String, dynamic> candidate,
  }) {
    return WebRTCSignalingMessage(
      type: SignalingMessageType.iceCandidate,
      sender: sender,
      iceCandidate: candidate,
    );
  }

  /// Converts the message to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'sender': sender.toString().split('.').last,
      if (sdp != null) 'sdp': sdp,
      if (iceCandidate != null) 'iceCandidate': iceCandidate,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Creates a message from JSON
  factory WebRTCSignalingMessage.fromJson(Map<String, dynamic> json) {
    return WebRTCSignalingMessage(
      type: SignalingMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      sender: SignalingSender.values.firstWhere(
        (e) => e.toString().split('.').last == json['sender'],
      ),
      sdp: json['sdp'] as String?,
      iceCandidate: json['iceCandidate'] as Map<String, dynamic>?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  @override
  String toString() {
    return 'WebRTCSignalingMessage(type: $type, sender: $sender, timestamp: $timestamp)';
  }
}

/// Type of signaling message
enum SignalingMessageType {
  /// SDP offer from host
  offer,

  /// SDP answer from client
  answer,

  /// ICE candidate exchange
  iceCandidate,

  /// Connection ready notification
  ready,
}

/// Sender of the signaling message
enum SignalingSender {
  /// Message from the host (elderly user's device)
  host,

  /// Message from the client (family member's device)
  client,
}
