# BACKLOG - App de Accesibilidad para Adultos Mayores

**Fecha de creación:** 24 dic 2025
**Versión:** 1.0
**Sprint objetivo:** MVP (Semanas 1-6)

---

## ESPECIFICACIÓN DE FUNCIONALIDADES MVP

### FUNCIONALIDAD 1: Setup del Proyecto Flutter

#### Historia de Usuario
```
Como desarrollador del proyecto
Quiero tener una estructura base de Flutter correctamente configurada con todas las dependencias necesarias
Para poder desarrollar las funcionalidades del MVP de forma eficiente y mantenible
```

#### Criterios de Aceptación Funcional
- [ ] El proyecto Flutter compila sin errores en Android 7.0+
- [ ] La estructura de carpetas sigue la convención definida en CLAUDE.md
- [ ] Firebase está configurado y conectado correctamente (Firestore + FCM)
- [ ] Todas las dependencias base están instaladas y funcionando
- [ ] La app puede ejecutarse en emulador y dispositivo físico
- [ ] El estado de la aplicación se gestiona correctamente con Provider

#### Criterios de Aceptación Técnico
- [ ] Flutter SDK versión 3.19 o superior instalado
- [ ] Dart versión 3.0 o superior
- [ ] minSdkVersion = 24 (Android 7.0) en build.gradle
- [ ] targetSdkVersion = 34 (Android 14)
- [ ] Dependencias instaladas según pubspec.yaml:
  - provider: ^6.1.1
  - flutter_webrtc: ^0.9.48
  - flutter_accessibility_service: ^3.0.0
  - http: ^1.1.0
  - dio: ^5.4.0
  - web_socket_channel: ^2.4.0
  - hive: ^2.2.3
  - permission_handler: ^11.1.0
- [ ] Firebase configurado con google-services.json (gitignored)
- [ ] Archivo secrets.dart creado desde secrets.example.dart (gitignored)
- [ ] .gitignore actualizado para proteger secrets y credenciales
- [ ] Hot reload funciona correctamente

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si Firebase no está configurado correctamente?
  - Mostrar error claro indicando configuración faltante
  - Proveer link a documentación de Firebase setup
- ¿Qué pasa si las dependencias tienen conflictos de versión?
  - Documentar versiones exactas que funcionan
  - Usar dependency_overrides si es necesario
- ¿Qué pasa si el dispositivo tiene Android <7.0?
  - Mostrar mensaje claro: "Requiere Android 7.0 o superior"
  - No permitir instalación en Play Store para versiones antiguas

#### Dependencias Técnicas
- **Permisos requeridos:** Ninguno (solo setup base)
- **APIs/SDKs necesarios:**
  - Flutter SDK 3.19+
  - Android SDK API 24+
  - Firebase SDK (Firestore, FCM)
- **Servicios de terceros:**
  - Firebase (cuenta configurada)
  - Cuenta Google para Firebase Console

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [x] En pruebas
- [ ] Listo

---

### FUNCIONALIDAD 2: WebRTC + Firebase para Control Remoto

#### Historia de Usuario
```
Como familiar de una persona con baja visión
Quiero conectarme remotamente al dispositivo de mi familiar usando un código simple de sesión
Para poder ver su pantalla y ayudarle a resolver problemas sin estar físicamente presente
```

#### Criterios de Aceptación Funcional
- [ ] El usuario (adulto mayor) puede generar un código de sesión de 4-6 dígitos desde la app
- [ ] El familiar puede ingresar el código desde su dispositivo y conectarse en <30 segundos
- [ ] La pantalla del adulto mayor se transmite en tiempo real con latencia <2 segundos en WiFi
- [ ] El familiar puede tocar elementos en la pantalla y estos toques se ejecutan en el dispositivo remoto
- [ ] El código de sesión es visible con texto grande (mínimo 48sp) y alto contraste
- [ ] La sesión se anuncia audiblemente: "Sesión remota iniciada. Código: [números]"
- [ ] Existe timeout automático de seguridad (15 minutos sin actividad)
- [ ] El usuario puede cancelar la sesión remota en cualquier momento con botón grande
- [ ] Indicadores visuales claros del estado de conexión (conectando, conectado, desconectado)

#### Criterios de Aceptación Técnico
- [ ] Implementado usando flutter_webrtc package versión 0.9.48+
- [ ] Signaling server implementado con Firebase Firestore
- [ ] STUN servers configurados (stun:stun.l.google.com:19302)
- [ ] Screen capture usando MediaProjection API (Android) vía Platform Channel
- [ ] Control remoto implementado con AccessibilityService.dispatchGesture()
- [ ] Códigos de sesión generados aleatoriamente (6 dígitos, sin ambigüedades: sin O/0, I/1)
- [ ] Sesiones almacenadas en Firestore con TTL de 15 minutos
- [ ] Transmisión de video en resolución adaptativa (360p-720p según ancho de banda)
- [ ] Encriptación DTLS-SRTP habilitada por defecto en WebRTC
- [ ] Manejo de reconexión automática ante pérdida temporal de red (<10 segundos)
- [ ] Logs estructurados para debugging de conexiones

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si no hay conexión a internet?
  - Mostrar error claro: "No hay conexión a internet. Conéctate a WiFi o datos móviles"
  - Anunciar error con TTS
  - Deshabilitar botón de iniciar sesión remota
- ¿Qué pasa si el usuario niega permiso de captura de pantalla?
  - Mostrar tutorial visual paso a paso
  - Explicar con TTS: "Para compartir tu pantalla, necesito permiso. Te llevaré a la configuración"
  - Proveer botón para abrir configuración nuevamente
- ¿Qué pasa si el código de sesión es inválido o expiró?
  - Mensaje claro: "El código no es válido o expiró. Solicita un nuevo código"
  - Permitir reintentar inmediatamente
- ¿Qué pasa si la conexión se cae durante la sesión?
  - Intentar reconectar automáticamente (máximo 3 intentos en 30 segundos)
  - Notificar al usuario: "Conexión perdida. Reintentando..."
  - Si falla: "Sesión terminada. Genera un nuevo código si necesitas ayuda"
- ¿Qué pasa si el dispositivo está en red 3G/4G con ancho de banda limitado?
  - Reducir calidad de video automáticamente
  - Mostrar advertencia: "Conexión lenta. La calidad de video puede ser baja"

#### Dependencias Técnicas
- **Permisos requeridos:**
  - android.permission.INTERNET
  - android.permission.RECORD_AUDIO (para futuro audio bidireccional)
  - android.permission.FOREGROUND_SERVICE
  - Permiso de captura de pantalla (MediaProjection)
  - Permiso de AccessibilityService (para control remoto)
- **APIs/SDKs necesarios:**
  - flutter_webrtc: ^0.9.48
  - Firebase Firestore SDK
  - MediaProjection API (Android)
  - AccessibilityService API (Android)
- **Servicios de terceros:**
  - Firebase Firestore (signaling)
  - STUN servers (Google públicos)

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

---

