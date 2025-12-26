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
- [ ] En pruebas
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

## BACKLOG FUTURO (Post-MVP - v1.0)

Estas funcionalidades están fuera del MVP pero documentadas para v1.0 (Semanas 7-12):

### FUNCIONALIDAD 7: AccessibilityService para WhatsApp Automation
- Automatización avanzada: abrir chat por nombre (no número), leer mensajes, enviar mensajes
- **Riesgo:** Muy frágil ante actualizaciones de WhatsApp
- **Prioridad v1.0:** P1 (importante pero no crítica, deep links cubren necesidad básica)

### FUNCIONALIDAD 8: Comandos de Voz Expandidos
- "Lee mis mensajes de [contacto]"
- "Envía mensaje a [contacto] diciendo [texto]"
- "¿Tengo mensajes nuevos?"
- "Llama a [contacto]"
- Parser NLP mejorado con contexto y sinónimos

### FUNCIONALIDAD 9: Notificaciones Inteligentes
- Listener de notificaciones de WhatsApp
- Anuncio automático de mensajes nuevos en voz alta
- Configuración de contactos VIP
- Control de frecuencia de anuncios

### FUNCIONALIDAD 10: Personalización de Accesibilidad
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

## REGISTRO DE CAMBIOS

| Fecha | Versión | Cambios |
|-------|---------|---------|
| 24 dic 2025 | 1.0 | Backlog inicial creado basado en ROADMAP v1.1 y ARQUITECTURA v2.0 |

---

**Próximos pasos:**
1. Revisar y aprobar este backlog
2. Iniciar desarrollo siguiendo prioridades P0
3. Actualizar estatus de cada funcionalidad conforme avanza el desarrollo
4. Sesión de planning semanal para ajustar estimaciones según progreso real
