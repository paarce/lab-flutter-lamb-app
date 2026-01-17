# Development Skill - App de Accesibilidad Flutter

## Descripción
Instrucciones para desarrollar funcionalidades de la app de accesibilidad siguiendo 
las convenciones del proyecto y los criterios del BACKLOG.md.

## Cuándo Usar
- Al implementar cualquier funcionalidad del BACKLOG.md
- Al crear nuevas pantallas, servicios o widgets
- Al integrar APIs o servicios externos

## Convenciones del Proyecto

### Estructura de Carpetas
- `lib/screens/` → Pantallas de la app (StatefulWidget)
- `lib/widgets/` → Componentes reutilizables
- `lib/services/` → Lógica de negocio, APIs, Platform Channels
- `lib/models/` → Modelos de datos (clases Dart)
- `lib/utils/` → Utilidades y helpers
- `android/app/src/main/kotlin/` → Código nativo Android

### Convenciones de Código

**Dart:**
- Indentación: 2 espacios
- Nombres: camelCase para variables/funciones, PascalCase para clases
- Widgets interactivos SIEMPRE envueltos en `Semantics`
- Botones: altura mínima 80dp con `minimumSize: Size(200, 80)`
- Texto: tamaño mínimo 24sp con `fontSize: 24.0`
- Contraste: cumplir WCAG 2.1 nivel AA

**Kotlin:**
- Indentación: 4 espacios
- Nombres: PascalCase para clases, camelCase para funciones
- Platform Channels: nombre `com.accessibility.app/[descriptivo]`
- Siempre manejar errores con try-catch

### Dependencias Base
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  flutter_webrtc: ^0.9.48
  flutter_accessibility_service: ^3.0.0
  http: ^1.1.0
  dio: ^5.4.0
  web_socket_channel: ^2.4.0
  hive: ^2.2.3
  permission_handler: ^11.1.0
```

### Usuario Final
- Adulto mayor (60+) con baja visión
- Usa TalkBack/VoiceOver activamente
- Experiencia técnica limitada
- Necesita interfaces simples y grandes

## Workflow de Implementación

### FASE 1: Análisis
Antes de escribir código:
1. Leer funcionalidad completa del BACKLOG.md
2. Identificar archivos a crear/modificar
3. Listar dependencias (librerías, permisos, Platform Channels)
4. Proponer orden de subtareas
5. **PAUSAR y esperar aprobación del desarrollador**

### FASE 2: Implementación
Para cada subtarea:
1. Explicar qué se va a implementar (1-2 líneas)
2. Mostrar código COMPLETO (sin omitir partes con "...")
3. Indicar ruta exacta del archivo
4. Explicar decisiones técnicas si hay alternativas
5. Agregar logs en puntos clave
6. **PAUSAR entre subtareas**

### FASE 3: Validación
Al terminar funcionalidad:
- [ ] Código compila sin errores (`flutter run`)
- [ ] Funciona en dispositivo físico
- [ ] Navegable con TalkBack
- [ ] Maneja errores principales (sin conexión, permisos denegados)
- [ ] Cumple checklist de accesibilidad
- [ ] Cumple criterios de aceptación del BACKLOG.md

## Accesibilidad - Requisitos Obligatorios

Cada widget interactivo DEBE tener `Semantics`:
```dart
Semantics(
  label: 'Descripción clara del elemento',
  hint: 'Qué pasa al activarlo',
  button: true, // si es botón
  child: ElevatedButton(
    // ...
  ),
)
```

Tamaños mínimos:
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    minimumSize: Size(200, 80), // Ancho mínimo 200, Alto mínimo 80
    textStyle: TextStyle(fontSize: 24), // Texto mínimo 24sp
  ),
)
```

Contraste:
```dart
ThemeData(
  colorScheme: ColorScheme.highContrastLight(),
  // O definir manualmente con ratio mínimo 4.5:1
)
```

## Manejo de Errores

Siempre envolver operaciones async:
```dart
try {
  final result = await someAsyncOperation();
  // Éxito
} catch (e) {
  print('ERROR [ContextoDescriptivo]: $e');
  // Mostrar mensaje al usuario
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: Mensaje simple para usuario')),
  );
}
```