### FUNCIONALIDAD 3: Interfaz Accesible Básica

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero una interfaz con botones grandes, texto legible y navegable solo con TalkBack
Para poder usar la aplicación de forma independiente sin necesidad de ver claramente la pantalla
```

#### Criterios de Aceptación Funcional
- [ ] Todos los botones tienen altura mínima de 80dp
- [ ] Todo el texto tiene tamaño mínimo de 24sp
- [ ] El contraste entre texto y fondo cumple WCAG 2.1 nivel AA (mínimo 4.5:1)
- [ ] Modo de alto contraste configurable desde la pantalla de inicio
- [ ] Navegación completa posible usando solo TalkBack (sin mirar pantalla)
- [ ] Cada elemento interactivo tiene Semantics con label y hint descriptivos
- [ ] Los botones se anuncian correctamente con TalkBack (rol de "botón")
- [ ] El espacio entre elementos táctiles es mínimo 16dp
- [ ] No hay dependencia de color únicamente para comunicar información
- [ ] Todos los íconos tienen etiquetas de texto descriptivas
- [ ] La app pasa Android Accessibility Scanner sin warnings críticos
- [ ] Timeouts de al menos 30 segundos para acciones que requieren confirmación

#### Criterios de Aceptación Técnico
- [ ] Implementado usando Material Design 3 con ColorScheme.highContrastLight()
- [ ] Todos los widgets interactivos envueltos en Semantics
- [ ] Tamaño de botones: minimumSize: Size(200, 80) en ElevatedButton.styleFrom()
- [ ] TextStyle con fontSize mínimo de 24.0
- [ ] Contraste configurado en ThemeData.colorScheme
- [ ] Orden de foco configurado con OrdinalSortKey donde sea necesario
- [ ] Animaciones respetan MediaQuery.disableAnimations
- [ ] Probado con `flutter run --analyze-accessibility`
- [ ] Compatible con gestos de TalkBack:
  - Swipe derecha/izquierda: navegación entre elementos
  - Doble tap: activar elemento
  - Dos dedos swipe up: scroll hacia arriba
- [ ] Pantallas principales:
  - home_screen.dart: Menú principal con botones grandes
  - remote_control_screen.dart: Código de sesión grande + botón cancelar
  - voice_command_screen.dart: Botón micrófono grande + feedback visual
  - whatsapp_screen.dart: Lista de contactos frecuentes

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si TalkBack no está activado?
  - Mostrar tutorial al primer inicio: "Para mejor experiencia, activa TalkBack"
  - Proveer botón directo a configuración de accesibilidad
- ¿Qué pasa si el usuario tiene configurado texto del sistema extra grande?
  - La UI debe adaptarse sin romper layout
  - Testar con scaling 2.0x en configuración Android
- ¿Qué pasa si el dispositivo tiene pantalla muy pequeña (<5 pulgadas)?
  - Permitir scroll vertical en todas las pantallas
  - Mantener tamaños mínimos (no reducir botones)
- ¿Qué pasa si el usuario toca accidentalmente botones adyacentes?
  - Espacio mínimo 16dp reduce probabilidad
  - Confirmación para acciones críticas (ej: cancelar sesión remota)

#### Dependencias Técnicas
- **Permisos requeridos:** Ninguno específico (UI base)
- **APIs/SDKs necesarios:**
  - Flutter Material Design 3
  - Flutter Semantics API
  - Android TalkBack (del sistema)
- **Servicios de terceros:**
  - Android Accessibility Scanner (para testing)

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

---

### FUNCIONALIDAD 4: Integración ElevenLabs STT/TTS Básica

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero dar comandos de voz y recibir respuestas audibles
Para interactuar con la aplicación sin necesidad de leer texto en pantalla
```

#### Criterios de Aceptación Funcional
- [ ] El usuario puede presionar botón de micrófono grande y dar comando de voz
- [ ] El comando es reconocido en <2 segundos con latencia de 150-500ms
- [ ] La transcripción del comando se muestra en pantalla (texto grande, 28sp)
- [ ] Feedback audible confirma cada acción ejecutada (ej: "Abriendo WhatsApp")
- [ ] Si ElevenLabs falla, el sistema hace fallback automático a Android SpeechRecognizer
- [ ] Indicador visual claro cuando está escuchando (animación de micrófono)
- [ ] El usuario puede cancelar grabación con botón o "cancelar" por voz
- [ ] Los mensajes de voz son claros, cortos (máximo 2 oraciones) y en lenguaje simple
- [ ] Reconoce comandos básicos para MVP:
  - "Solicitar ayuda" / "Necesito ayuda" → Genera código sesión remota
  - "Abrir WhatsApp" → Abre WhatsApp
  - "Alto contraste" / "Activar alto contraste" → Cambia tema
- [ ] Manejo de errores se anuncia en voz: "No te escuché bien. Intenta de nuevo"

#### Criterios de Aceptación Técnico
- [ ] Implementado con ElevenLabs Scribe v2 (WebSocket API) como STT principal
- [ ] ElevenLabs TTS (REST API) para síntesis de voz
- [ ] Fallback a Android SpeechRecognizer cuando:
  - ElevenLabs API retorna error 429 (límite excedido)
  - No hay conexión a internet
  - API key inválida o expirada
- [ ] API key almacenada en secrets.dart (gitignored)
- [ ] WebSocket connection a wss://api.elevenlabs.io/v1/speech-to-text/realtime
- [ ] Voice ID configurado en constants.dart
- [ ] Audio del micrófono capturado con permission RECORD_AUDIO
- [ ] Parser NLP simple (utils/nlp_parser.dart) para extraer intención y parámetros
- [ ] Audio TTS reproducido con audioplayers package
- [ ] Timeout de escucha: 10 segundos sin hablar → auto cancelar
- [ ] Logging de errores de API para debugging

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si no hay conexión a internet?
  - Usar Android SpeechRecognizer como fallback automático
  - Mostrar advertencia: "Modo sin conexión. Reconocimiento de voz básico activado"
- ¿Qué pasa si el usuario niega permiso de micrófono?
  - Tutorial visual mostrando cómo otorgar permiso
  - TTS: "Para usar comandos de voz, necesito permiso del micrófono"
  - Botón directo a configuración de permisos
- ¿Qué pasa si ElevenLabs retorna límite excedido (429)?
  - Fallback automático a Android SpeechRecognizer
  - Logging del evento para monitoreo
  - No mostrar error al usuario (transición transparente)
- ¿Qué pasa si el comando no se entiende?
  - TTS: "No entendí el comando. Intenta decir: solicitar ayuda, abrir WhatsApp"
  - Mostrar lista de comandos disponibles en pantalla
- ¿Qué pasa si hay mucho ruido ambiental?
  - Intentar procesar de todas formas (ElevenLabs es robusto)
  - Si falla múltiples veces: "Hay mucho ruido. Acércate más al micrófono"
- ¿Qué pasa si el usuario habla otro idioma o con acento fuerte?
  - ElevenLabs soporta español con buenos acentos
  - Si falla consistentemente: sugerir modo botones en vez de voz

#### Dependencias Técnicas
- **Permisos requeridos:**
  - android.permission.RECORD_AUDIO
  - android.permission.INTERNET
- **APIs/SDKs necesarios:**
  - ElevenLabs Scribe v2 API (WebSocket)
  - ElevenLabs TTS API (REST)
  - web_socket_channel: ^2.4.0
  - http: ^1.1.0 o dio: ^5.4.0
  - audioplayers package
  - Android SpeechRecognizer (fallback)
- **Servicios de terceros:**
  - ElevenLabs API (requiere API key válida)
  - Verificar límites de suscripción actual

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

---

### FUNCIONALIDAD 5: WhatsApp Básico mediante Deep Links

#### Historia de Usuario
```
Como adulto mayor con baja visión
Quiero abrir WhatsApp y opcionalmente abrir un chat específico mediante comando de voz o botón
Para comunicarme con mis contactos sin necesidad de buscar en la aplicación
```

