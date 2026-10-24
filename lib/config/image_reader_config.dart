/// Configuración del Lector de Imágenes (Feature 6.4)
///
/// Valores NO secretos. Las API keys viven en `secrets.dart` (Claude) o se
/// pasan con `--dart-define` (proveedores alternativos), para que este
/// archivo pueda commitearse sin riesgo.
///
/// Cambiar de proveedor sin tocar código:
/// ```bash
/// flutter run --dart-define-from-file=vision.env.json
/// ```
/// Ver `.claude/docs/FUNCIONALIDAD_6.4_LECTOR_FOTOS.md` para ejemplos.
library;

/// Proveedores de IA de visión soportados
enum VisionProvider {
  /// Claude (Anthropic) - default. Reutiliza `Secrets.claudeApiKey`.
  anthropic,

  /// Cualquier API compatible con OpenAI `/chat/completions`:
  /// OpenAI, DeepSeek, Gemini, OpenRouter, Ollama (local)...
  openaiCompatible,
}

class ImageReaderConfig {
  // ========================================
  // Experiencia de usuario
  // ========================================

  /// Tiempo que una imagen debe permanecer en pantalla antes de analizarla.
  ///
  /// Evita gastar llamadas a la IA mientras el usuario desliza rápido.
  /// Configurable: `--dart-define=IMAGE_READER_DWELL_MS=3000`
  static const Duration dwellDuration = Duration(
    milliseconds: int.fromEnvironment(
      'IMAGE_READER_DWELL_MS',
      defaultValue: 2000,
    ),
  );

  /// Número de fotos que se cargan por página desde la galería
  static const int pageSize = 50;

  /// Cuántas fotos antes del final se dispara la carga de la siguiente página
  static const int loadMoreThreshold = 5;

  // ========================================
  // Imagen enviada a la IA
  // ========================================

  /// Lado mayor (px) de la imagen enviada a la IA.
  ///
  /// 1568px es el máximo útil para Claude (más grande se reescala igual) y
  /// es suficiente para leer texto pequeño de informes médicos y chats.
  static const int maxImageSide = 1568;

  /// Calidad JPEG (0-100) de la imagen enviada a la IA
  static const int jpegQuality = 85;

  // ========================================
  // Proveedor de IA
  // ========================================

  /// Proveedor activo: `anthropic` (default) u `openai_compatible`
  static VisionProvider get provider {
    const raw = String.fromEnvironment(
      'VISION_PROVIDER',
      defaultValue: 'anthropic',
    );
    return raw == 'openai_compatible'
        ? VisionProvider.openaiCompatible
        : VisionProvider.anthropic;
  }

  /// Modelo de Claude por defecto (rápido, barato y con visión)
  static const String defaultAnthropicModel = 'claude-haiku-5-5';

  /// Modelo a usar. Si está vacío se usa el default del proveedor.
  static const String model = String.fromEnvironment('VISION_MODEL');

  /// URL base para `openai_compatible` (sin `/chat/completions`)
  ///
  /// Ejemplos:
  /// - OpenAI:   https://api.openai.com/v1
  /// - DeepSeek: https://api.deepseek.com/v1
  /// - Gemini:   https://generativelanguage.googleapis.com/v1beta/openai
  /// - Ollama:   http://192.168.1.50:11434/v1  (IP de tu ordenador en la LAN)
  static const String openaiBaseUrl = String.fromEnvironment(
    'VISION_BASE_URL',
    defaultValue: 'https://api.openai.com/v1',
  );

  /// API key para `openai_compatible` (Ollama no la necesita)
  static const String openaiApiKey = String.fromEnvironment('VISION_API_KEY');

  /// Tiempo máximo de espera de la respuesta de la IA
  ///
  /// Generoso porque los informes largos generan bastante texto.
  static const Duration requestTimeout = Duration(seconds: 45);

  /// Límite de tokens de salida (suficiente para leer un informe completo)
  static const int maxOutputTokens = 1500;
}
