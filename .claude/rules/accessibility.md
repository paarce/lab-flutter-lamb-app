# Reglas de Accesibilidad

## Principios Fundamentales

1. **SIEMPRE priorizar accesibilidad** - Este proyecto está diseñado para usuarios con baja visión
2. **Testar con TalkBack activado** - Nunca considerar una feature completa sin testing de accesibilidad
3. **Simplicidad sobre complejidad** - Usuarios tienen experiencia técnica limitada

---

## Widgets Flutter

### Requisitos Obligatorios para Todos los Widgets Interactivos

```dart
// ✅ CORRECTO
Semantics(
  label: 'Abrir WhatsApp',
  hint: 'Toca dos veces para abrir la aplicación WhatsApp',
  button: true,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      minimumSize: Size(200, 80), // MÍNIMO 80dp altura
      textStyle: TextStyle(fontSize: 24), // MÍNIMO 24sp
    ),
    onPressed: () => openWhatsApp(),
    child: Text('Abrir WhatsApp'),
  ),
)

// ❌ INCORRECTO - No tiene Semantics
ElevatedButton(
  onPressed: () => openWhatsApp(),
  child: Text('Abrir WhatsApp'),
)
```

### Tamaños Mínimos

| Elemento | Tamaño Mínimo | Ideal |
|----------|---------------|-------|
| **Altura de botón** | 80dp | 100dp |
| **Tamaño de texto** | 24sp | 28sp |
| **Espacio entre elementos** | 16dp | 24dp |
| **Área táctil** | 48x48dp | 60x60dp |

### Contraste de Color

```dart
// Alto contraste configurable
class AppColors {
  static ColorScheme highContrast = ColorScheme.highContrastLight(
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.blue[900]!,
    background: Colors.white,
  );

  static ColorScheme standard = ColorScheme.light(
    primary: Colors.blue[700]!,
    onPrimary: Colors.white,
  );
}

// Usar en MaterialApp
MaterialApp(
  theme: ThemeData(
    colorScheme: isHighContrast ? AppColors.highContrast : AppColors.standard,
  ),
)
```

---

## Testing de Accesibilidad

### Antes de Cada Commit

1. **Ejecutar analyzer:**
   ```bash
   flutter run --analyze-accessibility
   ```

2. **Probar con TalkBack:**
   - Activar TalkBack en Settings → Accessibility
   - Navegar por la app usando solo gestos de TalkBack
   - Verificar que TODOS los elementos se anuncian correctamente

3. **Android Accessibility Scanner:**
   - Instalar desde Google Play
   - Escanear cada pantalla nueva

### Checklist de Accesibilidad

- [ ] Todos los botones tienen `Semantics` con `label` y `button: true`
- [ ] Imágenes tienen `semanticLabel` descriptivo
- [ ] Formularios tienen `hint` explicativo
- [ ] Navegación funciona solo con TalkBack (sin mirar pantalla)
- [ ] Feedback audible para todas las acciones (TTS con ElevenLabs)
- [ ] Sin dependencia de color únicamente (usar iconos + texto)
- [ ] Tiempo de timeout suficiente (mínimo 30 segundos)

---

## Feedback de Voz

### Usar ElevenLabs TTS para Confirmaciones

```dart
// SIEMPRE dar feedback audible para acciones importantes
Future<void> openWhatsAppChat(String contactName) async {
  try {
    await whatsAppService.openChat(contactName);

    // ✅ Feedback audible
    await elevenLabsService.speak("Abriendo chat de $contactName");

  } catch (e) {
    // ✅ Errores también en voz
    await elevenLabsService.speak(
      "No se pudo abrir el chat. Por favor, verifica que WhatsApp esté instalado"
    );
  }
}
```

### Mensajes de Voz: Guía de Estilo

- **Cortos y claros:** Máximo 2 oraciones
- **Lenguaje simple:** Evitar jerga técnica
- **Tono amable:** "Abriendo chat de María" (no "Ejecutando comando...")
- **Errores comprensibles:** "WhatsApp no está instalado" (no "Error 404 package not found")

---

## Navegación

### Orden de Foco

```dart
// Especificar orden de navegación cuando sea necesario
Semantics(
  sortKey: OrdinalSortKey(1.0), // Primero
  child: ElevatedButton(...),
)

Semantics(
  sortKey: OrdinalSortKey(2.0), // Segundo
  child: ElevatedButton(...),
)
```