#### Criterios de Aceptación Funcional
- [ ] El usuario puede abrir WhatsApp presionando botón grande o diciendo "Abrir WhatsApp"
- [ ] Lista de contactos frecuentes (configurables) con botones grandes (80dp altura)
- [ ] Al presionar contacto, se abre WhatsApp en el chat específico (si tiene número guardado)
- [ ] Si WhatsApp no está instalado, muestra mensaje claro: "WhatsApp no está instalado"
- [ ] Feedback audible confirma acción: "Abriendo WhatsApp de María"
- [ ] Si no hay número guardado para contacto, solo abre WhatsApp (sin chat específico)
- [ ] El familiar puede ayudar remotamente a configurar contactos frecuentes
- [ ] Comandos de voz reconocidos:
  - "Abrir WhatsApp" → Abre la app
  - "Abrir WhatsApp de [nombre]" → Abre chat si tiene número guardado
- [ ] Máximo 6-8 contactos frecuentes visibles (scroll si hay más)

#### Criterios de Aceptación Técnico
- [ ] Implementado usando deep links de WhatsApp: whatsapp:// y wa.me/
- [ ] NO requiere AccessibilityService (reservado para v1.0)
- [ ] Lista de contactos almacenada localmente en Hive
- [ ] Estructura de datos: Map<String, String> → {"María": "+521234567890"}
- [ ] Intent de Android para abrir WhatsApp:
  - General: Intent(Intent.ACTION_VIEW, Uri.parse("whatsapp://"))
  - Chat específico: Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/$phoneNumber"))
- [ ] Validación de formato de número telefónico (incluye código de país)
- [ ] Platform Channel: whatsAppService.openApp() y openChat(phoneNumber)
- [ ] Detección de instalación de WhatsApp vía PackageManager
- [ ] UI de configuración de contactos con formulario accesible:
  - Campo nombre (Semantics label)
  - Campo número con teclado numérico
  - Validación en tiempo real
- [ ] Parser NLP extrae nombre de contacto del comando de voz

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si WhatsApp no está instalado?
  - Verificar con PackageManager antes de intentar abrir
  - Mensaje claro: "WhatsApp no está instalado. ¿Quieres instalarlo?"
  - Botón directo a Google Play Store
  - TTS: "WhatsApp no encontrado en tu dispositivo"
- ¿Qué pasa si el número telefónico no tiene código de país?
  - Agregar código de país por defecto (configurable: ej. +52 para México)
  - Mostrar advertencia si el formato parece incorrecto
- ¿Qué pasa si el contacto dice un nombre que no está en la lista?
  - TTS: "No encontré contacto llamado [nombre]. ¿Quieres agregarlo?"
  - Mostrar lista de contactos disponibles
- ¿Qué pasa si el usuario no tiene contactos configurados?
  - Tutorial inicial: "Configura tus contactos frecuentes para acceso rápido"
  - Permitir que el familiar configure remotamente via control remoto
  - Botón grande "Agregar contacto" en pantalla WhatsApp
- ¿Qué pasa si WhatsApp está bloqueado o crashea?
  - Error manejado por Android (fuera de nuestro control)
  - Si Intent falla: "No se pudo abrir WhatsApp. Intenta de nuevo"

