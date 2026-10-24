import 'dart:developer' as developer;

import '../../config/image_reader_config.dart';
import '../../config/secrets.dart';
import 'implementations/anthropic_vision_service.dart';
import 'implementations/openai_compatible_vision_service.dart';
import 'vision_service.dart';

/// Factory que crea el [VisionService] según `ImageReaderConfig.provider`
///
/// Cambiar de proveedor NO requiere tocar código, solo `--dart-define`.
/// Ver `.claude/docs/FUNCIONALIDAD_6.4_LECTOR_FOTOS.md`.
class VisionServiceFactory {
  static VisionService create() {
    final provider = ImageReaderConfig.provider;
    developer.log(
      'Creating vision service for provider: $provider',
      name: 'VisionServiceFactory',
    );

    switch (provider) {
      case VisionProvider.anthropic:
        return AnthropicVisionService(
          apiKey: Secrets.claudeApiKey,
          model: ImageReaderConfig.model,
        );
      case VisionProvider.openaiCompatible:
        return OpenAICompatibleVisionService(
          baseUrl: ImageReaderConfig.openaiBaseUrl,
          apiKey: ImageReaderConfig.openaiApiKey,
          model: ImageReaderConfig.model,
        );
    }
  }
}