### Gestos de TalkBack

Asegurar que estos gestos funcionen:
- **Swipe derecha/izquierda:** Navegar entre elementos
- **Doble tap:** Activar elemento seleccionado
- **Swipe arriba/abajo:** Ajustar configuraciones (slider)
- **Dos dedos swipe up:** Scroll hacia arriba

---

## Animaciones

### Evitar Animaciones Complejas

```dart
// ✅ Animaciones sutiles permitidas
AnimatedOpacity(
  duration: Duration(milliseconds: 300),
  opacity: isVisible ? 1.0 : 0.0,
  child: widget,
)

// ❌ Evitar animaciones que distraen
// - Parallax
// - Rotaciones continuas
// - Transiciones con zoom excesivo
```

### Respetar Configuración del Sistema

```dart
import 'package:flutter/services.dart';

// Detectar si usuario desactivó animaciones
final reducedMotion = MediaQuery.of(context).disableAnimations;

AnimatedContainer(
  duration: reducedMotion
    ? Duration.zero  // Sin animación
    : Duration(milliseconds: 300),
  // ...
)
```

---

## Errores Comunes a Evitar

### ❌ Iconos sin Texto
```dart
// MAL - Solo icono
IconButton(
  icon: Icon(Icons.settings),
  onPressed: () => openSettings(),
)

// ✅ BIEN - Con Semantics
Semantics(
  label: 'Configuración',
  button: true,
  child: IconButton(
    icon: Icon(Icons.settings),
    onPressed: () => openSettings(),
  ),
)
```

### ❌ Información Solo Visual
```dart
// MAL - Color como única indicación de error
TextField(
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey),
    ),
  ),
)

// ✅ BIEN - Color + texto + anuncio de voz
TextField(
  decoration: InputDecoration(
    errorText: hasError ? 'Campo obligatorio' : null,
    border: OutlineInputBorder(),
  ),
)
// + anuncio con ElevenLabs TTS
```

### ❌ Timeouts Cortos
```dart
// MAL - Muy corto para lectores de pantalla
showDialog(
  context: context,
  barrierDismissible: true,
  builder: (context) => AlertDialog(...),
);
Timer(Duration(seconds: 3), () => Navigator.pop(context)); // ❌

// ✅ BIEN - Timeout generoso o requiere acción explícita
showDialog(
  context: context,
  barrierDismissible: false, // Usuario debe cerrar explícitamente
  builder: (context) => AlertDialog(
    actions: [
      TextButton(
        child: Text('Entendido', style: TextStyle(fontSize: 24)),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  ),
);
```

---

## Onboarding y Tutoriales

### Primera Vez: Tutorial de Permisos

```dart
// Explicar CADA permiso peligroso antes de solicitarlo
Future<void> requestAccessibilityPermission() async {
  // 1. Explicación en lenguaje simple
  await elevenLabsService.speak(
    "Para ayudarte con WhatsApp, necesito un permiso especial. "
    "Te llevaré a la configuración donde debes activar el servicio de asistencia."
  );

  // 2. Mostrar pantalla con imágenes paso a paso
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PermissionTutorialScreen()),
  );

  // 3. Abrir configuración
  await openAccessibilitySettings();
}
```

### Capturas de Pantalla en Tutorial

Incluir imágenes reales de:
- Pantalla de configuración de Accessibility
- Dónde tocar para activar el servicio
- Confirmación de que está activado

---

## Testing con Usuarios Reales

### Protocolo de Testing

1. **Reclutar 2-3 usuarios del público objetivo** (60+ años, baja visión)
2. **NO explicar cómo usar la app** - observar cómo la descubren
3. **Registrar:**
   - Puntos de confusión
   - Errores de comprensión de mensajes de voz
   - Gestos que no funcionan como esperan
4. **Iterar antes de lanzar**

### Métricas de Éxito

- [ ] Usuario puede abrir WhatsApp de contacto en **<10 segundos** (sin ayuda)
- [ ] Usuario entiende mensajes de error (test de comprensión)
- [ ] 95%+ comandos de voz reconocidos correctamente
- [ ] 100% conformidad con Android Accessibility Scanner

---

## Referencias

- [Material Design Accessibility](https://m3.material.io/foundations/accessible-design/overview)
- [Flutter Accessibility Guide](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [TalkBack User Guide](https://support.google.com/accessibility/android/answer/6283677)
