# Setup del Cliente Web - Control Remoto

## Prerrequisitos

- Flutter SDK instalado
- Cuenta de Firebase con proyecto configurado
- Navegador moderno (Chrome, Firefox, Safari)

---

## 1. Habilitar Flutter Web

```bash
flutter config --enable-web
flutter create . --platforms=web
```

---

## 2. Configurar Firebase

### 2.1 Obtener credenciales de Firebase Console

1. Ir a: https://console.firebase.google.com
2. Seleccionar proyecto
3. **Project Settings** → **Your apps** → **Web app**
4. Copiar valores de `firebaseConfig`

### 2.2 Actualizar archivo de configuración

Editar `/Users/augustoc.p./Development/lamb/web/firebase-config.js`:

```javascript
const firebaseConfig = {
  apiKey: "TU_API_KEY_AQUI",
  authDomain: "tu-proyecto.firebaseapp.com",
  projectId: "tu-proyecto-id",
  storageBucket: "tu-proyecto.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456"
};
```

---

## 3. Ejecutar en Desarrollo

### Opción 1: Chrome (recomendado)

```bash
flutter run -d chrome --target lib/main_web.dart
```

### Opción 2: Edge

```bash
flutter run -d edge --target lib/main_web.dart
```

### Opción 3: Firefox

```bash
flutter run -d firefox --target lib/main_web.dart
```

---

## 4. Build para Producción

```bash
flutter build web --release --target lib/main_web.dart
```

Archivos generados en: `build/web/`

---

## 5. Deploy a Firebase Hosting

### 5.1 Instalar Firebase CLI

```bash
npm install -g firebase-tools
```

**Verificar instalación:**
```bash
firebase --version
# Debe mostrar versión 12.0.0+
```

### 5.2 Login a Firebase

```bash
firebase login
```

Esto abrirá un navegador para autenticarse con tu cuenta de Google.

### 5.3 Configurar Proyecto Firebase

El proyecto ya incluye archivos de configuración:
- ✅ `firebase.json` - Configuración de hosting (ya creado)
- ✅ `.firebaserc` - ID del proyecto (requiere actualización)

**Contenido de `firebase.json`:**
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [{"key": "Cache-Control", "value": "max-age=31536000"}]
      },
      {
        "source": "index.html",
        "headers": [{"key": "Cache-Control", "value": "no-cache, no-store, must-revalidate"}]
      }
    ]
  }
}
```

Este archivo configura:
- **public**: Directorio de archivos a deployar (`build/web`)
- **rewrites**: Redirige todas las rutas a `index.html` (SPA)
- **headers**: Optimiza cache (JS/CSS cacheados 1 año, HTML sin cache)

**Actualizar `.firebaserc`:**

Editar el archivo `.firebaserc` en la raíz del proyecto:

```json
{
  "projects": {
    "default": "tu-proyecto-id-real"
  }
}
```

Reemplazar `"tu-proyecto-id-real"` con el ID de tu proyecto Firebase (encontrarlo en Firebase Console → Project Settings).

**Ejemplo:**
```json
{
  "projects": {
    "default": "lamb-accessibility-app"
  }
}
```

### 5.4 Verificar Configuración

```bash
firebase projects:list
```

Debe mostrar tu proyecto listado.

```bash
firebase use default
```

Debe confirmar que estás usando el proyecto correcto.

### 5.5 Build y Deploy

**Paso 1: Build de producción**
```bash
flutter build web --release --target lib/main_web.dart
```

Este comando genera los archivos optimizados en `build/web/`.

**Paso 2: Deploy a Firebase Hosting**
```bash
firebase deploy --only hosting
```

**Salida esperada:**
```
=== Deploying to 'tu-proyecto-id'...

i  deploying hosting
i  hosting[tu-proyecto-id]: beginning deploy...
i  hosting[tu-proyecto-id]: found 25 files in build/web
✔  hosting[tu-proyecto-id]: file upload complete
i  hosting[tu-proyecto-id]: finalizing version...
✔  hosting[tu-proyecto-id]: version finalized
i  hosting[tu-proyecto-id]: releasing new version...
✔  hosting[tu-proyecto-id]: release complete

✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/tu-proyecto-id/overview
Hosting URL: https://tu-proyecto-id.web.app
```

### 5.6 Verificar Deployment

Abrir la URL de hosting en el navegador:
```
https://tu-proyecto-id.web.app
```

Debe mostrar la pantalla `ClientConnectScreen` del cliente web.

### 5.7 (Opcional) Configurar Dominio Personalizado

En Firebase Console:
1. Hosting → **Add custom domain**
2. Seguir instrucciones para configurar DNS
3. Firebase provee certificado SSL automáticamente

---

## 6. URLs de Acceso

### Local (desarrollo)

```
http://localhost:PUERTO
```

(El puerto se muestra al ejecutar `flutter run`)

### Producción (Firebase Hosting)

```
https://[tu-proyecto].web.app
```

---

## 7. Testing Conjunto Host + Client

### Terminal 1: Host (Android)

```bash
flutter run -d emulator-5554
```

### Terminal 2: Cliente (Web)

```bash
flutter run -d chrome --target lib/main_web.dart
```

---

## Troubleshooting

### Error: "Firebase not initialized"

- Verificar que `web/firebase-config.js` tiene credenciales correctas
- Verificar que scripts de Firebase están en `web/index.html`

### Error: "Failed to load video"

- Verificar que ambos (host y client) están en misma red
- Verificar reglas de Firestore permiten lectura/escritura

### Error en Safari

- Safari requiere HTTPS para WebRTC
- Usar Chrome o Firefox para desarrollo local

---

## Comandos Rápidos

### Desarrollo Local
```bash
# Ejecutar en Chrome
flutter run -d chrome --target lib/main_web.dart

# Ejecutar con web renderer específico (mejor para WebRTC)
flutter run -d chrome --target lib/main_web.dart --web-renderer html

# Ver logs en tiempo real
flutter logs
```

### Build y Deploy a Producción
```bash
# Build de producción optimizado
flutter build web --release --target lib/main_web.dart

# Deploy a Firebase Hosting
firebase deploy --only hosting

# Build + Deploy (comando completo)
flutter build web --release --target lib/main_web.dart && firebase deploy --only hosting
```

### Testing
```bash
# Ejecutar tests unitarios
flutter test

# Ejecutar análisis estático
flutter analyze

# Ejecutar ambos antes de deploy
flutter analyze && flutter test && flutter build web --release --target lib/main_web.dart && firebase deploy --only hosting
```

### Verificación Post-Deploy
```bash
# Ver URL de hosting
firebase hosting:sites:list

# Ver logs de hosting
firebase hosting:logs

# Abrir proyecto en consola
firebase open hosting
```
