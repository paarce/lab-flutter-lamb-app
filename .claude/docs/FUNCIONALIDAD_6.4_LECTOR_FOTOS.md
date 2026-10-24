# Funcionalidad 6.4: Lector de Fotos de la Galería

**Estado:** Fase 1 implementada (lectura automática). Fase 2 (preguntas por voz) diseñada, pendiente.
**Plataforma:** Android 7.0+ (API 24+)
**Rama:** `feature/7-gallery-image-reader`

---

## 1. Qué hace

El usuario abre **"Leer mis fotos"** desde la pantalla principal (botón grande o comando de voz) y:

1. La app pide permiso para ver las fotos (diálogo del sistema).
2. Muestra las fotos a **pantalla completa**, de la más reciente a la más antigua.
3. El usuario **desliza** (o usa los botones **Anterior / Siguiente**) para cambiar de foto.
4. Si se queda en una foto **2 segundos** (configurable), la app avisa *"Leyendo la foto, un momento"*, la envía a la IA y **lee en voz alta** lo que contiene:
   - **Captura de chat:** *"Es una captura de un chat de WhatsApp con María. María dice: ..."*
   - **Foto:** *"Es una foto de una persona en un paisaje de montaña..."*
   - **Resultados médicos:** *"Son los resultados de un análisis de sangre del 3 de mayo. Glucosa: 110 miligramos por decilitro, está por encima del rango normal..."*
   - **Documento / informe:** lee todo el texto relevante (diagnóstico, indicaciones, dosis, fechas).
5. El texto también se muestra en un panel grande (24sp) bajo la foto, con el tipo de imagen.

### Controles

| Control | Acción |
|---|---|
| Deslizar / **Anterior** / **Siguiente** | Cambia de foto. Detiene la lectura en curso. |
| Botón central | Cambia según el estado: **Leer foto** (sin esperar) · **Leyendo** · **Detener** · **Repetir** · **Reintentar** |
| **Ocultar texto** (barra superior) o tocar la foto | Muestra la foto completa sin el panel |
| Comando de voz | *"leer mis fotos"*, *"ver fotos"*, *"abre la galería"*, *"leer imagen"*... |

### Decisiones de UX

- **Tiempo de permanencia (dwell):** evita gastar llamadas a la IA mientras el usuario pasa fotos rápido.
- **Caché en memoria:** volver a una foto ya leída la repite **sin coste** y al instante.
- **Sin reintentos automáticos** (regla del proyecto): si falla, se muestra el diálogo accesible de `ErrorHandlerService` con botón *Reintentar*. Una foto fallida no se vuelve a pedir sola.
- **Error de configuración** (falta API key / key inválida): se muestra **una sola vez** y se pausa la lectura automática para no repetir el diálogo en cada foto.
- **Respuesta tardía:** si la IA responde cuando el usuario ya cambió de foto, se guarda en caché pero no se lee (no se mezclan descripciones).
- **Accesibilidad:** botones de 88dp con icono + texto 24sp, `Semantics` en todo, `liveRegion` para estados, respeta "reducir animaciones" del sistema, escala de texto con `FittedBox`.

---

## 2. Proveedor de IA: decisión

### Recomendación para el MVP: **Claude Haiku 5.5 (default, ya configurado)**

