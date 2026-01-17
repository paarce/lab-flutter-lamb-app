import 'dart:developer' as developer;

/// Servicio de logging centralizado (en memoria)
///
/// Mantiene últimos 100 logs en memoria para debugging
/// No persiste a disco (solo en memoria)
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal();

  /// Buffer de logs en memoria (máximo 100)
  final List<_LogEntry> _logs = [];
  static const int _maxLogs = 100;

  /// Log a nivel DEBUG (para debugging)
  void debug(String message, {String? tag}) {
    final entry = _LogEntry(
      level: 'DEBUG',
      message: message,
      tag: tag ?? 'App',
      timestamp: DateTime.now(),
    );
    _addLog(entry);
    developer.log(message, name: tag ?? 'Debug');
  }

  /// Log a nivel INFO (información general)
  void info(String message, {String? tag}) {
    final entry = _LogEntry(
      level: 'INFO',
      message: message,
      tag: tag ?? 'App',
      timestamp: DateTime.now(),
    );
    _addLog(entry);
    developer.log(message, name: tag ?? 'Info');
  }

  /// Log a nivel ERROR (errores)
  void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final fullMessage = error != null ? '$message - $error' : message;
    final entry = _LogEntry(
      level: 'ERROR',
      message: fullMessage,
      tag: tag ?? 'App',
      timestamp: DateTime.now(),
    );
    _addLog(entry);
    developer.log(
      fullMessage,
      name: tag ?? 'Error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Obtener logs en memoria
  List<String> getLogs() {
    return _logs
        .map((e) => '${e.timestamp.toIso8601String()} [${e.level}] '
            '${e.tag}: ${e.message}')
        .toList();
  }

  /// Limpiar logs
  void clearLogs() {
    _logs.clear();
  }

  void _addLog(_LogEntry entry) {
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
  }
}

class _LogEntry {
  final String level;
  final String message;
  final String tag;
  final DateTime timestamp;

  _LogEntry({
    required this.level,
    required this.message,
    required this.tag,
    required this.timestamp,
  });
}
