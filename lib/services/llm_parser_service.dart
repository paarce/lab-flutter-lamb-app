import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/secrets.dart';
import '../models/command.dart';
import '../prompts/llm_system_prompt.dart';
import 'llm_command_cache.dart';

/// Servicio para parsear comandos de voz usando Claude API
///
/// Usa Claude 3 Haiku como fallback cuando el parser local de keywords falla.
/// Extrae comandos estructurados de lenguaje natural en español.
///
/// Características:
/// - Timeout de 3 segundos máximo
/// - Cache de respuestas exitosas
/// - Retorna `null` en caso de error (no lanza excepciones)
class LLMParserService {
  /// URL de la API de Anthropic
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  /// Modelo a usar (Haiku es rápido y económico)
  static const String _model = 'claude-3-haiku-20240307';

  /// Versión de la API de Anthropic
  static const String _apiVersion = '2023-06-01';

  /// Timeout máximo para la llamada a la API
  static const Duration _timeout = Duration(seconds: 3);

  /// Cliente HTTP
  final http.Client _httpClient;

  /// Cache de comandos
  final LLMCommandCache _cache;

  /// API key de Claude (lazy loaded desde Secrets)
  String? _apiKey;

  /// Constructor con inyección de dependencias
  LLMParserService({
    http.Client? httpClient,
    LLMCommandCache? cache,
  })  : _httpClient = httpClient ?? http.Client(),
        _cache = cache ?? LLMCommandCache();