| Criterio | Por qué |
|---|---|
| **Coste** | ~0,10 USD por millón de tokens de entrada y 0,50 USD por millón de salida (prompts < 100K). Una foto (~1.500 tokens) + respuesta (~400 tokens) ≈ **0,0004 USD por foto** (≈ 2.500 fotos por 1 USD). Estimación: verifica en la [página de precios de Anthropic](https://www.anthropic.com/pricing), el tokenizer nuevo puede variar las cifras. |
| **Cero configuración** | Reutiliza `Secrets.claudeApiKey`, que ya usa el LLM Parser (Funcionalidad 4.4). No hay que crear cuentas. |
| **Calidad** | Buen OCR en español (informes, análisis, capturas) y descripción de fotos. |
| **Privacidad** | La API de Anthropic no usa los datos de la API para entrenar por defecto (relevante para informes médicos). |

### Alternativas (sin tocar código, vía `--dart-define`)

Un único cliente **compatible con OpenAI** (`/chat/completions` con `image_url`) cubre todas estas opciones:

| Proveedor | Coste aprox. | Notas |
|---|---|---|
| **Ollama (local)** | Gratis | Necesita un ordenador con GPU/CPU potente en la misma red WiFi. Bueno para desarrollo y pruebas sin gastar. **No apto para producción** (el móvil no puede ejecutar el modelo). Modelos con visión: `qwen2.5vl`, `llama3.2-vision`, `gemma3`. Calidad de OCR menor en informes largos. |
| **DeepSeek** | Muy barato | Según fuentes de terceros, desde septiembre de 2026 los modelos Flash aceptan imágenes con formato OpenAI. **Verifica** el nombre exacto del modelo y la disponibilidad en la [documentación oficial de DeepSeek](https://api-docs.deepseek.com/). Servidores en China: valora la privacidad de datos médicos. |
| **OpenAI** | Barato | `gpt-4.1-mini` u otro modelo mini con visión. Requiere cuenta y saldo. |
| **Gemini** | Muy barato / capa gratuita | Endpoint de compatibilidad OpenAI. **Ojo:** en la capa gratuita Google puede usar los datos para mejorar sus productos. No recomendado para informes médicos sin plan de pago. |

> **Por qué no Ollama como default:** "gratis" solo si hay un servidor propio encendido 24/7 al que el móvil pueda llegar. Para un MVP con usuarios reales, Haiku cuesta céntimos al mes y no requiere infraestructura.

---

## 3. Configuración (lo que tienes que hacer)

### Opción A — Claude (default): **no hay que hacer nada**

Si `lib/config/secrets.dart` ya tiene `claudeApiKey` (Funcionalidad 4.4), la función funciona tal cual:

```bash
flutter run
```

Si aún no la tienes:
1. Crea una cuenta en https://console.anthropic.com
2. Añade saldo (con 5 USD hay para miles de fotos)
3. Crea una API key en https://console.anthropic.com/settings/keys
4. Pégala en `lib/config/secrets.dart`:
   ```dart
   static const String claudeApiKey = 'sk-ant-...';
   ```

### Opción B — Otro proveedor (OpenAI, DeepSeek, Gemini, Ollama)

1. Copia el ejemplo (el archivo real está en `.gitignore`):
   ```bash
   cp vision.env.example.json vision.env.json
   ```
2. Edita `vision.env.json`:

   **OpenAI**
   ```json
   {
     "VISION_PROVIDER": "openai_compatible",
     "VISION_BASE_URL": "https://api.openai.com/v1",
     "VISION_MODEL": "gpt-4.1-mini",
     "VISION_API_KEY": "sk-..."
   }
   ```

   **DeepSeek** (verifica el nombre del modelo en su documentación)
   ```json
   {
     "VISION_PROVIDER": "openai_compatible",
     "VISION_BASE_URL": "https://api.deepseek.com/v1",
     "VISION_MODEL": "<modelo-con-vision>",
     "VISION_API_KEY": "sk-..."
   }
   ```

   **Gemini**
   ```json
   {
     "VISION_PROVIDER": "openai_compatible",
     "VISION_BASE_URL": "https://generativelanguage.googleapis.com/v1beta/openai",
     "VISION_MODEL": "<modelo-flash>",
     "VISION_API_KEY": "AIza..."
   }
   ```

   **Ollama local** (sin API key)
   ```json
   {
     "VISION_PROVIDER": "openai_compatible",
     "VISION_BASE_URL": "http://192.168.1.50:11434/v1",
     "VISION_MODEL": "qwen2.5vl"
   }
   ```
3. Ejecuta con:
   ```bash
   flutter run --dart-define-from-file=vision.env.json
   ```

#### Notas para Ollama
- En el ordenador: `ollama pull qwen2.5vl` y arranca con `OLLAMA_HOST=0.0.0.0 ollama serve` para que el móvil pueda conectarse.
- Usa la IP LAN del ordenador (`ipconfig getifaddr en0` en macOS). Desde el **emulador** Android usa `http://10.0.2.2:11434/v1`.
- Android bloquea HTTP sin TLS por defecto. Para pruebas locales hay que permitir tráfico *cleartext* solo hacia esa IP con un `network_security_config.xml` de debug. **No** se ha activado en este PR para no relajar la seguridad de la app.

### Variables disponibles

| Variable | Default | Descripción |
|---|---|---|
| `VISION_PROVIDER` | `anthropic` | `anthropic` u `openai_compatible` |
| `VISION_MODEL` | `claude-haiku-5-5` (anthropic) | Modelo a usar. Obligatorio para `openai_compatible`. |
| `VISION_BASE_URL` | `https://api.openai.com/v1` | Solo `openai_compatible` |
| `VISION_API_KEY` | — | Solo `openai_compatible` (no necesaria para IPs locales) |
| `IMAGE_READER_DWELL_MS` | `2000` | Milisegundos en una foto antes de leerla |

Otros parámetros (tamaño de imagen enviado, timeout, tokens de salida) están en `lib/config/image_reader_config.dart`.

---

## 4. Arquitectura

```
VoiceCommandScreen ──(botón "Leer mis fotos" / comando de voz)──► ImageReaderScreen
                                                                    │
                                                         ImageReaderProvider (ChangeNotifier, scoped a la pantalla)
                                                         ├─ GalleryService ──► PhotoManagerGalleryService (photo_manager)
                                                         ├─ VisionService  ──► VisionServiceFactory
                                                         │                     ├─ AnthropicVisionService (default)
                                                         │                     └─ OpenAICompatibleVisionService
                                                         └─ TTSService (flutter_tts, ya existente)
```

| Archivo | Responsabilidad |
|---|---|
| `lib/config/image_reader_config.dart` | Configuración no secreta + lectura de `--dart-define` |
| `lib/prompts/image_reader_prompt.dart` | Prompt único para todos los proveedores (tipos de imagen, reglas de lectura, formato JSON) |
| `lib/models/image_description.dart` | `ImageKind` + parser robusto de la respuesta (JSON, JSON en ```` ``` ````, o texto plano) |
| `lib/services/vision/vision_service.dart` | Interfaz + mapeo de errores HTTP → `AppError` |
| `lib/services/vision/implementations/*` | Clientes Claude y OpenAI-compatible (paquete `http`, ya en el proyecto) |
| `lib/services/gallery_service.dart` | Permisos + carga paginada + JPEG reescalado (1568px) |
| `lib/providers/image_reader_provider.dart` | Dwell timer, caché, estados, coordinación TTS, paginación |
| `lib/screens/image_reader_screen.dart` | UI accesible a pantalla completa |

**Imagen enviada a la IA:** JPEG ~1568px en el lado mayor, calidad 85. Suficiente para leer texto pequeño de informes y mantiene el coste bajo.

**Permisos Android** (`AndroidManifest.xml`): `READ_MEDIA_IMAGES` (13+), `READ_EXTERNAL_STORAGE` (≤12), `READ_MEDIA_VISUAL_USER_SELECTED` (acceso parcial en 14+, se activa al subir `targetSdk` a 34).

**Errores nuevos** (`ErrorCodes`): `VISION_API_KEY_MISSING`, `VISION_REQUEST_FAILED`, `VISION_EMPTY_RESPONSE`, `GALLERY_PERMISSION_DENIED`, `GALLERY_LOAD_FAILED`, con mensajes accesibles en `ErrorMessages`.

---

## 5. Privacidad (importante para Google Play)

- Las fotos **solo** se envían a la IA cuando el usuario se detiene en una foto dentro de esta pantalla. No hay envío en segundo plano.
- No se guarda nada en disco ni en Firebase: las descripciones viven en memoria y se borran al salir de la pantalla.
- La declaración de privacidad de la app debe **actualizarse**: hoy dice *"NO recopilamos datos. Todo es local"*, y esta función envía la foto a un proveedor externo (Anthropic por defecto) para interpretarla. Propuesta de texto:

  > *"Cuando usas 'Leer mis fotos', la foto que estás viendo se envía de forma segura a un servicio de inteligencia artificial (Anthropic) solo para describirla en voz alta. No guardamos tus fotos ni sus descripciones."*

- El prompt prohíbe diagnósticos o consejos médicos e identifica a personas reales; siempre recuerda consultar con el médico.

---

## 6. Fase 2 (siguiente PR): preguntar sobre la foto

Diseño propuesto, compatible con lo implementado:

1. **UI:** botón *"Preguntar"* (press-and-hold, igual que en `VoiceCommandScreen`) en el panel de la foto.
2. **STT:** reutilizar `ElevenLabsService` para transcribir la pregunta.
3. **Servicio:** añadir a `VisionService`:
   ```dart
   Future<String> askAboutImage(
     Uint8List jpegBytes,
     List<ImageChatTurn> history, // descripción inicial + preguntas previas
     String question,
   );
   ```
   Ambas implementaciones ya envían `messages`; solo hay que añadir los turnos previos.
4. **Provider:** guardar historial por foto (`Map<String, List<ImageChatTurn>>`) junto a la caché actual.
5. **Coste:** usar prompt caching de Anthropic para la imagen repetida en preguntas sucesivas.

Otras mejoras candidatas: zoom con pellizco (`InteractiveViewer`), filtrar solo capturas de pantalla (álbum *Screenshots*), compartir la descripción por WhatsApp con un familiar.

---

## 7. Tests

| Test | Cubre |
|---|---|
| `test/models/image_description_test.dart` | Parseo JSON / fences / texto plano / limpieza markdown |
| `test/services/vision/anthropic_vision_service_test.dart` | Request (base64, modelo, prompt), errores 401/429/500, key ausente |
| `test/services/vision/openai_compatible_vision_service_test.dart` | URL, Bearer, data URL, Ollama sin key, errores |
| `test/providers/image_reader_provider_test.dart` | Permisos, dwell, cancelación al deslizar, caché, respuesta tardía, sin reintentos automáticos, pausa por error de configuración, paginación, dispose |
| `test/screens/image_reader_screen_test.dart` | Render, botones ≥80dp, lectura tras dwell, navegación, ocultar texto, permiso denegado |
| `test/utils/nlp_parser_test.dart` | Comando de voz `openImageReader` |

Casos manuales con TalkBack: [`manual-test-cases/FUNCIONALIDAD_6.4_LECTOR_FOTOS.md`](./manual-test-cases/FUNCIONALIDAD_6.4_LECTOR_FOTOS.md)
