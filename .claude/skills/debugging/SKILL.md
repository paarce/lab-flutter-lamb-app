# Debugging Skill - Solución de Problemas

## Descripción
Guía para diagnosticar y resolver errores comunes en el desarrollo de la app.

## Cuándo Usar
- Cuando hay errores de compilación
- Cuando la app crashea en runtime
- Cuando una funcionalidad no se comporta como esperado
- Cuando hay problemas de rendimiento o conectividad

## Proceso de Debugging

### 1. Recopilar Información

Antes de proponer solución, pedir:
- [ ] Mensaje de error completo (copiar/pegar)
- [ ] Logs relevantes (consola Flutter o adb logcat)
- [ ] Código del archivo donde ocurre el error
- [ ] Pasos para reproducir el error
- [ ] Dispositivo/emulador y versión de Android

### 2. Diagnóstico

Categorizar el error:
- **Compilación:** Falta dependencia, error de sintaxis, versiones incompatibles
- **Runtime:** NullPointerException, PlatformException, permisos denegados
- **Lógica:** Funcionalidad no hace lo esperado
- **Rendimiento:** Latencia, app lenta, uso excesivo de memoria

### 3. Proponer Solución

- Explicar causa probable
- Mostrar código corregido COMPLETO
- Listar pasos de validación
- Sugerir logs adicionales si el problema persiste

## Errores Comunes y Soluciones

### Error: PlatformException en Platform Channel

**Síntoma:**
```
PlatformException(error, Method not implemented, null, null)
```

**Causa:** Método no implementado en Kotlin o nombre incorrecto

**Solución:**
1. Verificar que el nombre del método coincida exactamente (Dart ↔ Kotlin)
2. Verificar que el channel name sea idéntico
3. Agregar logs en ambos lados para confirmar llamada

### Error: MissingPluginException

**Síntoma:**
```
MissingPluginException(No implementation found for method X on channel Y)
```

**Causa:** Hot restart no carga código nativo nuevo

**Solución:**
```bash
# Detener app
flutter clean
flutter run
```

### Error: Permiso denegado

**Síntoma:**
```
SecurityException: Permission denied
```

**Causa:** Permiso no declarado en AndroidManifest.xml o no solicitado al usuario

**Solución:**
1. Agregar permiso en `AndroidManifest.xml`
2. Solicitar permiso con `permission_handler` antes de usar
3. Manejar caso de permiso denegado con mensaje claro

### Error: Dependencias incompatibles

**Síntoma:**
```
Because X depends on Y >=1.0.0 and Z depends on Y <1.0.0, version solving failed.
```

**Solución:**
```yaml
# En pubspec.yaml
dependency_overrides:
  package_problematico: ^version_especifica
```

## Comandos de Debugging
```bash
# Ver logs en tiempo real
flutter run --verbose

# Analizar código
flutter analyze

# Validar accesibilidad
flutter run --analyze-accessibility

# Ver logs de Android
adb logcat | grep "Flutter"

# Limpiar build
flutter clean

# Reinstalar dependencias
flutter pub get
```

## Checklist de Debugging

Cuando algo no funciona:
- [ ] ¿Hay errores en la consola?
- [ ] ¿Probaste `flutter clean`?
- [ ] ¿El código compila sin warnings?
- [ ] ¿Agregaste logs en puntos clave?
- [ ] ¿Probaste en dispositivo físico (no solo emulador)?
- [ ] ¿Los permisos están declarados y solicitados?
- [ ] ¿La funcionalidad requiere conexión a internet?