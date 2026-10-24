import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../config/image_reader_config.dart';
import '../../../models/image_description.dart';
import '../../../prompts/image_reader_prompt.dart';
import '../vision_service.dart';

/// Implementación de [VisionService] con Claude (Anthropic Messages API)
///
/// Proveedor por defecto: reutiliza la misma API key que el LLM Parser
/// (`Secrets.claudeApiKey`), así no hace falta crear cuentas nuevas.
class AnthropicVisionService implements VisionService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _apiVersion = '2023-06-01';

  final http.Client _httpClient;
  final String _apiKey;
  final String _model;

  AnthropicVisionService({
    required String apiKey,
    String? model,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _model = (model == null || model.isEmpty)
            ? ImageReaderConfig.defaultAnthropicModel
            : model,
        _httpClient = httpClient ?? http.Client();

  @override
  String get providerName => 'anthropic:$_model';

  @override
  Future<ImageDescription> describeImage(Uint8List jpegBytes) async {
    if (_apiKey.isEmpty || _apiKey.startsWith('YOUR_')) {
      throw VisionErrors.apiKeyMissing(providerName);
    }

    developer.log(
      'Describing image (${jpegBytes.length} bytes) with $providerName',
      name: 'AnthropicVisionService',
    );

    try {
      final response = await _httpClient
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': _apiVersion,
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': ImageReaderConfig.maxOutputTokens,
              'system': ImageReaderPrompt.system,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'image',
                      'source': {
                        'type': 'base64',
                        'media_type': 'image/jpeg',
                        'data': base64Encode(jpegBytes),
                      },
                    },
                    {
                      'type': 'text',
                      'text': ImageReaderPrompt.userInstruction,
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
      final content = json['content'] as List<dynamic>? ?? const [];
      final text = content
          .whereType<Map<String, dynamic>>()
          .where((block) => block['type'] == 'text')
          .map((block) => block['text'] as String? ?? '')
          .join('\n');

      final description = ImageDescription.fromModelResponse(text);
      if (description == null) {
        throw VisionErrors.emptyResponse(providerName);
      }

      developer.log(
        'Image described as ${description.kind}',
        name: 'AnthropicVisionService',
      );
      return description;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to describe image',
        name: 'AnthropicVisionService',
        error: e,
        stackTrace: stackTrace,
      );
      throw VisionErrors.wrap(providerName, e, stackTrace);
    }
  }

  @override
  void dispose() => _httpClient.close();
}