#### Dependencias Técnicas
- **Permisos requeridos:** Ninguno específico (solo Intents)
- **APIs/SDKs necesarios:**
  - Android Intent API
  - Android PackageManager
  - Hive (base de datos local): ^2.2.3
  - WhatsApp deep links (documentación: https://faq.whatsapp.com/general/chats/how-to-use-click-to-chat)
- **Servicios de terceros:**
  - WhatsApp instalado en el dispositivo (validación requerida)

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

---

### FUNCIONALIDAD 6: Gestión de Permisos

#### Historia de Usuario
```
Como adulto mayor con poca experiencia técnica
Quiero un tutorial visual paso a paso que me guíe para otorgar los permisos necesarios
Para poder usar todas las funcionalidades sin sentirme perdido en configuraciones complicadas
```

#### Criterios de Aceptación Funcional
- [ ] Al primer inicio, tutorial muestra permisos necesarios uno por uno (no todos juntos)
- [ ] Cada pantalla del tutorial tiene:
  - Explicación simple de POR QUÉ se necesita el permiso (máximo 2 oraciones)
  - Captura de pantalla mostrando DÓNDE tocar
  - Botón grande "Continuar" para ir al siguiente paso
  - Explicación audible con TTS
- [ ] Permisos solicitados en orden:
  1. Micrófono (para comandos de voz)
  2. Accesibilidad (para control remoto y screen sharing)
  3. Captura de pantalla (para sesión remota)
- [ ] La app detecta si el permiso ya fue otorgado y lo salta
- [ ] Si el usuario rechaza un permiso, explica las limitaciones:
  - "Sin micrófono: No podrás usar comandos de voz, pero botones sí funcionan"
- [ ] Botón "Reconfigurar permisos" disponible en pantalla de configuración
- [ ] Tutorial puede saltarse (checkbox "No mostrar de nuevo"), pero con advertencia clara
- [ ] Validación antes de features críticas:
  - Antes de iniciar sesión remota: verificar permiso de Accessibility + Screen Capture
  - Antes de usar comandos de voz: verificar permiso de micrófono

#### Criterios de Aceptación Técnico
- [ ] Implementado usando permission_handler: ^11.1.0
- [ ] Permisos declarados en AndroidManifest.xml:
  - android.permission.RECORD_AUDIO
  - android.permission.INTERNET
  - android.permission.FOREGROUND_SERVICE
  - android.permission.BIND_ACCESSIBILITY_SERVICE
- [ ] Lógica de validación:
  ```dart
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return true;
  }
  ```
- [ ] Para AccessibilityService (no manejable por permission_handler):
  - Detectar con AccessibilityService.isAccessibilityPermissionEnabled()
  - Abrir configuración con openAccessibilitySettings()
  - Polling cada 2 segundos para detectar cuando se otorgue
- [ ] Tutorial implementado como PageView con 3-4 pantallas
- [ ] Capturas de pantalla incluidas en assets/:
  - assets/tutorials/accessibility_step1.png
  - assets/tutorials/accessibility_step2.png
  - assets/tutorials/screen_capture.png
- [ ] Estado del tutorial almacenado en Hive (no mostrar de nuevo si completado)
- [ ] Deeplinks a configuraciones Android:
  - Settings.ACTION_ACCESSIBILITY_SETTINGS
  - Settings.ACTION_APPLICATION_DETAILS_SETTINGS

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si el usuario rechaza permanentemente un permiso?
  - Detectar con status.isPermanentlyDenied
  - Botón directo a configuración de la app en Android
  - TTS: "Ve a configuración de la app y activa el permiso manualmente"
- ¿Qué pasa si el fabricante (Xiaomi, Huawei) tiene configuraciones extra?
  - Documentar pasos específicos por fabricante en tutorial
  - Detectar fabricante con Build.MANUFACTURER
  - Mostrar instrucciones adicionales: "En Xiaomi, también activa 'Inicio automático'"
- ¿Qué pasa si el usuario sale del tutorial a mitad?
  - Guardar progreso (qué permisos ya se configuraron)
  - Al volver, reanudar desde último paso pendiente
- ¿Qué pasa si Android niega el permiso (política del sistema)?
  - Mostrar mensaje técnico: "El sistema no permite este permiso"
  - Ofrecer alternativas (ej: usar solo botones sin voz)
- ¿Qué pasa si el usuario no entiende las instrucciones?
  - Botón "Ayuda remota" que genera código para que familiar ayude

#### Dependencias Técnicas
- **Permisos requeridos:**
  - android.permission.RECORD_AUDIO
  - android.permission.INTERNET
  - android.permission.FOREGROUND_SERVICE
  - android.permission.BIND_ACCESSIBILITY_SERVICE (especial)
  - Permiso de captura de pantalla (MediaProjection, solicitado en runtime)
- **APIs/SDKs necesarios:**
  - permission_handler: ^11.1.0
  - Android Settings API (para abrir configuraciones)
  - flutter_accessibility_service (para validar AccessibilityService)
- **Servicios de terceros:** Ninguno

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

---

## MATRIZ DE PRIORIDADES

| Funcionalidad | Impacto Usuario | Complejidad Técnica | Prioridad | Semanas Estimadas |
|--------------|-----------------|---------------------|-----------|-------------------|
| **Setup del Proyecto Flutter** | Crítico (base para todo) | Media | **P0** | 1 |
| **Interfaz Accesible Básica** | Muy Alto (usabilidad core) | Baja-Media | **P0** | 1-2 |
| **Gestión de Permisos** | Muy Alto (sin permisos nada funciona) | Media | **P0** | 1 |
| **ElevenLabs STT/TTS** | Alto (accesibilidad clave) | Media | **P1** | 1-2 |
| **WhatsApp Deep Links** | Medio (funcionalidad básica) | Baja | **P1** | 0.5-1 |
| **WebRTC Control Remoto** | **Crítico (MVP core value)** | **Muy Alta** | **P0** | 2-3 |

### Notas de Priorización

**P0 (Críticas - Semanas 1-4):**
1. **Setup del Proyecto** (Semana 1): Sin esto, nada funciona
2. **Interfaz Accesible** (Semana 1-2): Define UX de toda la app
3. **Gestión de Permisos** (Semana 2): Bloquea control remoto si no se configura bien
4. **WebRTC Control Remoto** (Semana 3-4): **Valor principal del MVP** - Desbloquea ayuda familiar remota

**P1 (Importantes - Semanas 4-6):**
5. **ElevenLabs STT/TTS** (Semana 5): Mejora accesibilidad significativamente
6. **WhatsApp Deep Links** (Semana 5-6): Complemento útil, puede ser ayudado remotamente

### Dependencias entre Funcionalidades

```
Setup del Proyecto (S1)
    ↓
    ├─→ Interfaz Accesible (S1-2)
    │       ↓
    │   Gestión de Permisos (S2)
    │       ↓
    │   WebRTC Control Remoto (S3-4) ← VALOR CORE MVP
    │
    └─→ ElevenLabs STT/TTS (S5)
            ↓
        WhatsApp Deep Links (S5-6)
```

---

## CRITERIOS DE ÉXITO DEL MVP

### Técnicos
- [ ] 100% funcionalidades P0 completadas y testeadas
- [ ] App compila sin errores ni warnings críticos
- [ ] `flutter analyze` pasa sin issues
- [ ] Android Accessibility Scanner: 0 warnings críticos
- [ ] Latencia control remoto <2 segundos en WiFi
- [ ] 95%+ comandos de voz reconocidos (ambiente con ruido moderado)

### UX / Accesibilidad
- [ ] Navegación completa posible solo con TalkBack (usuario no necesita ver pantalla)
- [ ] Usuario puede generar código de sesión remota en <10 segundos sin ayuda
- [ ] Familiar puede conectarse remotamente en <30 segundos
- [ ] Tutorial de permisos completable por adulto mayor con experiencia técnica limitada
- [ ] Todos los mensajes de error son comprensibles (lenguaje simple, sin jerga técnica)

### Testing con Usuario Real
- [ ] Sesión de testing con usuario objetivo (60+ años, baja visión)
- [ ] Usuario puede solicitar ayuda remota sin asistencia
- [ ] Familiar puede resolver problema real mediante control remoto
- [ ] Feedback documentado y priorizado para v1.0

---

## DEFINICIÓN DE "LISTO" (Definition of Done)

Para que una funcionalidad se considere **LISTO**, debe cumplir:

### Código
- [ ] Código implementado según convenciones de CLAUDE.md
- [ ] Indentación correcta (2 espacios Dart, 4 espacios Kotlin)
- [ ] Nombres de variables/funciones siguen convenciones (camelCase, PascalCase)
- [ ] Sin código comentado ni TODOs sin resolver
- [ ] Logs agregados en puntos clave (Platform Channels, APIs externas)

### Testing
- [ ] Testeado manualmente en dispositivo físico (no solo emulador)
- [ ] Probado con TalkBack activado
- [ ] `flutter run --analyze-accessibility` ejecutado sin warnings críticos
- [ ] Casos de error principales validados (sin conexión, permisos denegados, etc.)

### Accesibilidad
- [ ] Todos los widgets interactivos tienen `Semantics`
- [ ] Botones tienen altura mínima 80dp
- [ ] Texto tiene tamaño mínimo 24sp
- [ ] Contraste cumple WCAG 2.1 nivel AA
- [ ] Navegable completamente con TalkBack

### Documentación
- [ ] Comentarios en código complejo (especialmente Platform Channels)
- [ ] README actualizado si se agregaron dependencias nuevas
- [ ] Secrets documentados en secrets.example.dart

### Integración
- [ ] `git commit` incluye mensaje descriptivo
- [ ] Branch fusionado a main sin conflictos
- [ ] Build APK funciona: `flutter build apk --release`
- [ ] No se commitaron secrets (verificar .gitignore)

---

### FUNCIONALIDAD 7: Configuración de Release para Producción

#### Historia de Usuario
```
Como desarrollador del proyecto
Quiero tener configurada la firma de releases de Android
Para poder publicar la aplicación en Google Play Store de forma segura
```

#### Criterios de Aceptación Funcional
- [ ] Keystore generado y almacenado de forma segura
- [ ] Build de release firmado correctamente funciona
- [ ] APK release puede instalarse en dispositivos de producción
- [ ] Verificación de firma funciona correctamente
- [ ] Documentación completa del proceso de release

#### Criterios de Aceptación Técnico
- [ ] Keystore generado con `keytool` usando parámetros seguros:
  - Algoritmo: RSA
  - Tamaño de clave: 2048 bits
  - Validez: 10000 días (requerido por Google Play)
- [ ] `build.gradle` configurado con `signingConfigs.release`
- [ ] Variables de entorno configuradas en `.env`:
  - `LAMB_KEY_ALIAS`
  - `LAMB_KEY_PASSWORD`
  - `LAMB_KEYSTORE_PATH`
  - `LAMB_STORE_PASSWORD`
- [ ] `.gitignore` actualizado para proteger:
  - `*.jks`
  - `*.keystore`
  - `.env`
- [ ] Archivo `.env.example` creado con template
- [ ] README actualizado con proceso de release
- [ ] Build de release funciona: `flutter build apk --release`
- [ ] Verificación de firma: `jarsigner -verify -verbose -certs app-release.apk`

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si las variables de entorno no están configuradas?
  - Build falla con mensaje claro indicando variables faltantes
  - Mensaje apunta a README con instrucciones
- ¿Qué pasa si el keystore no existe o la ruta es incorrecta?
  - Build falla indicando que el keystore no se encuentra
  - Verificar que la ruta en `.env` es absoluta y correcta
- ¿Qué pasa si las contraseñas son incorrectas?
  - Build falla con error de autenticación
  - No revelar información de seguridad en logs
- ¿Qué pasa si se commitea el keystore accidentalmente?
  - Pre-commit hook debe prevenir commit de archivos sensibles
  - Documentar proceso de rotación de claves si ocurre

#### Dependencias Técnicas
- **Herramientas requeridas:**
  - `keytool` (incluido en JDK)
  - Android SDK Build Tools
- **Servicios de terceros:**
  - Google Play Console (para upload de APK)
- **Seguridad:**
  - Gestor de contraseñas para almacenar passwords del keystore
  - Backup seguro del keystore (si se pierde, no se puede actualizar la app en Play Store)

#### Documentación del Proceso

**Paso 1: Generar Keystore**
```bash
keytool -genkey -v \
  -keystore ~/lamb-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias lamb-key
```

**Paso 2: Crear archivo .env**
```bash
cp .env.example .env
# Editar .env con valores reales
```

**Paso 3: Configurar build.gradle**
```gradle
android {
    signingConfigs {
        release {
            keyAlias System.getenv("LAMB_KEY_ALIAS")
            keyPassword System.getenv("LAMB_KEY_PASSWORD")
            storeFile file(System.getenv("LAMB_KEYSTORE_PATH"))
            storePassword System.getenv("LAMB_STORE_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

**Paso 4: Build de Release**
```bash
# Cargar variables de entorno
export $(cat .env | xargs)

# Build APK de release
flutter build apk --release

# Verificar firma
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

#### Checklist de Seguridad
- [ ] Keystore almacenado fuera del repositorio git
- [ ] Keystore respaldado en ubicación segura (cloud encriptado, USB, etc.)
- [ ] Contraseñas almacenadas en gestor de contraseñas
- [ ] Variables de entorno nunca commiteadas
- [ ] `.gitignore` previene commit de archivos sensibles
- [ ] Documentación no contiene contraseñas reales
- [ ] Proceso de rotación de claves documentado

#### Estatus
- [ ] Por hacer
- [ ] En desarrollo
- [ ] En pruebas
- [ ] Listo

#### Prioridad
**P1 (Alta - Pre-Producción):** Debe completarse antes del lanzamiento en Google Play Store, pero no es bloqueante para desarrollo del MVP.

---

## BACKLOG FUTURO (Post-MVP - v1.0)

Estas funcionalidades están fuera del MVP pero documentadas para v1.0 (Semanas 7-12):

### FUNCIONALIDAD 8: AccessibilityService para WhatsApp Automation
- Automatización avanzada: abrir chat por nombre (no número), leer mensajes, enviar mensajes
- **Riesgo:** Muy frágil ante actualizaciones de WhatsApp
- **Prioridad v1.0:** P1 (importante pero no crítica, deep links cubren necesidad básica)

### FUNCIONALIDAD 9: Comandos de Voz Expandidos
- "Lee mis mensajes de [contacto]"
- "Envía mensaje a [contacto] diciendo [texto]"
- "¿Tengo mensajes nuevos?"
- "Llama a [contacto]"
- Parser NLP mejorado con contexto y sinónimos

### FUNCIONALIDAD 10: Notificaciones Inteligentes
- Listener de notificaciones de WhatsApp
- Anuncio automático de mensajes nuevos en voz alta
- Configuración de contactos VIP
- Control de frecuencia de anuncios

### FUNCIONALIDAD 11: Personalización de Accesibilidad
- Velocidad de voz TTS ajustable
- Modo ultra alto contraste
- Tamaño de botones ajustable (80-120dp)
- Temas de color predefinidos

---

## RIESGOS Y MITIGACIONES

### Riesgo 1: WebRTC más complejo de lo estimado (Probabilidad: Media, Impacto: Crítico)
**Señales de alerta:**
- No se logra establecer conexión P2P después de 1 semana de desarrollo
- Latencia >5 segundos consistentemente
- Errores de signaling no resueltos

**Mitigación:**
- Estudiar código de RustDesk como referencia (repositorio clonado)
- Semana 3 dedicada exclusivamente a WebRTC (sin multitasking)
- Plan B: Integrar RustDesk como app separada si desarrollo custom falla
- Buffer de 1 semana en cronograma (semana 6)

### Riesgo 2: Usuario no puede completar tutorial de permisos (Probabilidad: Alta, Impacto: Alto)
**Señales de alerta:**
- En testing, usuario se confunde en pantallas de configuración Android
- Usuario rechaza permisos por miedo/desconfianza

**Mitigación:**
- Tutorial con capturas de pantalla reales (no genéricas)
- Botón "Ayuda remota" en cada paso del tutorial
- Familiar puede configurar permisos mediante control remoto
- Video tutorial corto (TikTok/YouTube) como material complementario

### Riesgo 3: Límites de ElevenLabs excedidos (Probabilidad: Media, Impacto: Medio)
**Señales de alerta:**
- Errores 429 frecuentes en logs
- Usuario reporta que comandos de voz dejaron de funcionar

**Mitigación:**
- Fallback automático a Android SpeechRecognizer (ya implementado en diseño)
- Monitorear dashboard de ElevenLabs semanalmente
- Optimizar uso: solo comandos críticos usan ElevenLabs, resto usa SpeechRecognizer

### Riesgo 4: Rechazo en Google Play por AccessibilityService (Probabilidad: Baja, Impacto: Crítico)
**Señales de alerta:**
- App rechazada en primera submission
- Google solicita evidencia de uso legítimo

**Mitigación:**
- Video demo profesional mostrando uso real (adulto mayor + familiar)
- Declaración de privacidad detallada desde día 1
- Seguir exactamente políticas de Google Play (documentación leída)
- Plan B: Distribución directa de APK vía web (menor alcance)

---

## FUNCIONALIDAD 2.1: Cliente WebRTC para Control Remoto (App del Familiar)

### Fecha de planeación: 08 Enero 2026
### Prioridad: **P0 (Crítica - Requerida para completar MVP)**
### Estatus: Por iniciar

---

### Contexto

Durante las pruebas de la Funcionalidad 2 (TC-HP-001 a TC-HP-008), se validó exitosamente el lado del **host/servidor** (adulto mayor). Sin embargo, **no es posible probar la conexión WebRTC completa** sin el lado del **cliente** (familiar que se conecta).

La Funcionalidad 2.1 es **fundamental para el MVP** porque:
- ✅ Sin cliente, no podemos validar que WebRTC funciona end-to-end
- ✅ No podemos probar estados críticos: `connecting`, `connected`
- ✅ No podemos validar la transmisión de pantalla real
- ✅ No podemos probar el control táctil remoto
- ✅ No hay forma de hacer pruebas completas con usuarios reales

**Decisión:** Priorizar desarrollo del cliente inmediatamente después de validar el host.

---

### Historia de Usuario

```
Como familiar de una persona con baja visión
Quiero conectarme al dispositivo de mi familiar ingresando un código de 6 dígitos
Para poder ver su pantalla en tiempo real y ayudarle tocando elementos que él necesita activar
```

---

### Alcance del Cliente MVP

#### **Plataforma Inicial: Web App (PWA)**
**Justificación:**
- ✅ Desarrollo más rápido que app nativa (1 semana vs 2-3 semanas)
- ✅ No requiere instalación (el familiar solo abre un link)
- ✅ Funciona en cualquier dispositivo (Android, iOS, PC, Mac)
- ✅ Usa `flutter_webrtc` que ya soporta web
- ✅ Permite testing inmediato sin compilaciones

**Plan futuro:** App nativa Android/iOS en v2.2 (post-MVP)

---

### Criterios de Aceptación Funcional

#### **Pantalla 1: Ingresar Código de Sesión**
- [ ] Input numérico para código de 6 dígitos
- [ ] Botón "Conectar" grande y visible
- [ ] Validación: solo acepta 6 dígitos numéricos (2-9, sin 0/1)
- [ ] Mensaje de error claro si código inválido
- [ ] Loading indicator mientras se conecta

#### **Pantalla 2: Visualización de Pantalla Remota**
- [ ] Stream de video de la pantalla del adulto mayor se muestra en tiempo real
- [ ] Video ocupa toda la pantalla (fullscreen) o es maximizable
- [ ] Latencia < 2 segundos en WiFi
- [ ] Controles de sesión visibles: "Desconectar", "Pantalla completa"
- [ ] Indicador de estado de conexión: "Conectando...", "Conectado", "Desconectado"

#### **Funcionalidad de Control Táctil (MVP Básico)**
- [ ] Al tocar en la pantalla del cliente, se simula un tap en el dispositivo del host
- [ ] Coordenadas se escalan correctamente (resolución cliente → resolución host)
- [ ] Feedback visual: círculo temporal donde se tocó
- [ ] **Limitación MVP:** Solo taps simples (no gestos complejos, no scroll, no pinch-to-zoom)

#### **Manejo de Desconexión**
- [ ] Si host termina la sesión, cliente recibe notificación y vuelve a pantalla inicial
- [ ] Si conexión se pierde, muestra mensaje: "Conexión perdida. Reconectando..."
- [ ] Intenta reconectar automáticamente 3 veces antes de fallar
- [ ] Botón "Volver a intentar" si reconexión falla

---

### Criterios de Aceptación Técnico

#### **Stack Técnico**
- [ ] **Frontend:** Flutter Web (compile con `flutter build web`)
- [ ] **WebRTC:** `flutter_webrtc` v0.9.48+ (mismo que host)
- [ ] **Signaling:** Firebase Firestore (mismo backend que host)
- [ ] **Hosting:** Firebase Hosting (deploy con `firebase deploy`)
- [ ] **URL:** `https://lamb-remote.web.app` o similar

#### **Arquitectura**
```
lib/
├── main_web.dart                    # Entry point para web
├── screens/
│   ├── client_connect_screen.dart   # Pantalla 1: Ingresar código
│   └── client_viewer_screen.dart    # Pantalla 2: Ver pantalla remota
├── services/
│   └── webrtc_client_service.dart   # Cliente WebRTC
└── providers/
    └── remote_viewer_provider.dart  # State management del cliente
```

#### **Flujo de Conexión WebRTC**

**Cliente:**
1. Usuario ingresa código de 6 dígitos
2. Cliente busca sesión en Firestore: `remote_sessions/{sessionCode}`
3. Si existe y `status == 'waiting'`, obtiene el `offer` SDP del host
4. Cliente crea `RTCPeerConnection`
5. Cliente setea el `offer` como remote description
6. Cliente crea `answer` SDP
7. Cliente guarda `answer` en Firestore: `remote_sessions/{sessionCode}/answer`
8. Cliente escucha ICE candidates del host y los agrega
9. WebRTC establece conexión P2P
10. Cliente recibe el stream de video y lo renderiza

**Signaling (Firestore):**
```
remote_sessions/{sessionCode}/
  ├── offer: String (SDP del host)
  ├── answer: String (SDP del cliente)
  ├── status: 'waiting' | 'connecting' | 'connected' | 'ended'
  ├── hostIceCandidates: Array<IceCandidate>
  ├── clientIceCandidates: Array<IceCandidate>
  └── lastActivity: Timestamp
```

#### **Comunicación de Control Táctil**

**Canal de datos WebRTC:**
```dart
// Host crea data channel
RTCDataChannel dataChannel = await peerConnection.createDataChannel(
  'control',
  RTCDataChannelInit(),
);

// Cliente envía eventos táctiles
dataChannel.send(json.encode({
  'type': 'tap',
  'x': normalizedX,  // 0.0 - 1.0
  'y': normalizedY,  // 0.0 - 1.0
  'timestamp': DateTime.now().millisecondsSinceEpoch,
}));
```

**Host recibe y ejecuta:**
- Escala coordenadas normalizadas a píxeles de pantalla del host
- Usa `AccessibilityService.simulateTap()` (Kotlin) para simular el tap

---

### Casos de Uso Críticos (Testing)

#### **TC-CLIENT-001: Conectar con código válido (P0)**
**Pasos:**
1. Host inicia sesión remota (código: 234567)
2. Cliente abre web app
3. Cliente ingresa: 234567
4. Cliente presiona "Conectar"

**Resultado esperado:**
- ✅ Cliente muestra "Conectando..."
- ✅ En 5-10 segundos, aparece pantalla del host
- ✅ Host ve estado cambiar a "Conectado"
- ✅ Cliente puede ver la pantalla en tiempo real

#### **TC-CLIENT-002: Código inválido (P0)**
**Pasos:**
1. Cliente ingresa código que no existe: 999999
2. Cliente presiona "Conectar"

**Resultado esperado:**
- ✅ Mensaje de error: "Código de sesión no encontrado o expirado"
- ✅ Vuelve a pantalla de ingreso de código

#### **TC-CLIENT-003: Control táctil básico (P0)**
**Pasos:**
1. Cliente conectado exitosamente
2. Cliente toca en el botón "WhatsApp" visible en la pantalla del host
3. Observar dispositivo del host

**Resultado esperado:**
- ✅ En el host, el botón "WhatsApp" se presiona (animación de tap)
- ✅ Acción correspondiente se ejecuta (ej: abre WhatsApp)
- ✅ Feedback visual en cliente: círculo breve donde se tocó

#### **TC-CLIENT-004: Desconexión del host (P1)**
**Pasos:**
1. Cliente conectado
2. Host presiona "Terminar Sesión"

**Resultado esperado:**
- ✅ Video desaparece en cliente
- ✅ Mensaje: "El host terminó la sesión"
- ✅ Botón "Volver" para regresar a pantalla inicial

---

### Estimación de Esfuerzo

| Tarea | Esfuerzo | Prioridad |
|-------|----------|-----------|
| Setup Flutter Web + Firebase Hosting | 2-3 horas | P0 |
| Pantalla de ingreso de código | 3-4 horas | P0 |
| WebRTC Client Service (conexión) | 6-8 horas | P0 |
| Pantalla de visualización de stream | 4-5 horas | P0 |
| Data channel para control táctil | 5-6 horas | P0 |
| Host: Recibir y ejecutar taps remotos | 4-5 horas | P0 |
| Manejo de errores y reconexión | 3-4 horas | P0 |
| Testing end-to-end | 4-5 horas | P0 |
| **TOTAL** | **31-40 horas** | **~1 semana** |

---

### Dependencias

**Ya completado:**
- ✅ Host (servidor) implementado y funcionando
- ✅ Firebase Firestore configurado
- ✅ Signaling con `offer` ya funciona

**Pendiente:**
- [ ] `AccessibilityService` en host debe soportar taps remotos
- [ ] Firebase Hosting configurado para web app
- [ ] Permisos de Firestore ajustados para permitir escritura de cliente

---

### Estatus

- [x] Identificado como bloqueante para MVP (08 ene 2026)
- [x] Especificación técnica completada
- [x] Aprobado para desarrollo
- [x] En desarrollo
- [x] En testing (TC-CLIENT-001 a TC-CLIENT-004)
- [x] Listo para MVP

---

### FUNCIONALIDAD 2.2: BaseScreenLayout - Widget de Layout Consistente

#### Fecha de planeación: 14 Enero 2026
#### Prioridad: **Media (P1 - Mejora UX)**
#### Estatus: Por iniciar

---

#### Contexto

La app está orientada a adultos mayores que necesitan una experiencia **predecible y consistente** en todas las pantallas. Actualmente, cada pantalla tiene su propia estructura, lo que puede generar confusión sobre dónde están los botones principales.

**Problema identificado:**
- Botones principales (CTAs) en diferentes ubicaciones entre pantallas
- Contenido sin scroll cuando crece (problemas en dispositivos pequeños)
- Falta de consistencia dificulta aprendizaje para adultos mayores

**Solución:**
Crear un widget base reutilizable (`BaseScreenLayout`) que estandarice el layout con:
- ✅ Contenido scrollable (adapta a cualquier tamaño de pantalla)
- ✅ Footer sticky con botones principales (siempre en la misma posición)
- ✅ Soporte para múltiples botones en footer
- ✅ Semántica completa para TalkBack

---

#### Historia de Usuario

```
Como adulto mayor con baja visión
Quiero que todos los botones principales estén siempre en el mismo lugar en cada pantalla
Para poder predecir dónde están y usarlos sin confusión
```

---

#### Criterios de Aceptación Funcional

**Layout Estándar:**
- [ ] Todas las pantallas usan el mismo widget base
- [ ] Contenido es scrollable automáticamente si excede el tamaño de pantalla
- [ ] Footer con botones principales siempre visible (sticky)
- [ ] Footer soporta 1-3 botones (ej: secundario + principal)
- [ ] AppBar con título y botón "Atrás" opcional
- [ ] Espaciado consistente en todas las pantallas (24dp padding)

**Accesibilidad:**
- [ ] Semántica completa para TalkBack
- [ ] Botones en footer tienen mínimo 80dp altura
- [ ] Footer se anuncia como región landmark
- [ ] Navegación con TalkBack es predecible

**Aplicación Inmediata:**
- [ ] `RemoteControlHostScreen` refactorizado para usar `BaseScreenLayout`
- [ ] Botón "Terminar Sesión" siempre visible en footer
- [ ] Código de sesión + instrucciones scrollable

---

#### Criterios de Aceptación Técnico

**Archivo nuevo:**
- [ ] `lib/widgets/base_screen_layout.dart` creado

**API del Widget:**
```dart
BaseScreenLayout(
  title: 'Control Remoto',           // Título del AppBar
  showBackButton: true,               // Mostrar botón "Atrás" (opcional)
  content: [                          // Lista de widgets scrollable
    ConnectionStatusIndicator(...),
    SessionCodeDisplay(...),
    // ... más widgets
  ],
  footerActions: [                    // 1-3 botones en footer sticky
    AccessibleButton(
      label: 'Terminar Sesión',
      icon: Icons.stop,
      onPressed: () => ...,
      isDestructive: true,
    ),
  ],
)
```

**Estructura Interna:**
```dart
Scaffold(
  appBar: AppBar(
    title: Text(title),
    leading: showBackButton ? BackButton() : null,
  ),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: content,
      ),
    ),
  ),
  persistentFooterButtons: footerActions,  // Sticky footer
)
```

**Características Técnicas:**
- [ ] Usa `Scaffold` + `persistentFooterButtons` para footer sticky
- [ ] Usa `SingleChildScrollView` para contenido scrollable
- [ ] `SafeArea` automático para evitar notches/bordes
- [ ] Padding consistente: 24dp en contenido, 16dp entre elementos del footer
- [ ] Semántica con `ExcludeSemantics` en decoraciones visuales
- [ ] Footer con `Semantics(label: 'Acciones principales', container: true)`

---

#### Aplicaciones por Pantalla

| Pantalla | Footer Actions | Content | Prioridad |
|----------|----------------|---------|-----------|
| **RemoteControlHostScreen** | "Terminar Sesión" | Status + Código + Instrucciones | P0 (Inmediato) |
| **WhatsAppScreen** | "Enviar" o "Volver" | Lista de contactos o chat | P1 (Futuro) |
| **VoiceCommandScreen** | "Detener" o "Cancelar" | Comandos + Feedback | P1 (Futuro) |
| **SettingsScreen** | "Guardar Cambios" | Opciones de configuración | P1 (Futuro) |

---

#### Diseño Visual

```
┌─────────────────────────────────────┐
│  ← Título de Pantalla            ⚙ │  ← AppBar (opcional back button)
├─────────────────────────────────────┤
│                                     │
│  [Contenido Scrollable]             │  ← SingleChildScrollView
│  • ConnectionStatusIndicator        │
│  • SessionCodeDisplay               │
│  • Instrucciones                    │
│  • Tarjetas informativas            │
│  • ...                              │
│  ↕ (scroll si crece)                │
│                                     │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐ │  ← Footer Sticky
│  │  [Btn Secundario] [Btn CTA]  │ │     (persistentFooterButtons)
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

---

#### Edge Cases y Manejo de Errores

**¿Qué pasa si el contenido es muy corto?**
- El footer permanece en la parte inferior (no flota en el medio)
- `SingleChildScrollView` con `Column` natural mantiene el footer abajo

**¿Qué pasa si hay 3+ botones en footer?**
- Advertir en documentación: máximo 3 botones recomendado
- Si se excede, los botones se envuelven (wrap) automáticamente

**¿Qué pasa en dispositivos muy pequeños?**
- Contenido siempre scrollable (no overflow)
- Footer se mantiene visible y accesible
- Botones mantienen tamaño mínimo (no se reducen)

**¿Qué pasa si no hay footerActions?**
- Footer no se muestra (comportamiento de `persistentFooterButtons`)
- Widget funciona como `Scaffold` normal

---

#### Refactorización de RemoteControlHostScreen

**Antes:**
```dart
Scaffold(
  appBar: AppBar(...),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: Column(
        children: [
          ConnectionStatusIndicator(...),
          SessionCodeDisplay(...),
          // ... más contenido
          _buildActionButtons(provider),  // Botones dentro del scroll
        ],
      ),
    ),
  ),
)
```

**Después:**
```dart
BaseScreenLayout(
  title: 'Control Remoto',
  content: [
    ConnectionStatusIndicator(status: provider.status),
    SizedBox(height: 32),
    if (provider.sessionCode != null) ...[
      SessionCodeDisplay(sessionCode: provider.sessionCode!),
      // ... más contenido
    ],
  ],
  footerActions: [
    AccessibleButton(
      label: 'Terminar Sesión',
      icon: Icons.stop,
      onPressed: () => _endSession(provider),
      isDestructive: true,
    ),
  ],
)
```

---

#### Estimación de Esfuerzo

| Tarea | Esfuerzo | Prioridad |
|-------|----------|-----------|
| Diseñar API del widget | 1 hora | P0 |
| Implementar `BaseScreenLayout` | 3-4 horas | P0 |
| Refactorizar `RemoteControlHostScreen` | 2-3 horas | P0 |
| Documentar uso en CLAUDE.md | 1 hora | P0 |
| Testing con TalkBack | 2 horas | P0 |
| **TOTAL** | **9-11 horas** | **~1-1.5 días** |

---

#### Dependencias

**Ya completado:**
- ✅ `AccessibleButton` widget existente
- ✅ `RemoteControlHostScreen` estructura actual

**Requerido:**
- [ ] Ninguna dependencia externa nueva

---

#### Testing

**Casos de prueba:**
- [ ] TC-BASE-001: Contenido largo scrollable sin overflow
- [ ] TC-BASE-002: Footer sticky visible al hacer scroll
- [ ] TC-BASE-003: Múltiples botones en footer (1, 2, 3 botones)
- [ ] TC-BASE-004: Navegación con TalkBack predecible
- [ ] TC-BASE-005: Botón "Atrás" funciona correctamente
- [ ] TC-BASE-006: Layout responsive en diferentes tamaños de pantalla

---

#### Documentación

**Agregar a CLAUDE.md:**
```markdown
### BaseScreenLayout - Widget Base para Pantallas

