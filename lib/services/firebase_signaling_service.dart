import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../errors/app_error.dart';
import '../errors/error_category.dart';
import '../errors/error_codes.dart';
import '../models/remote_session.dart';
import 'error_handler_service.dart';

/// Service for managing remote control sessions via Firebase Firestore
///
/// Handles:
/// - Creating new sessions with unique codes
/// - Listening for real-time session updates (signaling)
/// - Updating sessions with WebRTC SDP and ICE candidates
/// - Cleaning up expired sessions
class FirebaseSignalingService {
  final FirebaseFirestore _firestore;
  final String _collectionPath = 'remote_sessions';

  /// Cached reference to the sessions collection
  late final CollectionReference<Map<String, dynamic>> _sessionsCollection;

  FirebaseSignalingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _sessionsCollection = _firestore.collection(_collectionPath);
  }

  /// Creates a new remote control session
  ///
  /// Generates a unique 6-digit code and stores the session in Firestore.
  /// The session expires after 15 minutes.
  ///
  /// [hostDeviceId] Optional device identifier for the host
  /// [context] BuildContext for error handling (optional)
  ///
  /// Returns the created [RemoteSession]
  ///
  /// Throws [AppError] if session creation fails
  Future<RemoteSession> createSession({
    String? hostDeviceId,
    BuildContext? context,
  }) async {
    try {
      print('🟡 [FirebaseSignaling] Creating new remote session');

      // Generate new session
      final session = RemoteSession.create(hostDeviceId: hostDeviceId);
      print(
          '🟡 [FirebaseSignaling] Generated session code: ${session.sessionCode}');

      print('🟡 [FirebaseSignaling] Storing session in Firestore...');
      final startTime = DateTime.now();

      // Store in Firestore with session code as document ID
      await _sessionsCollection
          .doc(session.sessionCode)
          .set(session.toFirestore());

      final duration = DateTime.now().difference(startTime);
      print(
          '✅ [FirebaseSignaling] Session created successfully: ${session.sessionCode}');
      print(
          '⏱️  [FirebaseSignaling] createSession() took: ${duration.inMilliseconds}ms (${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s)');

      return session;
    } catch (e, stackTrace) {
      // Parse error message to provide user-friendly feedback
      final errorString = e.toString().toLowerCase();

      AppError appError;

      // Check for common Firestore errors
      if (errorString.contains('permission') ||
          errorString.contains('permission_denied')) {
        developer.log(
          'CRITICAL: Firestore permission denied',
          name: 'FirebaseSignalingService',
          error: e,
          stackTrace: stackTrace,
        );

        appError = AppError(
          category: ErrorCategory.firebase,
          code: ErrorCodes.fbFirestoreFailed,
          technicalMessage: e.toString(),
          userMessage:
              'Cloud Firestore no está habilitado. Por favor, habilita Firestore en Firebase Console.',
          canRetry: false,
          stackTrace: stackTrace,
        );
      } else if (errorString.contains('offline') ||
          errorString.contains('network')) {
        developer.log(
          'Firestore network error',
          name: 'FirebaseSignalingService',
          error: e,
        );

        appError = AppError(
          category: ErrorCategory.network,
          code: ErrorCodes.netNoInternet,
          technicalMessage: e.toString(),
          userMessage:
              'Sin conexión a internet. Verifica WiFi o datos móviles.',
          canRetry: true,
          stackTrace: stackTrace,
        );
      } else if (errorString.contains('timeout')) {
        developer.log(
          'Firestore operation timed out',
          name: 'FirebaseSignalingService',
          error: e,
        );

        appError = AppError(
          category: ErrorCategory.network,
          code: ErrorCodes.netTimeout,
          technicalMessage: e.toString(),
          userMessage:
              'La operación tardó demasiado. Intenta de nuevo o verifica tu conexión.',
          canRetry: true,
          stackTrace: stackTrace,
        );
      } else {
        // Generic error
        developer.log(
          'Failed to create session (unknown error)',
          name: 'FirebaseSignalingService',
          error: e,
          stackTrace: stackTrace,
        );

        appError = AppError(
          category: ErrorCategory.firebase,
          code: ErrorCodes.fbFirestoreFailed,
          technicalMessage: e.toString(),
          userMessage: 'Error al crear sesión remota.',
          canRetry: true,
          stackTrace: stackTrace,
        );
      }

      // Show user-friendly error if context available
      if (context != null && context.mounted) {
        await ErrorHandlerService.handleError(
          context: context,
          error: appError,
          service: 'FirebaseSignalingService',
          canRetry: appError.canRetry,
          onRetry: () => createSession(
            hostDeviceId: hostDeviceId,
            context: context,
          ),
        );
      }

      throw appError;
    }
  }

  /// Gets a session by its code
  ///
  /// Returns [RemoteSession] if found and not expired, null otherwise
  Future<RemoteSession?> getSession(String sessionCode) async {
    try {
      developer.log(
        'Fetching session: $sessionCode',
        name: 'FirebaseSignalingService',
      );

      final doc = await _sessionsCollection.doc(sessionCode).get();

      if (!doc.exists) {
        developer.log(
          'Session not found: $sessionCode',
          name: 'FirebaseSignalingService',
        );
        return null;
      }

      final session = RemoteSession.fromFirestore(doc);

      // Check if expired
      if (session.isExpired) {
        developer.log(
          'Session expired: $sessionCode',
          name: 'FirebaseSignalingService',
        );
        // Clean up expired session
        await deleteSession(sessionCode);
        return null;
      }

      return session;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to get session: $sessionCode',
        name: 'FirebaseSignalingService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Listens to real-time updates for a session
  ///
  /// Returns a stream of [RemoteSession] updates
  ///
  /// The stream automatically ends if:
  /// - Session is deleted
  /// - Session expires
  /// - Session status becomes 'ended' or 'failed'
  Stream<RemoteSession?> watchSession(String sessionCode) {
    developer.log(
      'Watching session: $sessionCode',
      name: 'FirebaseSignalingService',
    );

    return _sessionsCollection
        .doc(sessionCode)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        developer.log(
          'Session deleted or not found: $sessionCode',
          name: 'FirebaseSignalingService',
        );
        return null;
      }

      final session = RemoteSession.fromFirestore(snapshot);

      // Check if expired
      if (session.isExpired) {
        developer.log(
          'Session expired during watch: $sessionCode',
          name: 'FirebaseSignalingService',
        );
        // Schedule cleanup (async, don't await)
        deleteSession(sessionCode);
        return null;
      }

      // Check if session ended
      if (session.status == RemoteSessionStatus.ended ||
          session.status == RemoteSessionStatus.failed) {
        developer.log(
          'Session ended: $sessionCode (status: ${session.status})',
          name: 'FirebaseSignalingService',
        );
      }

      return session;
    });
  }

  /// Updates session status
  ///
  /// Common statuses:
  /// - waiting → connecting → connected
  /// - waiting/connecting/connected → ended (by user)
  /// - waiting/connecting/connected → failed (on error)
  Future<void> updateSessionStatus(
    String sessionCode,
    RemoteSessionStatus status,
  ) async {
    try {
      developer.log(
        'Updating session status: $sessionCode → $status',
        name: 'FirebaseSignalingService',
      );

      await _sessionsCollection.doc(sessionCode).update({
        'status': status.toString().split('.').last,
      });
    } catch (e, stackTrace) {
      developer.log(
        'Failed to update session status: $sessionCode',
        name: 'FirebaseSignalingService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to update session status: $e');
    }
  }

  /// Updates session with WebRTC offer SDP (from host)
  Future<void> setOffer(String sessionCode, String sdp) async {
    try {
      print('🟡 [FirebaseSignaling] setOffer: Updating session $sessionCode with offer (${sdp.length} chars)');
      final startTime = DateTime.now();

      // NO TIMEOUT - Let's see how long it REALLY takes
      await _sessionsCollection.doc(sessionCode).update({
        'offerSdp': sdp,
        'status': RemoteSessionStatus.connecting.toString().split('.').last,
      });

      final duration = DateTime.now().difference(startTime);
      print('✅ [FirebaseSignaling] setOffer: Updated successfully in ${duration.inMilliseconds}ms (${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s)');
    } catch (e, stackTrace) {
      print('🔴 [FirebaseSignaling] setOffer: Failed for session $sessionCode - $e');
      throw Exception('Failed to set offer: $e');
    }
  }

  /// Updates session with WebRTC answer SDP (from client)
  Future<void> setAnswer(String sessionCode, String sdp) async {
    try {
      developer.log(
        'Setting answer for session: $sessionCode',
        name: 'FirebaseSignalingService',
      );

      await _sessionsCollection.doc(sessionCode).update({
        'answerSdp': sdp,
      });
    } catch (e, stackTrace) {
      developer.log(
        'Failed to set answer: $sessionCode',
        name: 'FirebaseSignalingService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to set answer: $e');
    }
  }

  /// Adds an ICE candidate to the session
  ///
  /// [isHost] determines if the candidate is from host or client
  Future<void> addIceCandidate(
    String sessionCode,
    Map<String, dynamic> candidate, {
    required bool isHost,
  }) async {
    try {
      developer.log(
        'Adding ICE candidate for session: $sessionCode (host: $isHost)',
        name: 'FirebaseSignalingService',
      );

      final fieldName = isHost ? 'hostIceCandidates' : 'clientIceCandidates';

      await _sessionsCollection.doc(sessionCode).update({
        fieldName: FieldValue.arrayUnion([candidate]),
      });
    } catch (e, stackTrace) {
      developer.log(
        'Failed to add ICE candidate: $sessionCode',
        name: 'FirebaseSignalingService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - ICE candidate failures are not critical
      // Connection might still work with partial candidates
    }
  }

  /// Sets the client device ID when a client connects
  Future<void> setClientDevice(String sessionCode, String clientDeviceId) async {
    try {
      developer.log(
        'Setting client device for session: $sessionCode',
        name: 'FirebaseSignalingService',
      );

      await _sessionsCollection.doc(sessionCode).update({
        'clientDeviceId': clientDeviceId,
      });
    } catch (e, stackTrace) {
      developer.log(
        'Failed to set client device: $sessionCode',
        name: 'FirebaseSignalingService',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Failed to set client device: $e');
    }
  }

  /// Deletes a session (cleanup)
  Future<void> deleteSession(String sessionCode) async {
    try {
      developer.log(
        'Deleting session: $sessionCode',
        name: 'FirebaseSignalingService',
      );

      await _sessionsCollection.doc(sessionCode).delete();
    } catch (e, stackTrace) {
      developer.log(
        'Failed to delete session: $sessionCode',
        name: 'FirebaseSignalingService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - cleanup failures are not critical
    }
  }

  /// Ends a session (marks as ended and schedules cleanup)
  ///
  /// This is the preferred way to end a session (vs deleteSession)
  /// because it allows clients to see the session ended before deletion
  Future<void> endSession(String sessionCode) async {
    try {
      developer.log(
        'Ending session: $sessionCode',
        name: 'FirebaseSignalingService',
      );

      // Mark as ended first
      await updateSessionStatus(sessionCode, RemoteSessionStatus.ended);

      // Schedule cleanup after 5 seconds (gives clients time to see "ended" status)
      Future.delayed(const Duration(seconds: 5), () {
        deleteSession(sessionCode);
      });
    } catch (e, stackTrace) {
      developer.log(
        'Failed to end session: $sessionCode',
        name: 'FirebaseSignalingService',
        error: e,
        stackTrace: stackTrace,
      );
      // Try to delete anyway
      await deleteSession(sessionCode);
    }
  }

  /// Cleans up all expired sessions
  ///
  /// This is useful for maintenance, but Firestore security rules
  /// already prevent access to expired sessions
  Future<void> cleanupExpiredSessions() async {
    try {
      developer.log(
        'Cleaning up expired sessions',
        name: 'FirebaseSignalingService',
      );

      final now = Timestamp.now();

      final expiredQuery = await _sessionsCollection
          .where('expiresAt', isLessThan: now)
          .get();

      if (expiredQuery.docs.isEmpty) {
        developer.log(
          'No expired sessions to clean up',
          name: 'FirebaseSignalingService',
        );
        return;
      }

      // Delete all expired sessions
      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      developer.log(
        'Cleaned up ${expiredQuery.docs.length} expired sessions',
        name: 'FirebaseSignalingService',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to cleanup expired sessions',
        name: 'FirebaseSignalingService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - cleanup failures are not critical
    }
  }
}
