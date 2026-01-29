# OmniStream IPTV

**OmniStream IPTV** es una app IPTV (móvil + Android TV/Google TV) enfocada en una experiencia **premium**, con UX tipo “Netflix”, zapping rápido y una base sólida para evolucionar hacia EPG y VOD.

## Estado actual (stable)

Incluido en este ZIP (objetivo: PR-1 + PR-2 + PR-3 en una única entrega estable):

### 1) Listas / Dashboard
- ✅ Dashboard “Mis Listas” estilo Netflix (vertical list)
- ✅ Tarjetas WOW (cinematic glow + glass + badges + focus reactive en TV)
- ✅ Shimmer loading (skeleton)
- ✅ Badges: ACTIVO / CADUCA PRONTO / CADUCADA
- ✅ Continue watching: último canal visto con botones **Reanudar** y **Ir a lista**
- ✅ Editar playlist (⋮): **Nombre + URL (M3U)** y **Server/User/Pass (Xtream)** con reconstrucción de URL
- ✅ Tipografía unificada (Montserrat)

### 2) Añadir playlist (Wizard)
- ✅ Wizard full-screen unificado M3U + Xtream (sin diálogos)
- ✅ Modo compacto solo en wizard (landscape/teclado) + botón “pill” para cerrar

### 3) Canales
- ✅ Vista de canales adaptativa (móvil + TV)
- ✅ Búsqueda en vivo
- ✅ Fix overflow en landscape (header responsive)
- ✅ Multi-selección de categorías (toggle) + estado “All”
- ✅ Highlight del último canal (cuando se entra desde “Continuar viendo”) — **solo borde, sin etiqueta**
- ✅ Opción de **auto-play** del canal inicial (entrada directa y premium)

### 4) Player
- ✅ Reproductor basado en **media_kit**
- ✅ Persistencia del último canal reproducido (al iniciar y al hacer zapping/selección en la guía)
- ✅ Guía EPG (overlay) como base de la Fase 3

### 5) Android TV / Google TV
- ✅ Soporte de launcher TV (LEANBACK_LAUNCHER) para que la app aparezca en la pantalla de apps

## Stack técnico

- **Flutter (Dart)**
- **Estado / UI:** flutter_bloc, go_router
- **DI:** get_it
- **Persistencia local:** Hive
- **Video:** media_kit + media_kit_video

## Setup rápido

1) Instalar dependencias

```bash
flutter pub get
```

2) Ejecutar

```bash
flutter run
```

## Android TV / ADB (lanzar manualmente)

Si necesitas lanzar por ADB:

```bash
adb shell monkey -p com.example.omnistream_iptv -c android.intent.category.LAUNCHER 1
adb shell monkey -p com.example.omnistream_iptv -c android.intent.category.LEANBACK_LAUNCHER 1
```

## Package name (Android)

El package real de instalación lo determina `applicationId`:

- `android/app/build.gradle.kts` → `defaultConfig { applicationId = "com.example.omnistream_iptv" }`

## Roadmap

- **Fase 3: Live / EPG**
  - EPG completa (parsing + caché)
  - “Now/Next” y timeline
  - zapping + overlays premium

- **Fase 4: VOD**
  - Catálogo VOD (movies/series)
  - Integraciones de fuentes (gratuitas y/o servicios)
  - búsquedas, filtros, ficha, trailer, etc.

## Documentación adicional

- `ARQUITECTURA_ESTABILIZADA.md`
- `INFRASTRUCTURE_SETUP.md`
- `NATIVE_CONFIG.md`

