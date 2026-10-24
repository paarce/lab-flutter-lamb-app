import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../config/image_reader_config.dart';
import '../../../models/image_description.dart';
import '../../../prompts/image_reader_prompt.dart';
import '../vision_service.dart';

/// Implementación de [VisionService] para APIs compatibles con OpenAI
///
/// Un solo cliente sirve para cualquier proveedor que implemente
/// `POST {baseUrl}/chat/completions` con imágenes `image_url`:
/// - OpenAI (gpt-4.1-mini, gpt-4o-mini...)
/// - DeepSeek (modelos Flash con visión)
/// - Gemini (endpoint de compatibilidad OpenAI)
/// - OpenRouter
/// - Ollama local (qwen2.5vl, llama3.2-vision, gemma3...) - sin API key
class OpenAICompatibleVisionService implements VisionService {
  final http.Client _httpClient;
  final String _baseUrl;
  final String _apiKey;
  final String _model;

  /// Ollama y otros servidores locales no requieren API key
  final bool _requiresApiKey;

  OpenAICompatibleVisionService({
    required String baseUrl,
    required String model,
    String apiKey = '',
    http.Client? httpClient,
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _apiKey = apiKey,
        _model = model,
        _requiresApiKey = !_isLocalUrl(baseUrl),
        _httpClient = httpClient ?? http.Client();

  @override
  String get providerName => 'openai_compatible:$_model';

  @override
  Future<ImageDescription> describeImage(Uint8List jpegBytes) async {
    if (_model.isEmpty || (_requiresApiKey && _apiKey.isEmpty)) {
      throw VisionErrors.apiKeyMissing(providerName);
    }

    developer.log(
      'Describing image (${jpegBytes.length} bytes) with $providerName at $_baseUrl',
      name: 'OpenAICompatibleVisionService',
    );

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': ImageReaderConfig.maxOutputTokens,
              'messages': [
                {
                  'role': 'system',
                  'content': ImageReaderPrompt.system,
                },
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text': ImageReaderPrompt.userInstruction,
                    },
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:image/jpeg;base64,${base64Encode(jpegBytes)}',
                      },
                    },
                  ],
                },
              ],
            }),
          )
          .timeout(ImageReaderConfig.requestTimeout);

      if (response.statusCode != 200) {
        throw VisionErrors.fromHttpStatus(
          providerName,
          response.statusCode,
          response.body,
        );
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final choices = json['choices'] as List<dynamic>? ?? const [];
      final text = choices.isEmpty
          ? ''
          : (choices.first['message']?['content'] as String? ?? '');

      final description = ImageDescription.fromModelResponse(text);
      if (description == null) {
        throw VisionErrors.emptyResponse(providerName);
      }

      developer.log(
        'Image described as ${description.kind}',
        name: 'OpenAICompatibleVisionService',
      );
      return description;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to describe image',
        name: 'OpenAICompatibleVisionService',
        error: e,
        stackTrace: stackTrace,
      );
      throw VisionErrors.wrap(providerName, e, stackTrace);
    }
  }

  @override
  void dispose() => _httpClient.close();

  /// URLs de red local (Ollama en el ordenador de desarrollo)
  static bool _isLocalUrl(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' || // Host desde el emulador Android
        host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.endsWith('.local');
  }
}
