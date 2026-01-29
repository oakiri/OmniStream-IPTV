# Release checklist (Play Store / TV)

## Antes de generar AAB/APK release

- [ ] `flutter clean` && `flutter pub get`
- [ ] Incrementar versión en `pubspec.yaml` (versionName/versionCode)
- [ ] Revisar `android/app/build.gradle.kts`:
  - `applicationId` definitivo (no `com.example.*`)
  - `minSdk`/`targetSdk` alineados
  - `signingConfig` (keystore)
- [ ] Verificar `android/app/src/main/AndroidManifest.xml`:
  - `LEANBACK_LAUNCHER` (TV)
  - `android:banner` (si se quiere un banner específico de TV)
- [ ] Revisar permisos y features (solo los necesarios)
- [ ] Probar en:
  - [ ] Móvil (touch + teclado + rotación)
  - [ ] Google TV / Xiaomi Box (D-Pad focus + launcher)

## Smoke tests

- [ ] Añadir playlist (M3U y Xtream)
- [ ] Ver “Mis Listas” (shimmer, cards, borrar lista)
- [ ] Continuar viendo (reanudar último canal y acceso a /channels)
- [ ] Canales (búsqueda + multi-categoría)
- [ ] Player (reproducir, abrir guía, volver)