Widget estándar para crear pantallas consistentes en toda la app.

**Uso:**
```dart
BaseScreenLayout(
  title: 'Título de Pantalla',
  showBackButton: true,
  content: [
    // Lista de widgets scrollable
  ],
  footerActions: [
    // 1-3 botones sticky
  ],
)
```

**Características:**
- Contenido automáticamente scrollable
- Footer sticky con botones principales
- Semántica completa para TalkBack
- Espaciado consistente (24dp)
```

---

#### Impacto en el Proyecto

**Beneficios:**
- ✅ **Consistencia:** Experiencia predecible para adultos mayores
- ✅ **Accesibilidad:** Footer siempre en misma posición para TalkBack
- ✅ **Escalabilidad:** Fácil crear nuevas pantallas
- ✅ **Mantenibilidad:** Cambios de diseño en un solo lugar
- ✅ **Responsive:** Funciona en cualquier tamaño de pantalla

**Pantallas afectadas:**
- RemoteControlHostScreen (refactorización inmediata)
- Futuras pantallas: WhatsApp, Voice Commands, Settings

---

#### Estatus

- [x] Especificación completada (14 ene 2026)
- [x] Aprobado para desarrollo
- [x] En desarrollo
- [x] En testing
- [x] Listo para producción
- [x] Documentado en CLAUDE.md

---

## MEJORAS POST-MVP (Funcionalidad 2.3 - Enhancements)

### Prioridad: P1-P2 (Alta, pero no bloqueante para MVP)

---

### MEJORA 2.2.1: Botón para Repetir Código de Sesión en Altavoz

#### Historia de Usuario
```
Como adulto mayor usando la app
Quiero poder repetir el código de sesión en altavoz cuando lo necesite
Para poder compartirlo con mi familiar sin tener que leerlo visualmente en la pantalla
```

#### Contexto
Durante las pruebas del TC-HP-004, se identificó que aunque el código se anuncia automáticamente al inicio, sería útil poder repetirlo bajo demanda, especialmente en casos donde:
- El usuario no escuchó el código la primera vez
- El familiar llegó tarde y no estaba presente cuando se anunció
- El usuario necesita confirmar el código nuevamente

#### Criterios de Aceptación Funcional
- [ ] Existe un botón "Repetir código" visible en la pantalla de sesión activa
- [ ] El botón tiene un ícono de altavoz/volumen para identificación rápida
- [ ] Al presionar el botón, el TTS anuncia: "Código de sesión: X, X, X, X, X, X" (cada dígito separado)
- [ ] El botón tiene tamaño mínimo de 80dp de altura (estándar de accesibilidad)
- [ ] El botón funciona con TalkBack activado
- [ ] Semantic label: "Repetir código de sesión en altavoz, Botón, Toca dos veces para escuchar el código nuevamente"

#### Criterios de Aceptación Técnico
- [ ] Botón implementado usando `AccessibleButton` widget existente
- [ ] Usa `ElevenLabsService.speak()` para reproducir el código
- [ ] El mensaje del TTS es el mismo que el anuncio inicial (consistencia)
- [ ] El botón se deshabilita temporalmente mientras reproduce el audio (evita spam)
- [ ] Se agrega a `RemoteControlHostScreen` debajo del widget `SessionCodeDisplay`

#### UI/UX
**Ubicación:** Entre el `SessionCodeDisplay` y las instrucciones "Comparte este código..."

**Diseño:**
```
┌─────────────────────────────────────┐
│   SessionCodeDisplay (código)       │
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│  🔊 Repetir código en altavoz       │  ← NUEVO BOTÓN
└─────────────────────────────────────┘
           ↓
