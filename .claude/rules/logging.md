# Reglas de Logging

## Principio Fundamental

Usar **`developer.log()`** para TODOS los logs en la aplicación.

**NO usar `print()` para logging.**

---

## Formato Estándar

```dart
import 'dart:developer' as developer;

developer.log(
  'Descripción del evento',
  name: 'NombreClase',
  error: exception,        // Opcional - cuando hay error
  stackTrace: stackTrace,  // Opcional - para debugging
);
```

### Ejemplos

**Log básico:**
```dart
developer.log(
  'Session created successfully',
  name: 'RemoteControlProvider',
);
```

**Log con error:**
```dart
developer.log(
  'Failed to connect to session',
  name: 'WebRTCService',
  error: e,
  stackTrace: stackTrace,
);
```

**Log con contexto:**
```dart
developer.log(
  'Processing signaling message: ${message.type}',
  name: 'FirebaseSignalingService',
);
```

---

## Cuándo Agregar Logs

### Logs Esenciales (MANTENER)

- **Inicio/fin de operaciones críticas:** Conexión WebRTC, sesiones remotas
- **Cambios de estado importantes:** Conectado, desconectado, error
- **Errores con contexto:** Excepciones capturadas con información útil
- **Platform Channel calls:** Llamadas entre Flutter y código nativo

### Logs de Debugging (ELIMINAR antes de commit)

- **Logs con emojis:** 🔵🔴🟢 son indicadores de debugging temporal
- **Logs de pasos intermedios:** "STEP 1", "STEP 2", etc.
- **Logs muy frecuentes:** En loops o callbacks que se llaman constantemente
- **Logs de valores:** Solo para verificar durante desarrollo

---

## Ventajas de `developer.log()`

1. **Estructurado:** Parámetros tipados (`name`, `error`, `stackTrace`)
2. **Filtrable:** En DevTools se puede filtrar por `name`
3. **Profesional:** Estándar de Flutter para producción
4. **Contexto:** El `name` identifica inmediatamente el origen

---

## Filtrar Logs en DevTools

```bash
# Ver solo logs de un servicio específico
flutter logs | grep "WebRTCService"

# Ver todos los logs estructurados
flutter logs
```

En Flutter DevTools (web):
- Ir a "Logging" tab
- Usar filtro de texto para buscar por `name`

---

## Checklist Antes de Commit

- [ ] No hay `print()` en el código (solo `developer.log()`)
- [ ] No hay logs con emojis (🔵🔴🟢⚠️✅❌)
- [ ] Todos los logs tienen `name:` con nombre de clase/servicio
- [ ] Logs de error incluyen `error:` y `stackTrace:` cuando aplica
- [ ] No hay logs excesivos en loops o callbacks frecuentes

---

## Migración desde `print()`

**Antes (incorrecto):**
```dart
print('🔵 [RemoteControlProvider] Starting session...');
print('Error: $e');
```

**Después (correcto):**
```dart
developer.log(
  'Starting session',
  name: 'RemoteControlProvider',
);

developer.log(
  'Failed to start session',
  name: 'RemoteControlProvider',
  error: e,
);
```