  /// Parsea un transcript usando Claude API
  ///
  /// Retorna `null` si:
  /// - API key no configurada
  /// - Error de red/timeout
  /// - Respuesta inválida del modelo
  /// - Comando no reconocido (unknown)
  Future<VoiceCommand?> parse(String transcript) async {
    if (transcript.trim().isEmpty) {
      return null;
    }

    // Verificar cache primero
    final cached = _cache.get(transcript);
    if (cached != null) {
      // TEMPORAL DEBUG
      debugPrint('⚡ [LLMParserService] Cache HIT for: "$transcript"');
      return cached;
    }

    // TEMPORAL DEBUG
    debugPrint('🔍 [LLMParserService] Cache MISS for: "$transcript"');

    // Obtener API key
    _apiKey ??= _getApiKey();
    if (_apiKey == null || _apiKey!.isEmpty || _apiKey!.startsWith('YOUR_')) {
      developer.log(
        'Claude API key not configured',
        name: 'LLMParserService',
      );
      // TEMPORAL DEBUG
      debugPrint('⚠️ [LLMParserService] Claude API key not configured');
      return null;
    }

    try {
      developer.log(
        'Calling Claude API for: "$transcript"',
        name: 'LLMParserService',
      );
      // TEMPORAL DEBUG
      debugPrint('📡 [LLMParserService] Calling Claude API for: "$transcript"');

      final response = await _callClaudeApi(transcript);
      if (response == null) {
        // TEMPORAL DEBUG
        debugPrint('❌ [LLMParserService] Claude API returned null');
        return null;
      }

      // TEMPORAL DEBUG
      debugPrint('📥 [LLMParserService] Claude response: $response');

      final command = _parseResponse(response, transcript);
      if (command != null && command.type != CommandType.unknown) {
        // Cachear solo comandos válidos (no unknown)
        _cache.put(transcript, command);
        // TEMPORAL DEBUG
        debugPrint('✅ [LLMParserService] Parsed successfully: ${command.type}');
      } else {
        // TEMPORAL DEBUG
        debugPrint('❌ [LLMParserService] Parse failed or returned unknown');
      }

      return command;
    } catch (e, stackTrace) {
      developer.log(
        'Error parsing with LLM',
        name: 'LLMParserService',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Llama a la API de Claude
  Future<String?> _callClaudeApi(String transcript) async {
    try {
      final body = jsonEncode({
        'model': _model,
        'max_tokens': 100,
        'system': LLMSystemPrompt.prompt,
        'messages': [
          {
            'role': 'user',
            'content': transcript,
          }
        ],
      });

      final response = await _httpClient
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey!,
              'anthropic-version': _apiVersion,
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final content = json['content'] as List<dynamic>?;
        if (content != null && content.isNotEmpty) {
          final text = content[0]['text'] as String?;
          developer.log(
            'Claude response: $text',
            name: 'LLMParserService',
          );
          return text;
        }
      } else if (response.statusCode == 429) {
        developer.log(
          'Claude API rate limit exceeded',
          name: 'LLMParserService',
        );
        // TEMPORAL DEBUG
        debugPrint('⚠️ [LLMParserService] Rate limit exceeded (429)');
      } else {
        developer.log(
          'Claude API error: ${response.statusCode} - ${response.body}',
          name: 'LLMParserService',
        );
        // TEMPORAL DEBUG
        debugPrint('❌ [LLMParserService] API error ${response.statusCode}: ${response.body}');
      }

      return null;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        developer.log(
          'Claude API timeout after ${_timeout.inSeconds}s',
          name: 'LLMParserService',
        );
        // TEMPORAL DEBUG
        debugPrint('⏱️ [LLMParserService] Timeout after ${_timeout.inSeconds}s');
      } else {
        developer.log(
          'Claude API call failed: $e',
          name: 'LLMParserService',
        );
        // TEMPORAL DEBUG
        debugPrint('❌ [LLMParserService] API call failed: $e');
      }
      return null;
    }
  }

  /// Parsea la respuesta JSON de Claude a un VoiceCommand
  VoiceCommand? _parseResponse(String response, String originalText) {
    try {
      // Limpiar respuesta (a veces viene con texto extra)
      final jsonStr = _extractJson(response);
      if (jsonStr == null) {
        developer.log(
          'Could not extract JSON from response: $response',
          name: 'LLMParserService',
        );
        // DEBUG: Ver qué respuesta no se pudo parsear
        debugPrint('⚠️ [LLMParserService] Could not extract JSON from: "$response"');
        return null;
      }

      // DEBUG: Mostrar JSON extraído
      debugPrint('📦 [LLMParserService] Extracted JSON: $jsonStr');

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final typeStr = json['type'] as String?;
      final params = json['params'] as Map<String, dynamic>?;

      // DEBUG: Mostrar tipo extraído del JSON
      debugPrint('🏷️ [LLMParserService] Type from JSON: "$typeStr"');
      debugPrint('📋 [LLMParserService] Params from JSON: $params');

      if (typeStr == null) {
        debugPrint('❌ [LLMParserService] Type is null!');
        return null;
      }

      final commandType = _mapTypeToCommand(typeStr);

      // DEBUG: Mostrar mapeo de tipo a CommandType
      debugPrint('🔄 [LLMParserService] Mapped "$typeStr" → $commandType');

      developer.log(
        'Parsed LLM command: $commandType with params: $params',
        name: 'LLMParserService',
      );

      return VoiceCommand.now(
        type: commandType,
        originalText: originalText,
        parameters: params,
      );
    } catch (e) {
      developer.log(
        'Failed to parse Claude response: $e',
        name: 'LLMParserService',
      );
      return null;
    }
  }

  /// Extrae JSON de una respuesta que puede tener texto extra
  String? _extractJson(String response) {
    // Buscar el primer { y último }
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');

    if (start == -1 || end == -1 || end < start) {
      return null;
    }

    return response.substring(start, end + 1);
  }

  /// Mapea string de tipo a CommandType enum
  CommandType _mapTypeToCommand(String type) {
    switch (type.toLowerCase()) {
      // Asistencia
      case 'request_help':
        return CommandType.requestHelp;
      case 'share_screen':
        return CommandType.shareScreen;

      // WhatsApp
      case 'open_chat':
        return CommandType.openWhatsApp;

      // Interfaz
      case 'toggle_contrast':
        return CommandType.toggleContrast;

      // Audio
      case 'volume_up':
        return CommandType.adjustVolumeUp;
      case 'volume_down':
        return CommandType.adjustVolumeDown;
      case 'volume_max':
        return CommandType.setVolumeMax;
      case 'volume_min':
        return CommandType.setVolumeMin;

      // Información
      case 'tutorial':
        return CommandType.playTutorial;
      case 'list_commands':
        return CommandType.listCommands;

      // Sistema (NUEVO)
      case 'get_time':
        return CommandType.getTime;
      case 'get_date':
        return CommandType.getDate;
      case 'get_battery':
        return CommandType.getBatteryLevel;

      // Social (NUEVO)
      case 'thank_you':
        return CommandType.thankYou;
      case 'goodbye':
        return CommandType.goodbye;

      // Rechazo de conversaciones (NUEVO)
      case 'conversation_rejected':
        return CommandType.conversationRejected;

      // Control
      case 'cancel':
        return CommandType.cancel;

      default:
        return CommandType.unknown;
    }
  }

  /// Obtiene la API key desde Secrets
  String? _getApiKey() {
    try {
      return Secrets.claudeApiKey;
    } catch (e) {
      developer.log(
        'Failed to get Claude API key from Secrets: $e',
        name: 'LLMParserService',
      );
      return null;
    }
  }

  /// Limpia el cache
  void clearCache() {
    _cache.clear();
  }

  /// Cierra el cliente HTTP
  void dispose() {
    _httpClient.close();
  }
}