## Logging

Usar **`developer.log()`** para TODOS los logs (NO usar `print()`).

Agregar logs en:
- Platform Channels (llamadas Dart ↔ Kotlin)
- Operaciones de red (API calls)
- Eventos críticos (conexión WebRTC, permisos)
- Errores con contexto

```dart
import 'dart:developer' as developer;

// Log básico
developer.log(
  'Session created successfully',
  name: 'RemoteControlProvider',
);

// Log con error
developer.log(
  'Failed to connect to session',
  name: 'WebRTCService',
  error: e,
  stackTrace: stackTrace,
);
```

**Ver regla completa:** `.claude/rules/logging.md`

## Comandos Útiles
```bash
# Ejecutar app
flutter run

# Compilar APK
flutter build apk --release

# Analizar código
flutter analyze

# Validar accesibilidad
flutter run --analyze-accessibility

# Limpiar build
flutter clean
```

## Idioma del Código

**CRÍTICO:** Todo el código debe estar en INGLÉS.

### Reglas de Idioma:
- **Nombres de variables:** Inglés (`userName`, NO `nombreUsuario`)
- **Nombres de funciones:** Inglés (`fetchUserData()`, NO `obtenerDatosUsuario()`)
- **Nombres de clases:** Inglés (`UserService`, NO `ServicioUsuario`)
- **Comentarios en código:** Inglés
- **Logs:** Inglés (`print('LOG [ClassName.method]: Description')`)
- **Mensajes de error técnicos:** Inglés
- **Documentación en código (docstrings):** Inglés

### Excepciones (Español permitido):
- **UI visible al usuario:** Español (textos en botones, mensajes en pantalla)
- **Strings de Semantics:** Español (para TalkBack en español)
- **Mensajes de error para usuario final:** Español

### Ejemplos:

**✅ CORRECTO:**
```dart
// Service to handle remote screen sharing
class RemoteControlService {
  // Start a new remote session
  Future<String> startSession() async {
    try {
      final sessionCode = await _generateCode();
      print('LOG [RemoteControlService.startSession]: Session created with code: $sessionCode');
      return sessionCode;
    } catch (e) {
      print('ERROR [RemoteControlService.startSession]: ${e.toString()}');
      throw Exception('Failed to start remote session');
    }
  }
  
  // Generate random 6-digit session code
  String _generateCode() {
    // Implementation
  }
}
```

**❌ INCORRECTO:**
```dart
// Servicio para manejar compartir pantalla remota
class ServicioControlRemoto {
  // Iniciar nueva sesión remota
  Future<String> iniciarSesion() async {
    try {
      final codigoSesion = await _generarCodigo();
      print('LOG [ServicioControlRemoto.iniciarSesion]: Sesión creada con código: $codigoSesion');
      return codigoSesion;
    } catch (e) {
      print('ERROR [ServicioControlRemoto.iniciarSesion]: ${e.toString()}');
      throw Exception('Falló al iniciar sesión remota');
    }
  }
}
```

**✅ UI en Español (permitido):**
```dart
Semantics(
  label: 'Botón para iniciar sesión remota', // ✅ Español para TalkBack
  hint: 'Presiona para generar código de sesión',
  button: true,
  child: ElevatedButton(
    onPressed: _startSession,
    child: Text('Iniciar Sesión Remota'), // ✅ Español visible al usuario
  ),
)

// Mensaje de error para usuario
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Error: No hay conexión a internet'), // ✅ Español para usuario
  ),
);
```

### Validación de Idioma

Antes de considerar código "listo":
- [ ] Todos los nombres de variables/funciones/clases en inglés
- [ ] Todos los comentarios técnicos en inglés
- [ ] Logs en inglés
- [ ] Strings de UI en español (para usuario final)

## Referencias
- BACKLOG.md: `.claude/docs/BACKLOG.md`
- Arquitectura: `.claude/docs/ARQUITECTURA.md` (si existe)