# Guía de Contribución - OmniStream IPTV

Gracias por tu interés en contribuir a OmniStream IPTV. Este documento proporciona directrices para contribuir al proyecto.

## 📋 Antes de Empezar

- Asegúrate de tener Flutter 3.0.0+ instalado
- Lee el README.md para entender la estructura del proyecto
- Familiarízate con Clean Architecture y Riverpod

## 🔄 Flujo de Contribución

### 1. Fork y Clone

```bash
git clone https://github.com/tu-usuario/omnistream_iptv.git
cd omnistream_iptv
```

### 2. Crear una Rama

```bash
git checkout -b feature/descripcion-corta
```

**Convenciones de nombres de ramas:**

- `feature/` - Nueva funcionalidad
- `bugfix/` - Corrección de bug
- `refactor/` - Refactorización de código
- `docs/` - Actualización de documentación
- `test/` - Adición de tests

### 3. Hacer Cambios

- Sigue las convenciones de código del proyecto
- Ejecuta `flutter analyze` para verificar la calidad
- Ejecuta `flutter test` para asegurar que los tests pasen
- Ejecuta `dart format` para formatear el código

```bash
flutter analyze
flutter test
dart format lib/ test/
```

### 4. Commit

**Mensajes de commit:**

```
<tipo>(<alcance>): <descripción breve>

<descripción detallada opcional>

<referencias a issues>
```

**Tipos de commit:**

- `feat:` - Nueva funcionalidad
- `fix:` - Corrección de bug
- `docs:` - Cambios en documentación
- `style:` - Cambios de formato (sin lógica)
- `refactor:` - Refactorización de código
- `test:` - Adición o modificación de tests
- `chore:` - Cambios en build, dependencias, etc.

**Ejemplos:**

```bash
git commit -m "feat(player): add auto-reconnect with exponential backoff"
git commit -m "fix(epg): resolve fuzzy matching for channel names"
git commit -m "docs: update installation instructions"
```

### 5. Push y Pull Request

```bash
git push origin feature/descripcion-corta
```

Luego abre un Pull Request en GitHub con:

- **Título descriptivo**
- **Descripción clara** de los cambios
- **Referencia a issues** relacionados (ej: `Closes #123`)
- **Screenshots** si es un cambio visual

## 🧪 Testing

### Escribir Tests

Todos los cambios deben incluir tests:

```dart
void main() {
  group('UserRepository', () {
    test('should return user data when successful', () async {
      // Arrange
      final mockDataSource = MockUserDataSource();
      final repository = UserRepository(mockDataSource);

      // Act
      final result = await repository.getUser('123');

      // Assert
      expect(result, isA<User>());
    });
  });
}
```

### Ejecutar Tests

```bash
# Tests unitarios
flutter test

# Tests de integración
flutter test integration_test/

# Con cobertura
flutter test --coverage
```

## 📐 Arquitectura y Estructura

### Clean Architecture

El proyecto sigue Clean Architecture con tres capas:

```
Domain Layer (Lógica de negocio pura)
    ↓
Data Layer (Acceso a datos)
    ↓
Presentation Layer (UI y estado)
```

### Ejemplo de Estructura para una Feature

```
lib/
├── domain/
│   ├── entities/
│   │   └── channel.dart
│   ├── repositories/
│   │   └── channel_repository.dart
│   └── usecases/
│       └── get_channels.dart
├── data/
│   ├── datasources/
│   │   └── channel_remote_datasource.dart
│   ├── models/
│   │   └── channel_model.dart
│   └── repositories/
│       └── channel_repository_impl.dart
└── presentation/
    ├── pages/
    │   └── channels_page.dart
    ├── widgets/
    │   └── channel_tile.dart
    └── providers/
        └── channels_provider.dart
```

## 🎨 Guía de Estilo

### Dart/Flutter

- Usa `const` siempre que sea posible
- Evita `var`, usa tipos explícitos
- Usa `final` para variables que no cambian
- Sigue las reglas de `flutter_lints`

```dart
// ✅ Bien
const String appName = 'OmniStream IPTV';
final List<Channel> channels = [];
final int maxRetries = 3;

// ❌ Mal
var appName = 'OmniStream IPTV';
String channels = '';
int MAX_RETRIES = 3;
```

### Comentarios

```dart
/// Documentación de función (triple slash)
/// Explica qué hace, parámetros y retorno
int calculateBufferSize(int connectionSpeed) {
  // Comentario de línea para lógica compleja
  return connectionSpeed > 10 ? 1024 : 512;
}
```

### Imports

```dart
// 1. Dart imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:riverpod/riverpod.dart';

// 4. Relative imports
import '../models/user.dart';
```

## 🔍 Checklist Antes de Hacer Push

- [ ] Código formateado (`dart format`)
- [ ] Sin warnings de análisis (`flutter analyze`)
- [ ] Tests pasan (`flutter test`)
- [ ] Cobertura de código > 80%
- [ ] Commits con mensajes descriptivos
- [ ] PR con descripción clara
- [ ] Sin conflictos con `main`

## 🚀 Proceso de Review

1. **Automated Checks**: GitHub Actions ejecuta análisis y tests
2. **Code Review**: Al menos un maintainer revisa el código
3. **Feedback**: Se pueden solicitar cambios
4. **Merge**: Una vez aprobado, se mergea a `main`

## 📚 Recursos Útiles

- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Riverpod Guide](https://riverpod.dev)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)

## ❓ Preguntas o Problemas

- Abre un issue en GitHub
- Participa en las discusiones
- Contacta a los maintainers

---

¡Gracias por contribuir a OmniStream IPTV! 🎉
