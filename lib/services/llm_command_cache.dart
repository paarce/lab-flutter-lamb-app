import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../models/command.dart';

/// Entry en el cache con metadata de expiración
class _CacheEntry {
  final VoiceCommand command;
  final DateTime expiresAt;

  _CacheEntry({
    required this.command,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache en memoria para comandos parseados por LLM
///
/// Reduce llamadas a la API almacenando respuestas exitosas.
/// - TTL de 5 minutos por defecto
/// - Máximo 100 entradas (evita memory leaks)
/// - Normalización de keys (lowercase, trimmed)
/// - Evicción de entradas más antiguas cuando está lleno
class LLMCommandCache {
  /// Máximo de entradas en el cache
  static const int _maxEntries = 100;

  /// TTL por defecto: 5 minutos
  static const Duration _defaultTTL = Duration(minutes: 5);

  /// Almacenamiento interno del cache
  final Map<String, _CacheEntry> _cache = {};

  /// Obtiene un comando del cache
  ///
  /// Retorna `null` si:
  /// - No existe en cache
  /// - Entrada expirada (y la elimina)
  VoiceCommand? get(String transcript) {
    final key = _normalizeKey(transcript);
    final entry = _cache[key];

    if (entry == null) {
      developer.log(
        'Cache MISS: "$key"',
        name: 'LLMCommandCache',
      );
      // TEMPORAL DEBUG
      debugPrint('💨 [LLMCommandCache] MISS: "$key"');
      return null;
    }

    // Verificar expiración
    if (entry.isExpired) {
      developer.log(
        'Cache EXPIRED: "$key"',
        name: 'LLMCommandCache',
      );
      _cache.remove(key);
      // TEMPORAL DEBUG
      debugPrint('⏰ [LLMCommandCache] EXPIRED: "$key"');
      return null;
    }

    developer.log(
      'Cache HIT: "$key" -> ${entry.command.type}',
      name: 'LLMCommandCache',
    );
    // TEMPORAL DEBUG
    debugPrint('⚡ [LLMCommandCache] HIT: "$key" -> ${entry.command.type}');
    return entry.command;
  }

  /// Almacena un comando en el cache
  ///
  /// Si el cache está lleno, evicta la entrada más antigua
  void put(String transcript, VoiceCommand command, {Duration? ttl}) {
    final key = _normalizeKey(transcript);
    final expiresAt = DateTime.now().add(ttl ?? _defaultTTL);

    // Evictar entradas si está lleno
    if (_cache.length >= _maxEntries && !_cache.containsKey(key)) {
      _evictOldest();
    }

    _cache[key] = _CacheEntry(
      command: command,
      expiresAt: expiresAt,
    );

    developer.log(
      'Cache PUT: "$key" -> ${command.type} (expires: $expiresAt)',
      name: 'LLMCommandCache',
    );
    // TEMPORAL DEBUG
    debugPrint('💾 [LLMCommandCache] PUT: "$key" -> ${command.type}');
  }

  /// Limpia todo el cache
  void clear() {
    _cache.clear();
    developer.log(
      'Cache CLEARED',
      name: 'LLMCommandCache',
    );
  }

  /// Cantidad de entradas en el cache
  int get length => _cache.length;

  /// Normaliza la key del transcript
  ///
  /// - Lowercase
  /// - Trimmed
  /// - Espacios múltiples colapsados
  String _normalizeKey(String transcript) {
    return transcript.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Evicta la entrada más antigua del cache
  void _evictOldest() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestExpiry;

    for (final entry in _cache.entries) {
      if (oldestExpiry == null || entry.value.expiresAt.isBefore(oldestExpiry)) {
        oldestKey = entry.key;
        oldestExpiry = entry.value.expiresAt;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
      developer.log(
        'Cache EVICTED: "$oldestKey"',
        name: 'LLMCommandCache',
      );
    }
  }

  /// Limpia entradas expiradas (llamar periódicamente si es necesario)
  void cleanExpired() {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      developer.log(
        'Cache CLEANED: ${expiredKeys.length} expired entries',
        name: 'LLMCommandCache',
      );
    }
  }
}
