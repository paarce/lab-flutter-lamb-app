# ADR-001: Unificar la capa de IA (LLM) del proyecto

**Estado:** Aceptado. Migración **pospuesta** (deuda técnica registrada)
**Fecha:** 2026-10-25
**Relacionado:** Funcionalidad 4.4 (LLM Parser), Funcionalidad 6.4 (Lector de fotos), Funcionalidad 6.5 (Leer cualquier pantalla)

---

## Contexto

Hoy hay **dos integraciones con IA independientes** que no comparten código:

| | LLM Parser (F 4.4) | Lector de fotos (F 6.4) |
|---|---|---|
| Archivo | `lib/services/llm_parser_service.dart` | `lib/services/vision/` |
| Proveedor | Solo Claude | Claude (default) u OpenAI-compatible (OpenAI, DeepSeek, Gemini, Ollama) |
| Modelo | Fijo: `claude-3-haiku-20240307` (antiguo) | Configurable (`VISION_MODEL`), default `claude-haiku-5-5` |
| Configuración | `Secrets.claudeApiKey` | `Secrets.claudeApiKey` + `--dart-define` (`ImageReaderConfig`) |
| Errores | Devuelve `null` en silencio | Lanza `AppError` (`VisionErrors`) |
| Entrada | Solo texto | Texto + imagen |

**Lo único compartido es la API key.** El cliente HTTP de Anthropic (URL, cabeceras, versión de la API, timeout, parseo de `content`, mapeo de errores) está **duplicado**.

Consecuencias de dejarlo así:
- Cambiar de modelo o proveedor obliga a tocar cada feature por separado.
- El parser de voz no puede usar Ollama, DeepSeek ni OpenAI aunque el lector de fotos sí pueda.
- Cada feature nuevo con IA (preguntas sobre la foto, leer la pantalla, resúmenes de chats...) tenderá a copiar otro cliente más.

## Decisión

1. **Ahora (rama del lector de fotos):** **no** se unifica. La prioridad es probar la funcionalidad con usuarios. Se hacen solo cambios baratos que facilitan la migración futura:
   - `VisionService.describeImage()` recibe **bytes**, no una foto de la galería, así que sirve para cualquier origen de imagen (galería, cámara, captura de pantalla).
   - Los clientes de visión aceptan `systemPrompt` y `userInstruction` por constructor: el transporte no depende del prompt del lector de fotos.
   - El mapeo de errores HTTP → `AppError` está aislado en `VisionErrors`.
   - `LLMParserService` **no se toca**.

2. **Más adelante:** crear una capa genérica `lib/services/llm/` y migrar ambos features a ella (plan abajo).

### Cuándo hacer la migración (lo que ocurra antes)

- Antes de empezar la **Fase 2 del lector** (preguntas sobre la foto, que necesita historial de conversación).
- Antes de la **Funcionalidad 6.5** (leer cualquier pantalla).
- Al añadir un **tercer** feature con IA.
- Si se decide cambiar de proveedor en toda la app (por ejemplo, todo a DeepSeek u Ollama).

## Diseño objetivo

Separar **transporte** (cómo se habla con el modelo) de **uso** (qué pide cada feature):

```
lib/services/llm/
├── llm_client.dart               # abstract: Future<LLMResponse> complete(LLMRequest)
├── llm_request.dart              # system, messages[], contenido: texto | imagen (bytes + mime), maxTokens, timeout
├── llm_response.dart             # text, usage (tokens), stopReason
├── llm_config.dart               # proveedor + modelo POR USO (comandos: barato y rápido; visión: con imágenes)
├── llm_client_factory.dart       # crea el cliente según config (patrón TTSFactory)
├── llm_errors.dart               # HTTP / timeout / red → AppError (lo que hoy es VisionErrors)
└── implementations/
    ├── anthropic_llm_client.dart
    └── openai_compatible_llm_client.dart

# Features: solo prompt + parseo
lib/services/llm_parser_service.dart       → usa LLMClient (prompt de comandos → VoiceCommand)
lib/services/image_reader_service.dart     → usa LLMClient (prompt de imagen → ImageDescription)
```

`llm_config.dart` permitiría por ejemplo:
```dart
LLMConfig.forUse(LLMUse.voiceCommands)  // Haiku, timeout 3 s, 100 tokens
LLMConfig.forUse(LLMUse.imageReading)   // Haiku u otro con visión, timeout 45 s, 1500 tokens
```

## Plan de migración

1. Crear `lib/services/llm/` moviendo el transporte de `AnthropicVisionService` y `OpenAICompatibleVisionService` a `AnthropicLLMClient` y `OpenAICompatibleLLMClient`. Los tests de `test/services/vision/` pasan casi tal cual a `test/services/llm/`.
2. Convertir `VisionService` en `ImageReaderService` (prompt + `ImageDescription.fromModelResponse`) sobre `LLMClient`. `ImageReaderProvider` no cambia de forma.
3. Migrar `LLMParserService` a `LLMClient`, **conservando su contrato**: captura el `AppError` y devuelve `null` (el parser de voz no muestra diálogos, a propósito). Mantener el cache y el timeout de 3 s.
4. Actualizar el modelo del parser (`claude-3-haiku-20240307`) al configurado.
5. Unificar `ImageReaderConfig` (parte de proveedor) en `LLMConfig`. Mantener los nombres `VISION_*` o renombrarlos a `LLM_*` con alias, para no romper los `vision.env.json` existentes.
6. Añadir prompt caching de Anthropic en el cliente (útil para la Fase 2: la misma imagen en varias preguntas).

**Esfuerzo estimado:** 1-2 días con tests. Riesgo bajo: ambos features ya tienen tests de su lado.

## Consecuencias

- ✅ Se puede probar el lector de fotos ya, sin un refactor que toque la Funcionalidad 4.4.
- ⚠️ Mientras tanto hay duplicación consciente (~150 líneas) y dos formas de configurar el proveedor.
- ⚠️ El parser de voz sigue con un modelo antiguo y fijo hasta la migración.
