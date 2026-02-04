# Changelog

## Unreleased

- docs(setup): document env + build runner steps
  - Summary: expand quick setup instructions to include .env creation and build_runner generation.
  - Files: README.md
- fix(build): ensure assets directories and env template
  - Summary: add a tracked assets/images placeholder and replace the missing .env asset with .env.example for clean clones.
  - Files: pubspec.yaml, assets/images/.gitkeep
- fix(epg): guard async state + responsive header
  - Summary: add mounted checks around async bootstrap, adapt header/column sizing to avoid overflow on small screens.
  - Files: lib/features/navigation/presentation/pages/epg_timeline_page.dart
- refactor(live): drive Live tab from playlist bloc
  - Summary: replace the hub page with PlaylistBloc-driven timeline rendering and premium empty/error states.
  - Files: lib/features/navigation/presentation/pages/live_page.dart, lib/features/navigation/presentation/pages/live_epg_hub_page.dart
- feat(live): add EPG hub page
  - Summary: create the LiveEpgHubPage to load the last playlist, trigger EPG refresh, and render loading/empty/error states.
  - Files: lib/features/navigation/presentation/pages/live_epg_hub_page.dart
- feat(live): connect Live tab to EPG hub
  - Summary: replace the placeholder LivePage widget with the LiveEpgHubPage entrypoint.
  - Files: lib/features/navigation/presentation/pages/live_page.dart
- feat(epg): add now-based window and go-to-now control
  - Summary: center the timeline on the fixed NOW-2h → NOW+12h window with initial scroll and a go-to-now CTA when users drift away.
  - Files: lib/features/navigation/presentation/pages/epg_timeline_page.dart
- feat(epg): add refresh + shimmer loading
  - Summary: replace the spinner with shimmer skeletons and support pull-to-refresh in the timeline view.
  - Files: lib/features/navigation/presentation/pages/epg_timeline_page.dart

## 0.3.0 (PR-1 + PR-2 + PR-3)

- Dashboard “Mis Listas” estilo Netflix (vertical list) con WOW cards, shimmer y badges.
- “Continuar viendo”: último canal visto con accesos directos (Reanudar / Ir a lista).
- Wizard full-screen unificado M3U/Xtream (modo compacto con teclado/landscape).
- Canales: multi-selección de categorías + búsqueda + auto-play del canal inicial.
- Android TV/Google TV: soporte LEANBACK_LAUNCHER en manifest.
- Tipografía unificada: Montserrat como base de la app.
- Router logs: limitados a modo debug.
