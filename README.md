# OmniStream IPTV

**OmniStream IPTV** es una aplicación de reproducción IPTV de alto rendimiento, multiplataforma (Android, iOS, Web, macOS), centrada en la velocidad de "zapping", la estabilidad del stream y una interfaz de usuario moderna y adaptativa.

## 📋 Características Principales

- **Reproducción de IPTV de alto rendimiento** con soporte para múltiples codecs (H.264, H.265/HEVC, MPEG-TS, HLS, DASH)
- **Procesamiento de listas masivas** (20,000+ canales) sin bloquear la UI
- **Soporte de múltiples formatos de entrada**: M3U/M3U8, Xtream Codes API, Stalker Portal
- **EPG avanzado** con caché local, fuzzy matching y catch-up
- **UI adaptativa** con navegación D-Pad para TV y controles táctiles para móviles
- **Killer features**: Picture in Picture (PiP), Multi-View (4 canales simultáneamente), Background Play
- **Auto-reconnect** con reintentos exponenciales
- **Speed Test integrado** para medir velocidad de conexión
- **Timeshift local** para pausar y reanudar transmisiones en vivo

## 🛠️ Stack Tecnológico

| Componente | Tecnología |
|-----------|-----------|
| **Framework** | Flutter (Dart) |
| **Gestor de Estado** | Riverpod |
| **Base de Datos Local** | Hive + Drift (SQLite) |
| **Motor de Video** | video_player + media_kit |
| **Networking** | Dio + HTTP |
| **Backend** | Firebase (Analytics, Crashlytics, Remote Config) |
| **CI/CD** | GitHub Actions |

## 📦 Requisitos Previos

- **Flutter**: versión 3.0.0 o superior
- **Dart**: versión 3.0.0 o superior
- **Git**: para control de versiones
- **Android SDK**: para compilación de Android
- **Xcode**: para compilación de iOS (macOS)

## 🚀 Instalación y Configuración

### 1. Clonar el Repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd omnistream_iptv
```

### 2. Configurar Variables de Entorno

#### En Linux/macOS:

```bash
./scripts/setup_env.sh
```

#### En Windows:

```bash
scripts\setup_env.bat
```

Este script te guiará para introducir tus claves de Firebase y otros servicios de forma segura. Se creará un archivo `.env` que **nunca debe ser commiteado**.

### 3. Instalar Dependencias

```bash
flutter pub get
```

### 4. Generar Código (Code Generation)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Ejecutar la Aplicación

#### En dispositivo/emulador Android:

```bash
flutter run -d android
```

#### En simulador/dispositivo iOS:

```bash
flutter run -d ios
```

#### En navegador (Web):

```bash
flutter run -d chrome
```

## 📁 Estructura del Proyecto

```
omnistream_iptv/
├── lib/                          # Código fuente Dart
│   ├── main.dart                # Punto de entrada
│   ├── domain/                  # Lógica de negocio (entidades, repositorios)
│   ├── data/                    # Acceso a datos (APIs, bases de datos)
│   ├── presentation/            # UI y gestión de estado
│   └── core/                    # Utilidades compartidas
├── test/                        # Tests unitarios
├── integration_test/            # Tests de integración
├── .github/
│   └── workflows/
│       └── flutter_ci.yml       # Pipeline de CI/CD
├── scripts/
│   ├── setup_env.sh            # Script de configuración (Linux/macOS)
│   └── setup_env.bat           # Script de configuración (Windows)
├── pubspec.yaml                # Dependencias del proyecto
├── analysis_options.yaml       # Configuración de análisis de código
├── .env.example                # Plantilla de variables de entorno
├── firebase.json               # Configuración de Firebase
└── README.md                   # Este archivo
```

## 🔐 Seguridad

### Gestión de Claves API

- **Nunca** hardcodees claves API en el código
- Usa el archivo `.env` para variables sensibles
- El archivo `.env` está en `.gitignore` y no será commiteado
- Usa `.env.example` como plantilla para documentar qué variables se necesitan

### Mejores Prácticas

1. Rota tus claves API regularmente
2. Usa claves diferentes para dev, staging y producción
3. Revoca claves comprometidas inmediatamente
4. Usa Firebase Security Rules para proteger datos en la nube

## 🧪 Testing

### Tests Unitarios

```bash
flutter test
```

### Tests de Integración

```bash
flutter test integration_test/
```

### Análisis de Código

```bash
flutter analyze
```

### Verificar Formato

```bash
dart format --set-exit-if-changed lib/ test/
```

## 📊 CI/CD Pipeline

El proyecto usa **GitHub Actions** para automatizar:

- ✅ Análisis de código (`flutter analyze`)
- ✅ Ejecución de tests (`flutter test`)
- ✅ Compilación de APK (Android)
- ✅ Compilación de iOS
- ✅ Compilación Web
- ✅ Verificación de cobertura de código

Los workflows se ejecutan automáticamente en cada push a `main` o `develop`.

## 📝 Convenciones de Código

### Estructura de Carpetas (Clean Architecture)

```
lib/
├── domain/
│   ├── entities/          # Modelos de dominio
│   ├── repositories/      # Interfaces de repositorios
│   └── usecases/         # Casos de uso
├── data/
│   ├── datasources/      # Acceso a APIs y BD
│   ├── models/           # Modelos de datos (con serialización)
│   └── repositories/     # Implementación de repositorios
└── presentation/
    ├── pages/            # Pantallas
    ├── widgets/          # Componentes reutilizables
    ├── providers/        # Riverpod providers
    └── state/            # Gestión de estado
```

### Naming Conventions

- **Archivos**: `snake_case` (ej: `user_repository.dart`)
- **Clases**: `PascalCase` (ej: `UserRepository`)
- **Variables/Funciones**: `camelCase` (ej: `getUserData()`)
- **Constantes**: `CONSTANT_CASE` (ej: `const MAX_RETRIES = 3`)

### Linting

El proyecto usa `flutter_lints` para mantener la calidad del código. Todas las reglas están configuradas en `analysis_options.yaml`.

## 🐛 Debugging

### Logs

Usa el paquete `logger` para logging estructurado:

```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.i('Información');
logger.w('Advertencia');
logger.e('Error', error: exception);
```

### Sentry

Los errores se reportan automáticamente a Sentry (si está configurado). Puedes ver los reportes en tu dashboard de Sentry.

## 📚 Documentación Adicional

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Hive Documentation](https://docs.hivedb.dev)

## 🤝 Contribuir

1. Crea una rama para tu feature: `git checkout -b feature/mi-feature`
2. Commit tus cambios: `git commit -am 'Añade mi feature'`
3. Push a la rama: `git push origin feature/mi-feature`
4. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo licencia MIT. Ver `LICENSE` para más detalles.

## 📧 Contacto

Para preguntas o sugerencias, contacta al equipo de desarrollo.

---

**Última actualización**: Enero 2026


## 🔥 Configuración de Firebase

Para que la integración con Firebase funcione correctamente, es **crucial** añadir el archivo `google-services.json` en la siguiente ruta:

```
android/app/google-services.json
```

Si este archivo no está presente, la aplicación mostrará una advertencia en la consola y continuará ejecutándose sin las funcionalidades de Firebase (sincronización en la nube, Crashlytics, etc.).