┌─────────────────────────────────────┐
│   Card: "Comparte este código..."   │
└─────────────────────────────────────┘
```

#### Edge Cases y Manejo de Errores
- ¿Qué pasa si el usuario presiona el botón mientras ya está reproduciendo?
  - Botón se deshabilita visualmente y no hace nada
  - TalkBack anuncia: "Esperando que termine el audio actual"
- ¿Qué pasa si ElevenLabs falla?
  - Botón sigue funcionando, pero no reproduce audio (fallo silencioso)
  - Se loggea el error en consola
  - NO se muestra error al usuario (no es crítico)
- ¿Qué pasa si el usuario tiene el volumen multimedia en 0?
  - Se reproduce de todas formas (responsabilidad del usuario ajustar volumen)
  - Considerar agregar indicador visual de "reproduciendo..." para feedback

#### Estimación de Esfuerzo
- **Desarrollo:** 2-3 horas
- **Testing:** 1 hora (TC-ACC-006 y casos nuevos)
- **Total:** 3-4 horas

#### Dependencias
- ✅ ElevenLabsService ya implementado y funcionando
- ✅ AccessibleButton widget existente
- ✅ RemoteControlHostScreen estructura ya definida

#### Estatus
- [x] Identificado durante testing (TC-HP-004)
- [x] Diseñado (especificación completa)
- [x] En desarrollo
- [x] En pruebas
- [x] Listo para producción

---

### Otras Mejoras Planeadas para 2.1

#### MEJORA 2.1.2: Ajuste de Volumen de TTS (Prioridad: P2)
- Agregar slider de volumen específico para TTS en settings
- Permitir probar el volumen con audio de ejemplo

#### MEJORA 2.1.3: Selección de Voz (Prioridad: P2)
- Permitir elegir entre voz masculina/femenina
- Agregar opción de velocidad de habla (lenta/normal/rápida)

#### MEJORA 2.1.4: Historial de Sesiones (Prioridad: P3)
- Mostrar últimas 5 sesiones remotas con fecha/hora
- Útil para auditoría y confianza del usuario

---

## REGISTRO DE CAMBIOS

| Fecha | Versión | Cambios |
|-------|---------|---------|
| 11 ene 2026 | 1.2 | Agregada FUNCIONALIDAD 7: Configuración de Release para Producción. Renumeradas funcionalidades post-MVP (8-11) |
| 08 ene 2026 | 1.1 | Agregada sección "Mejoras Post-MVP" con mejora 2.1.1 (Repetir código en altavoz) |
| 24 dic 2025 | 1.0 | Backlog inicial creado basado en ROADMAP v1.1 y ARQUITECTURA v2.0 |

---

**Próximos pasos:**
1. Revisar y aprobar este backlog
2. Iniciar desarrollo siguiendo prioridades P0
3. Actualizar estatus de cada funcionalidad conforme avanza el desarrollo
4. Sesión de planning semanal para ajustar estimaciones según progreso real
