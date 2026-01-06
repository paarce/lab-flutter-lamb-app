# Accessibility Skill - TalkBack & Diseño Inclusivo

## Descripción
Guía específica para implementar funcionalidades accesibles para usuarios con 
baja visión usando TalkBack.

## Cuándo Usar
- Al crear cualquier pantalla nueva
- Al agregar widgets interactivos (botones, inputs)
- Al validar accesibilidad de funcionalidad implementada
- Cuando se mencione "TalkBack", "accesibilidad" o "baja visión"

## Reglas de Oro de Accesibilidad

### 1. Semantics es OBLIGATORIO
TODO widget interactivo DEBE tener `Semantics`:
```dart
// ❌ MAL
ElevatedButton(
  onPressed: () {},
  child: Text('Aceptar'),
)

// ✅ BIEN
Semantics(
  label: 'Botón Aceptar',
  hint: 'Presiona para confirmar la acción',
  button: true,
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Aceptar'),
  ),
)
```

### 2. Tamaños Mínimos

**Botones:**
```dart
minimumSize: Size(200, 80) // Ancho 200dp, Alto 80dp
```

**Texto:**
```dart
fontSize: 24.0 // Mínimo 24sp
```

**Espaciado entre elementos táctiles:**
```dart
SizedBox(height: 16) // Mínimo 16dp entre botones
```

### 3. Contraste WCAG 2.1 AA

Ratio mínimo 4.5:1 entre texto y fondo.

Usar esquema de alto contraste:
```dart
ThemeData(
  colorScheme: ColorScheme.highContrastLight(),
)
```

O definir manualmente:
```dart
// Ejemplo validado
Color fondo = Colors.white;        // #FFFFFF
Color texto = Colors.black;         // #000000
// Ratio: 21:1 ✅

Color fondoOscuro = Color(0xFF1A1A1A);
Color textoClaro = Colors.white;
// Ratio: ~15:1 ✅
```

### 4. No Dependencia de Color

NUNCA usar solo color para comunicar información:
```dart
// ❌ MAL
Container(
  color: Colors.red, // Solo color indica error
)

// ✅ BIEN
Container(
  color: Colors.red,
  child: Row(
    children: [
      Icon(Icons.error), // Ícono + color
      Text('Error: ...'), // Texto explícito
    ],
  ),
)
```

## Estructura de Pantalla Accesible
```dart
class AccessibleScreen extends StatefulWidget {
  @override
  _AccessibleScreenState createState() => _AccessibleScreenState();
}

class _AccessibleScreenState extends State<AccessibleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Título Pantalla',
          style: TextStyle(fontSize: 24), // Mínimo 24sp
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24), // Padding generoso
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón 1
            Semantics(
              label: 'Descripción clara del botón 1',
              hint: 'Qué pasa al presionarlo',
              button: true,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 80),
                  textStyle: TextStyle(fontSize: 24),
                ),
                onPressed: () {
                  // Acción
                },
                child: Text('Botón 1'),
              ),
            ),
            
            SizedBox(height: 24), // Espaciado entre botones
            
            // Botón 2
            Semantics(
              label: 'Descripción clara del botón 2',
              hint: 'Qué pasa al presionarlo',
              button: true,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 80),
                  textStyle: TextStyle(fontSize: 24),
                ),
                onPressed: () {
                  // Acción
                },
                child: Text('Botón 2'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Orden de Foco (si es necesario)

Si el orden natural no funciona, usar `FocusTraversalGroup`:
```dart
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(
        order: NumericFocusOrder(1.0),
        child: Widget1(),
      ),
      FocusTraversalOrder(
        order: NumericFocusOrder(2.0),
        child: Widget2(),
      ),
    ],
  ),
)
```

## Feedback Auditivo

Anunciar eventos importantes con TTS:
```dart
import 'package:flutter/services.dart';

void announceToTalkBack(String message) {
  SystemChannels.accessibility.invokeMethod(
    'announce',
    message,
  );
}

// Uso:
announceToTalkBack('Sesión remota iniciada. Código: 123456');
```

## Checklist de Validación

Al terminar una pantalla, verificar:

- [ ] Todos los widgets interactivos tienen `Semantics`
- [ ] Botones tienen altura mínima 80dp
- [ ] Texto tiene tamaño mínimo 24sp
- [ ] Contraste cumple ratio 4.5:1
- [ ] Espaciado entre elementos táctiles ≥16dp
- [ ] No hay información solo por color
- [ ] Probado con TalkBack activado:
  - [ ] Swipe derecha/izquierda navega correctamente
  - [ ] Doble tap activa elementos
  - [ ] Labels se leen claramente
- [ ] `flutter run --analyze-accessibility` sin warnings críticos

## Comandos de Validación
```bash
# Ejecutar con análisis de accesibilidad
flutter run --analyze-accessibility

# En dispositivo: activar TalkBack
# Configuración > Accesibilidad > TalkBack > Activar
```

## Referencias
- WCAG 2.1: https://www.w3.org/WAI/WCAG21/quickref/
- Flutter Accessibility: https://docs.flutter.dev/development/accessibility-and-localization/accessibility