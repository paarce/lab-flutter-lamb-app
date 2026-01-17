import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a remote control session
///
/// Used to store session information in Firestore for signaling
/// between the host (elderly user) and client (family member).
class RemoteSession {
  /// Unique 6-digit session code (no ambiguous characters: O/0, I/1)
  final String sessionCode;

  /// Current status of the session
  final RemoteSessionStatus status;

  /// Timestamp when the session was created
  final DateTime createdAt;

  /// Timestamp when the session expires (15 minutes after creation)
  final DateTime expiresAt;

  /// ID of the host device (optional, for tracking)
  final String? hostDeviceId;

  /// ID of the client device (set when client connects)
  final String? clientDeviceId;

  /// WebRTC offer SDP from host (set by host)
  final String? offerSdp;

  /// WebRTC answer SDP from client (set by client)
  final String? answerSdp;

  /// List of ICE candidates from host
  final List<Map<String, dynamic>>? hostIceCandidates;

  /// List of ICE candidates from client
  final List<Map<String, dynamic>>? clientIceCandidates;

  RemoteSession({
    required this.sessionCode,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.hostDeviceId,
    this.clientDeviceId,
    this.offerSdp,
    this.answerSdp,
    this.hostIceCandidates,
    this.clientIceCandidates,
  });

  /// Checks if the session has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Checks if the session is active (waiting or connected)
  bool get isActive =>
      (status == RemoteSessionStatus.waiting ||
          status == RemoteSessionStatus.connected) &&
      !isExpired;

  /// Creates a new session with a random code
  ///
  /// Session expires 15 minutes after creation
  factory RemoteSession.create({String? hostDeviceId}) {
    final now = DateTime.now();
    return RemoteSession(
      sessionCode: _generateSessionCode(),
      status: RemoteSessionStatus.waiting,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 15)),
      hostDeviceId: hostDeviceId,
    );
  }

  /// Generates a random 6-digit session code
  ///
  /// Excludes ambiguous characters: O/0 (use only 2-9), I/1 (use only 2-9)
  static String _generateSessionCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    // Use only digits 2-9 to avoid confusion with O/0 and I/1
    const digits = '23456789';
    String code = '';

    int seed = random;
    for (int i = 0; i < 6; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      code += digits[seed % digits.length];
    }

    return code;
  }

  /// Converts the session to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'sessionCode': sessionCode,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      if (hostDeviceId != null) 'hostDeviceId': hostDeviceId,
      if (clientDeviceId != null) 'clientDeviceId': clientDeviceId,
      if (offerSdp != null) 'offerSdp': offerSdp,
      if (answerSdp != null) 'answerSdp': answerSdp,
      if (hostIceCandidates != null)
        'hostIceCandidates': hostIceCandidates,
      if (clientIceCandidates != null)
        'clientIceCandidates': clientIceCandidates,
    };
  }

  /// Creates a session from a Firestore document
  factory RemoteSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;

    return RemoteSession(
      sessionCode: data['sessionCode'] as String,
      status: RemoteSessionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => RemoteSessionStatus.waiting,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      hostDeviceId: data['hostDeviceId'] as String?,
      clientDeviceId: data['clientDeviceId'] as String?,
      offerSdp: data['offerSdp'] as String?,
      answerSdp: data['answerSdp'] as String?,
      hostIceCandidates: data['hostIceCandidates'] != null
          ? List<Map<String, dynamic>>.from(data['hostIceCandidates'])
          : null,
      clientIceCandidates: data['clientIceCandidates'] != null
          ? List<Map<String, dynamic>>.from(data['clientIceCandidates'])
          : null,
    );
  }

  /// Creates a copy of the session with updated fields
  RemoteSession copyWith({
    String? sessionCode,
    RemoteSessionStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? hostDeviceId,
    String? clientDeviceId,
    String? offerSdp,
    String? answerSdp,
    List<Map<String, dynamic>>? hostIceCandidates,
    List<Map<String, dynamic>>? clientIceCandidates,
  }) {
    return RemoteSession(
      sessionCode: sessionCode ?? this.sessionCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      hostDeviceId: hostDeviceId ?? this.hostDeviceId,
      clientDeviceId: clientDeviceId ?? this.clientDeviceId,
      offerSdp: offerSdp ?? this.offerSdp,
      answerSdp: answerSdp ?? this.answerSdp,
      hostIceCandidates: hostIceCandidates ?? this.hostIceCandidates,
      clientIceCandidates: clientIceCandidates ?? this.clientIceCandidates,
    );
  }
}

/// Status of a remote control session
enum RemoteSessionStatus {
  /// Session created, waiting for client to connect
  waiting,

  /// Client connected, WebRTC handshake in progress
  connecting,

  /// WebRTC connection established
  connected,

  /// Session ended by user or timeout
  ended,

  /// Session failed due to error
  failed,
}
