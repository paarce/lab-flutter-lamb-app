import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lamb/errors/app_error.dart';
import 'package:lamb/errors/error_codes.dart';
import 'package:lamb/models/image_description.dart';
import 'package:lamb/services/vision/implementations/openai_compatible_vision_service.dart';

void main() {
  final imageBytes = Uint8List.fromList([9, 8, 7]);

  http.Response chatResponse(String content) => http.Response.bytes(
        utf8.encode(jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': content},
            },
          ],
        })),
        200,
        headers: {'content-type': 'application/json'},
      );

  group('OpenAICompatibleVisionService', () {
    test('posts to {baseUrl}/chat/completions with bearer token and data URL',
        () async {
      late http.Request captured;
      final service = OpenAICompatibleVisionService(
        baseUrl: 'https://api.example.com/v1/',
        model: 'vision-mini',
        apiKey: 'key-123',
        httpClient: MockClient((request) async {
          captured = request;
          return chatResponse(
            '{"kind": "document", "text": "Es un informe médico."}',
          );
        }),
      );

      final result = await service.describeImage(imageBytes);

      expect(
        captured.url.toString(),
        'https://api.example.com/v1/chat/completions',
      );
      expect(captured.headers['Authorization'], 'Bearer key-123');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'vision-mini');
      expect(body['messages'][0]['role'], 'system');
      final userContent = body['messages'][1]['content'] as List;
      final imagePart = userContent.firstWhere((p) => p['type'] == 'image_url');
      expect(
        imagePart['image_url']['url'],
        'data:image/jpeg;base64,${base64Encode(imageBytes)}',
      );

      expect(result.kind, ImageKind.document);
      expect(result.spokenText, 'Es un informe médico.');
    });

    test('local Ollama URL works without API key', () async {
      late http.Request captured;
      final service = OpenAICompatibleVisionService(
        baseUrl: 'http://192.168.1.50:11434/v1',
        model: 'qwen2.5vl',
        httpClient: MockClient((request) async {
          captured = request;
          return chatResponse('{"kind": "photo", "text": "Un perro."}');
        }),
      );

      final result = await service.describeImage(imageBytes);

      expect(captured.headers.containsKey('Authorization'), isFalse);
      expect(result.spokenText, 'Un perro.');
    });

    test('remote URL without API key throws missing key error', () async {
      final service = OpenAICompatibleVisionService(
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4.1-mini',
        httpClient: MockClient((_) async => chatResponse('x')),
      );

      await expectLater(
        service.describeImage(imageBytes),
        throwsA(isA<AppError>()
            .having((e) => e.code, 'code', ErrorCodes.visionApiKeyMissing)
            .having((e) => e.canRetry, 'canRetry', false)),
      );
    });

    test('missing model throws missing configuration error', () async {
      final service = OpenAICompatibleVisionService(
        baseUrl: 'https://api.openai.com/v1',
        model: '',
        apiKey: 'key',
        httpClient: MockClient((_) async => chatResponse('x')),
      );

      await expectLater(
        service.describeImage(imageBytes),
        throwsA(isA<AppError>()
            .having((e) => e.code, 'code', ErrorCodes.visionApiKeyMissing)),
      );
    });

    test('empty choices throws empty response error', () async {
      final service = OpenAICompatibleVisionService(
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
        apiKey: 'k',
        httpClient: MockClient((_) async => http.Response('{"choices": []}', 200)),
      );

      await expectLater(
        service.describeImage(imageBytes),
        throwsA(isA<AppError>()
            .having((e) => e.code, 'code', ErrorCodes.visionEmptyResponse)),
      );
    });

    test('maps 403 to invalid API key', () async {
      final service = OpenAICompatibleVisionService(
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
        apiKey: 'k',
        httpClient: MockClient((_) async => http.Response('forbidden', 403)),
      );

      await expectLater(
        service.describeImage(imageBytes),
        throwsA(isA<AppError>()
            .having((e) => e.code, 'code', ErrorCodes.llmApiKeyInvalid)),
      );
    });
  });
}
