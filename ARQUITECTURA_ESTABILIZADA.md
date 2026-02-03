# 📢 Arquitectura Estabilizada - OmniStream IPTV

**Fecha**: Enero 2026  
**Estado**: ✅ Aplicación Funcional y Resiliente  
**Rama**: `develop`

---

## ✅ Cambios Realizados (Estabilización)

### 1. **Adiós al Crash de Inicio**
- **Problema**: Si faltaba `google-services.json` o Firebase fallaba, la app crasheaba inmediatamente
- **Solución**: Inyección de dependencias defensiva + Modo Offline con Hive
- **Resultado**: La app entra automáticamente en Modo Offline si Firebase no está disponible
- **Archivos modificados**:
  - `lib/main.dart`: Try-catch en Firebase, inicialización segura
  - `lib/injection_container.dart`: Hive.openBox() explícito antes de registrar

### 2. **Adiós al Crash de Navegación**
- **Problema**: Navigator.push() causaba errores de contexto al abrir listas
- **Solución**: Migración completa a **GoRouter**
- **Resultado**: Navegación estable y predecible
- **Archivos modificados**:
  - `lib/core/router/app_router.dart`: Rutas centralizadas
  - `lib/main.dart`: MaterialApp.router() en lugar de MaterialApp()

### 3. **Limpieza de Código**
- Corregidos imports rotos en Blocs
- Estandarizados eventos en PlaylistBloc
- Eliminados conflictos de TypeAdapter en Hive (CategoryModel: typeId 1 → 3)

---

## ⚠️ Nuevas Reglas de Desarrollo (CRÍTICAS)

### 🚫 Regla 1: Navegación - NUNCA uses Navigator.push()

**INCORRECTO:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => ChannelListPage()),
);
```

**CORRECTO:**
```dart
context.pushNamed('channels', extra: {'playlistId': '123'});
```

**Por qué**: GoRouter gestiona el contexto correctamente y evita errores de contexto que cierran la app.

---

### 🚫 Regla 2: Datos Remotos - Siempre defensivo

**INCORRECTO:**
```dart
final result = await remoteDataSource.getChannels(playlistId);
```

**CORRECTO:**
```dart
try {
  if (remoteDataSource != null) {
    final result = await remoteDataSource.getChannels(playlistId);
    // usar result
  } else {
    // Fallback a Hive
    return await localDataSource.getChannels(playlistId);
  }
} catch (e) {
  // Fallback a Hive
  return await localDataSource.getChannels(playlistId);
}
```

**Por qué**: Firebase puede no estar inicializado. El repositorio debe permitir que remoteDataSource sea null sin crashes.

---

### 🚫 Regla 3: Firebase - Siempre verifica si está inicializado

**INCORRECTO:**
```dart
final user = FirebaseAuth.instance.currentUser;
```

**CORRECTO:**
```dart
try {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // usar user
  }
} catch (e) {
  print('Firebase no inicializado: $e');
  // Continuar sin Firebase
}
```

**Por qué**: En entornos sin credenciales, Firebase puede no estar disponible.

---

## 🎯 Tu Misión: Implementar Parseo de M3U

### Estado Actual
- ✅ Pantalla `/channels` abre correctamente
- ❌ Solo muestra un placeholder con la URL
- ❌ No descarga ni parsea el archivo M3U real

### Objetivo
Conectar el **PlaylistBloc** a la pantalla `/channels` para:
1. Descargar el archivo M3U desde la URL
2. Parsearlo usando `PlaylistParser`
3. Mostrar la lista de canales real

### Dónde Implementar
**Archivo**: `lib/features/playlist/presentation/pages/channel_list_page.dart`

**Estructura esperada**:
```dart
class ChannelListPage extends StatefulWidget {
  final String playlistId;
  
  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  @override
  void initState() {
    super.initState();
    // Trigger PlaylistBloc.getPlaylist(playlistId)
    context.read<PlaylistBloc>().add(GetPlaylistEvent(playlistId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistBloc, PlaylistState>(
      builder: (context, state) {
        if (state is PlaylistLoading) return LoadingWidget();
        if (state is PlaylistError) return ErrorWidget(state.message);
        if (state is PlaylistLoaded) {
          return ChannelGridView(channels: state.channels);
        }
        return SizedBox.shrink();
      },
    );
  }
}
```

---

## 🚀 Antes de Escribir Código

### Checklist Obligatorio
```bash
# 1. Sincronizar con los últimos cambios
git pull origin develop

# 2. Limpiar y reinstalar dependencias
flutter clean
flutter pub get

# 3. Regenerar código generado
dart run build_runner build --delete-conflicting-outputs

# 4. Verificar que compila
flutter build apk --debug

# 5. Analizar código
flutter analyze
```

---

## 📊 Estructura de Datos Esperada

### PlaylistState (después de parseo)
```dart
class PlaylistLoaded extends PlaylistState {
  final List<ChannelModel> channels;
  final String playlistId;
  final DateTime lastUpdated;
  
  PlaylistLoaded({
    required this.channels,
    required this.playlistId,
    required this.lastUpdated,
  });
}
```

### ChannelModel
```dart
class ChannelModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String url;
  final String? group;
}
```

---

## 🔍 Debugging

Si algo falla, revisa estos logs:
```
[MAIN] Initializing Firebase...
[MAIN] Initializing Hive...
[MAIN] Initializing dependency injection...
[PLAYLIST_BLOC] GetPlaylistEvent received
[PLAYLIST_PARSER] Parsing M3U file...
```

Si ves `⚠ [MAIN] Firebase features will be disabled.`, significa que Firebase no está disponible pero la app continúa funcionando.

---

## ✅ Reglas de Commit

Antes de hacer push:
1. `flutter analyze` debe pasar (sin errores críticos)
2. `flutter test` debe pasar (si hay tests)
3. Mensaje de commit: `feat:`, `fix:`, `refactor:`, etc.
4. Ejemplo: `feat: Implementar parseo de M3U en ChannelListPage`

---

## 📞 Soporte Rápido

| Problema | Solución |
|----------|----------|
| App no compila | `flutter clean && flutter pub get && dart run build_runner build` |
| Firebase error | Verifica que `google-services.json` esté en `android/app/` |
| Crash en navegación | Usa `context.pushNamed()` en lugar de `Navigator.push()` |
| Hive error | Asegúrate de que `HiveService().init()` se llamó en `main.dart` |

---

**Última actualización**: Enero 2026  
**Responsable**: Manus AI  
**Estado**: 🟢 Listo para Desarrollo
