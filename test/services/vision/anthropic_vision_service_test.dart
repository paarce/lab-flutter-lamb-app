import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lamb/config/image_reader_config.dart';
import 'package:lamb/errors/app_error.dart';
import 'package:lamb/errors/error_codes.dart';
import 'package:lamb/models/image_description.dart';
import 'package:lamb/services/vision/implementations/anthropic_vision_service.dart';

void main() {
  final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

  http.Response claudeResponse(String text) => http.Response.bytes(
        utf8.encode(jsonEncode({
          'content': [
            {'type': 'text', 'text': text},
          ],
        })),
        200,
        headers: {'content-type': 'application/json'},
      );

  group('AnthropicVisionService', () {
    test('sends the image as base64 with the system prompt', () async {
      late http.Request captured;
      final service = AnthropicVisionService(
        apiKey: 'sk-test',
        httpClient: MockClient((request) async {
          captured = request;
          return claudeResponse('{"kind": "photo", "text": "Una foto."}');
        }),
      );

      await service.describeImage(imageBytes);

      expect(captured.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(captured.headers['x-api-key'], 'sk-test');
      expect(captured.headers['anthropic-version'], isNotEmpty);

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], ImageReaderConfig.defaultAnthropicModel);
      expect(body['system'], contains('baja visión'));
      final content = body['messages'][0]['content'] as List;
      expect(content[0]['type'], 'image');
      expect(content[0]['source']['media_type'], 'image/jpeg');
      expect(content[0]['source']['data'], base64Encode(imageBytes));
    });

    test('uses a custom model when configured', () async {
      late Map<String, dynamic> body;
      final service = AnthropicVisionService(
        apiKey: 'sk-test',
        model: 'claude-custom',
        httpClient: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return claudeResponse('{"kind": "photo", "text": "Una foto."}');
        }),
      );

      await service.describeImage(imageBytes);
      expect(body['model'], 'claude-custom');
    });

    test('accepts custom prompts (reusable for other image features)',
        () async {
      late Map<String, dynamic> body;
      final service = AnthropicVisionService(
        apiKey: 'sk-test',
        systemPrompt: 'Lee la pantalla actual.',
        userInstruction: '¿Qué hay en pantalla?',
        httpClient: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return claudeResponse('{"kind": "other", "text": "Una pantalla."}');
        }),
      );

      await service.describeImage(imageBytes);

      expect(body['system'], 'Lee la pantalla actual.');
      expect(body['messages'][0]['content'][1]['text'], '¿Qué hay en pantalla?');
    });

    test('parses the description from the response', () async {
      final service = AnthropicVisionService(
        apiKey: 'sk-test',
        httpClient: MockClient((_) async => claudeResponse(
              '{"kind": "chat", "text": "Es una captura de un chat de WhatsApp con María."}',
            )),
      );

      final result = await service.describeImage(imageBytes);

      expect(result.kind, ImageKind.chatScreenshot);
      expect(result.spokenText, contains('María'));
    });

    test('throws non-retryable error when API key is missing', () async {
      var called = false;
      final service = AnthropicVisionService(
        apiKey: 'YOUR_CLAUDE_API_KEY_HERE',
        httpClient: MockClient((_) async {
          called = true;
          return claudeResponse('');
        }),
      );

      await expectLater(
        service.describeImage(imageBytes),
        throwsA(isA<AppError>()
            .having((e) => e.code, 'code', ErrorCodes.visionApiKeyMissing)
            .having((e) => e.canRetry, 'canRetry', false)),
      );
      expect(called, isFalse);
    });

    test('maps 401 to invalid API key (not retryable)', () async {
      final service = AnthropicVisionService(
        apiKey: 'sk-bad',
        httpClient: MockClient((_) async => http.Response('unauthorized', 401)),
      );

      await expectLater(
        service.describeImage(imageBytes),
        throwsA(isA<AppError>()
            .having((e) => e.code, 'code', ErrorCodes.llmApiKeyInvalid)
            .having((e) => e.canRetry, 'canRetry', false)),
      );
    });

    test('maps 429 to rate limit (retryable)', () async {
      final service = AnthropicVisionService(
        apiKey: 'sk-test',
        httpClient: MockClient((_) async => http.Response('slow down', 429)),
      );

      await expectLater(
        service.describeImage(imageBytes),
        throwsA(isA<AppError>()
            .having((e) => e.code, 'code', ErrorCodes.llmRateLimitExceeded)
            .having((e) => e.canRetry, 'canRetry', true)),
      );
    });

    test('maps 500 to request failed (retryable)', () async {
      final service = AnthropicVisionService(
        apiKey: 'sk-test',
        httpClient: MockClient((_) async => http.Response('boom', 500)),
      );

      await expectLater(
        service.describeImage(imageBytes),
        throwsA(isA<AppError>()
            .having((e) => e.code, 'code', ErrorCodes.visionRequestFailed)
            .having((e) => e.canRetry, 'canRetry', true)),
      );
    });

    test('throws empty response error when model returns no text', () async {
      final service = AnthropicVisionService(
        apiKey: 'sk-test',
        httpClient: MockClient((_) async => claudeResponse('')),
      );

      await expectLater(
        service.describeImage(imageBytes),
        throwsA(isA<AppError>()
            .having((e) => e.code, 'code', ErrorCodes.visionEmptyResponse)),
      );
    });
  });
}
