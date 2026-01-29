import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/core/utils/app_logger.dart';

enum PlaylistSourceType {
  m3uUrl,
  xtreamCodes,
}

/// Full-screen, keyboard-safe wizard to add a playlist.
///
/// Steps:
/// 1) Choose source (M3U URL / Xtream Codes)
/// 2) Enter credentials
/// 3) Name + review
class AddPlaylistFlowPage extends StatefulWidget {
  const AddPlaylistFlowPage({super.key, this.editingProfile});

  /// Si se proporciona, el wizard entra en modo "Editar".
  final PlaylistProfile? editingProfile;

  @override
  State<AddPlaylistFlowPage> createState() => _AddPlaylistFlowPageState();
}

class _AddPlaylistFlowPageState extends State<AddPlaylistFlowPage> {
  static const _stepCount = 3;
  static const _log = AppLogger('playlist.wizard');

  int _step = 0;
  PlaylistSourceType? _source;

  final _formStep2Key = GlobalKey<FormState>();
  final _formStep3Key = GlobalKey<FormState>();

  final _m3uUrlController = TextEditingController();
  final _serverController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();

  late final Listenable _inputListenable;

  final _m3uUrlFocus = FocusNode();
  final _serverFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  final _nameFocus = FocusNode();

  final _scrollController = ScrollController();
  final _m3uUrlFieldKey = GlobalKey();
  final _serverFieldKey = GlobalKey();
  final _userFieldKey = GlobalKey();
  final _passFieldKey = GlobalKey();
  final _nameFieldKey = GlobalKey();

@override
  void initState() {
    super.initState();
    _inputListenable = Listenable.merge([
      _m3uUrlController,
      _serverController,
      _userController,
      _passController,
      _nameController,
    ]);

    // Auto-scroll focused inputs into view (keyboard + compact mode).
    _m3uUrlFocus.addListener(() {
      if (_m3uUrlFocus.hasFocus) _ensureFieldVisible(_m3uUrlFieldKey);
    });
    _serverFocus.addListener(() {
      if (_serverFocus.hasFocus) _ensureFieldVisible(_serverFieldKey);
    });
    _userFocus.addListener(() {
      if (_userFocus.hasFocus) _ensureFieldVisible(_userFieldKey);
    });
    _passFocus.addListener(() {
      if (_passFocus.hasFocus) _ensureFieldVisible(_passFieldKey);
    });
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) _ensureFieldVisible(_nameFieldKey);
    });

    // Modo edición: precargar campos y saltar la selección inicial.
    final edit = widget.editingProfile;
    if (edit != null) {
      _prefillFromProfile(edit);
    }
  }

  void _prefillFromProfile(PlaylistProfile profile) {
    _log.ui('Prefill edit: id=${profile.id} name="${profile.name}"');
    _nameController.text = profile.name;
    final url = profile.url.trim();

    final type = (profile.type ?? '').toLowerCase();
    final isXtream = type.contains('xtream') || _looksLikeXtreamUrl(url);

    if (isXtream) {
      _source = PlaylistSourceType.xtreamCodes;
      final parsed = _parseXtreamUrl(url);
      if (parsed != null) {
        _serverController.text = parsed.server;
        _userController.text = parsed.username;
        _passController.text = parsed.password;
      } else {
        // Fallback: dejamos la URL completa en servidor para que el usuario la ajuste.
        _serverController.text = url;
      }
      _step = 1;
    } else {
      _source = PlaylistSourceType.m3uUrl;
      _m3uUrlController.text = url;
      _step = 1;
    }
  }

  bool _looksLikeXtreamUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('get.php') && u.contains('username=') && u.contains('password=');
  }

  _ParsedXtream? _parseXtreamUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final username = uri.queryParameters['username'] ?? '';
      final password = uri.queryParameters['password'] ?? '';
      if (username.isEmpty || password.isEmpty) return null;

      // server = scheme://host:port + basePath (si get.php está en subcarpeta)
      final scheme = uri.scheme.isNotEmpty ? uri.scheme : 'http';
      final host = uri.host;
      final port = uri.hasPort ? ':${uri.port}' : '';

      final path = uri.path;
      final idx = path.toLowerCase().lastIndexOf('/get.php');
      final basePath = idx >= 0 ? path.substring(0, idx) : '';
      final server = '$scheme://$host$port$basePath'.replaceAll(RegExp(r'/$'), '');

      return _ParsedXtream(server: server, username: username, password: password);
    } catch (_) {
      return null;
    }
  }
  @override
  void dispose() {
    _m3uUrlController.dispose();
    _serverController.dispose();
    _userController.dispose();
    _passController.dispose();
    _nameController.dispose();

    _m3uUrlFocus.dispose();
    _serverFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _nameFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isPhoneLike {
    final mq = MediaQuery.of(context);
    return mq.size.shortestSide < 600;
  }


void _ensureFieldVisible(GlobalKey key) {
  // Ensures the currently focused field is visible above the keyboard + action bar.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.18,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  });
}


bool _isCurrentStepValid() {
  // Step 0: choose source
  if (_step == 0) return _source != null;

  // Step 1: credentials
  if (_step == 1) {
    if (_source == PlaylistSourceType.m3uUrl) {
      final url = _m3uUrlController.text.trim();
      return url.isNotEmpty;
    }
    if (_source == PlaylistSourceType.xtreamCodes) {
      final server = _serverController.text.trim();
      final user = _userController.text.trim();
      final pass = _passController.text.trim();
      return server.isNotEmpty && user.isNotEmpty && pass.isNotEmpty;
    }
    return false;
  }

  // Step 2: name/review
  if (_step == 2) {
    return _nameController.text.trim().isNotEmpty;
  }

  return false;
}

  void _setSource(PlaylistSourceType type) {
    setState(() {
      _source = type;
      _step = math.min(_step + 1, _stepCount - 1);
    });

    // Move focus to the first input of step 2.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (_source) {
        case PlaylistSourceType.m3uUrl:
          _m3uUrlFocus.requestFocus();
          break;
        case PlaylistSourceType.xtreamCodes:
          _serverFocus.requestFocus();
          break;
        case null:
          break;
      }
    });
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _step = math.max(0, _step - 1);
      if (_step == 0) _source = null;
    });
  }

  void _nextOrSave() {
    FocusScope.of(context).unfocus();

    // Step 0 -> 1 is driven by choosing a card.
    if (_step == 0) return;

    if (_step == 1) {
      final ok = _formStep2Key.currentState?.validate() ?? false;
      if (!ok) return;
      setState(() => _step = 2);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nameFocus.requestFocus();
      });
      return;
    }

    // Step 2: validate name and submit.
    final ok = _formStep3Key.currentState?.validate() ?? false;
    if (!ok) return;

    final name = _nameController.text.trim();

    String url;
    String? username;
    String? password;

    if (_source == PlaylistSourceType.m3uUrl) {
      url = _m3uUrlController.text.trim();
    } else {
      final server = _normalizeBaseUrl(_serverController.text);
      username = _userController.text.trim();
      password = _passController.text.trim();
      url = _buildXtreamM3uUrl(server: server, username: username, password: password);
    }

    final bloc = context.read<PlaylistProfileBloc>();
    final editing = widget.editingProfile;

    if (editing != null) {
      _log.ui('Update playlist: id=${editing.id} name="$name"');
      bloc.add(
        UpdateProfileEvent(
          existing: editing,
          name: name,
          url: url,
          username: username,
          password: password,
        ),
      );
    } else {
      _log.ui('Add playlist: name="$name"');
      bloc.add(
        AddProfileEvent(
          name: name,
          url: url,
          username: username,
          password: password,
        ),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(editing != null ? 'Lista actualizada' : 'Lista añadida')),
      );
      Navigator.of(context).pop(true);
    }
  }

  String _normalizeBaseUrl(String input) {
    var server = input.trim();
    if (server.isEmpty) return server;
    if (!server.startsWith('http://') && !server.startsWith('https://')) {
      server = 'http://$server';
    }
    if (server.endsWith('/')) server = server.substring(0, server.length - 1);
    return server;
  }

  String _buildXtreamM3uUrl({
    required String server,
    required String username,
    required String password,
  }) {
    return '$server/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
  }

  @override
Widget build(BuildContext context) {
  final mq = MediaQuery.of(context);
  final isLandscape = mq.orientation == Orientation.landscape;
  final viewInsets = mq.viewInsets;
  final keyboardOpen = viewInsets.bottom > 0;

  /// Compact mode ONLY for the wizard:
  /// - Always compact if height is very small
  /// - Or if we're in landscape AND the keyboard is open
  final isCompact = mq.size.height < 420 || (isLandscape && keyboardOpen);

  return Scaffold(
    backgroundColor: Colors.black,
    // Avoid the classic "body shrinks / jumps" issues when the keyboard appears
    // (especially noticeable in landscape and on TV devices).
    resizeToAvoidBottomInset: false,
    body: SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              if (!isCompact)
                _Header(
                  step: _step,
                  source: _source,
                  isEditing: widget.editingProfile != null,
                  onBack: () {
                    if (_step == 0) {
                      Navigator.of(context).maybePop();
                    } else {
                      _back();
                    }
                  },
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        isCompact ? 56 : 12,
                        16,
                        // Leave room for keyboard + bottom action bar.
                        (isLandscape ? 120 : 150) + (keyboardOpen ? viewInsets.bottom : 0),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isCompact) _StepChips(step: _step, source: _source),
                                    const SizedBox(height: 12),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 220),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: _buildStepContent(key: ValueKey(_step)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // When the keyboard is open, the hint steals space and makes scrolling feel "off".
                            if (!keyboardOpen) _FooterHint(step: _step, source: _source),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          if (isCompact)
            Positioned(
              top: 8,
              right: 8,
              child: _TopPillAction(
                icon: _step == 0 ? Icons.close_rounded : Icons.arrow_back_rounded,
                label: _step == 0 ? 'Cerrar' : 'Atrás',
                onTap: () {
                  if (_step == 0) {
                    Navigator.of(context).maybePop();
                  } else {
                    _back();
                  }
                },
              ),
            ),

          // Bottom action bar (keyboard-safe). We keep it in an overlay so the body doesn't "jump".
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: viewInsets.bottom,
                ),
                child: AnimatedBuilder(
                  animation: _inputListenable,
                  builder: (context, _) => _ActionBar(
                    step: _step,
                    canContinue: _isCurrentStepValid(),
                    onBack: _back,
                    onNextOrSave: _nextOrSave,
                    isPhoneLike: _isPhoneLike,
                    isCompact: isCompact,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildStepContent({Key? key}) {

    switch (_step) {
      case 0:
        return _StepChooseSource(
          key: key,
          isPhoneLike: _isPhoneLike,
          onSelect: _setSource,
        );
      case 1:
        return _StepCredentials(
          key: key,
          source: _source!,
          formKey: _formStep2Key,
          m3uUrlController: _m3uUrlController,
          serverController: _serverController,
          userController: _userController,
          passController: _passController,
          m3uUrlFocus: _m3uUrlFocus,
          serverFocus: _serverFocus,
          userFocus: _userFocus,
          passFocus: _passFocus,
          m3uUrlFieldKey: _m3uUrlFieldKey,
          serverFieldKey: _serverFieldKey,
          userFieldKey: _userFieldKey,
          passFieldKey: _passFieldKey,
          onSubmitted: _nextOrSave,
        );
      case 2:
      default:
        final serverNorm = _normalizeBaseUrl(_serverController.text);
        final genUrl = _source == PlaylistSourceType.xtreamCodes
            ? _buildXtreamM3uUrl(
                server: serverNorm,
                username: _userController.text.trim(),
                password: _passController.text.trim(),
              )
            : _m3uUrlController.text.trim();
        return _StepNameReview(
          key: key,
          source: _source!,
          formKey: _formStep3Key,
          nameController: _nameController,
          nameFocus: _nameFocus,
          nameFieldKey: _nameFieldKey,
          m3uUrl: _m3uUrlController.text.trim(),
          server: _serverController.text.trim(),
          username: _userController.text.trim(),
          password: _passController.text.trim(),
          generatedUrl: genUrl,
        );
    }
  }
}

class _ParsedXtream {
  final String server;
  final String username;
  final String password;
  const _ParsedXtream({required this.server, required this.username, required this.password});
}

class _TopPillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopPillAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.source,
    required this.isEditing,
    required this.onBack,
  });

  final int step;
  final PlaylistSourceType? source;
  final bool isEditing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final title = switch (step) {
      0 => isEditing ? 'Editar lista' : 'Añadir lista',
      1 => isEditing ? 'Editar conexión' : 'Conecta tu proveedor',
      2 => isEditing ? 'Revisión y guardado' : 'Revisión final',
      _ => 'Añadir lista',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _StepChips(step: step, source: source),
        ],
      ),
    );
  }
}

class _StepChips extends StatelessWidget {
  const _StepChips({required this.step, required this.source});

  final int step;
  final PlaylistSourceType? source;

  @override
  Widget build(BuildContext context) {
    Widget chip(String text, int idx) {
      final selected = step == idx;
      final enabled = idx <= step;
      return Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? Colors.white.withOpacity(0.30) : Colors.white.withOpacity(0.16),
            ),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      );
    }

    final sourceLabel = source == null
        ? '1 · Fuente'
        : (source == PlaylistSourceType.m3uUrl ? '1 · M3U' : '1 · Xtream');

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip(sourceLabel, 0),
        chip('2 · Datos', 1),
        chip('3 · Nombre', 2),
      ],
    );
  }
}

class _StepChooseSource extends StatelessWidget {
  const _StepChooseSource({
    super.key,
    required this.onSelect,
    required this.isPhoneLike,
  });

  final ValueChanged<PlaylistSourceType> onSelect;
  final bool isPhoneLike;

@override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        );
    final subStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withOpacity(0.8),
        );

    final cards = [
      _SourceCard(
        icon: Icons.link_rounded,
        title: 'M3U por URL',
        subtitle: 'Pega el enlace de tu lista (m3u/m3u8).',
        onTap: () => onSelect(PlaylistSourceType.m3uUrl),
      ),
      _SourceCard(
        icon: Icons.vpn_key_rounded,
        title: 'Xtream Codes',
        subtitle: 'Servidor + usuario + contraseña.',
        onTap: () => onSelect(PlaylistSourceType.xtreamCodes),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Elige tu fuente', style: titleStyle),
        const SizedBox(height: 6),
        Text('Un flujo único para reducir bugs y mejorar el alta.', style: subStyle),
        const SizedBox(height: 16),
        if (isPhoneLike)
          ...[
            cards[0],
            const SizedBox(height: 12),
            cards[1],
          ]
        else
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
        const SizedBox(height: 14),
        Text(
          'Tip: si tu proveedor es Xtream, la app generará automáticamente el M3U compatible.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.65),
              ),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.75),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.75)),
          ],
        ),
      ),
    );
  }
}

class _StepCredentials extends StatelessWidget {
  const _StepCredentials({
    super.key,
    required this.source,
    required this.formKey,
    required this.m3uUrlController,
    required this.serverController,
    required this.userController,
    required this.passController,
    required this.m3uUrlFocus,
    required this.serverFocus,
    required this.userFocus,
    required this.passFocus,
    this.m3uUrlFieldKey,
    this.serverFieldKey,
    this.userFieldKey,
    this.passFieldKey,
    required this.onSubmitted,
  });

  final PlaylistSourceType source;
  final GlobalKey<FormState> formKey;

  final TextEditingController m3uUrlController;
  final TextEditingController serverController;
  final TextEditingController userController;
  final TextEditingController passController;

  final FocusNode m3uUrlFocus;
  final FocusNode serverFocus;
  final FocusNode userFocus;
  final FocusNode passFocus;

  final Key? m3uUrlFieldKey;
  final Key? serverFieldKey;
  final Key? userFieldKey;
  final Key? passFieldKey;

  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final title = source == PlaylistSourceType.m3uUrl ? 'Pega tu URL' : 'Credenciales Xtream';
    final subtitle = source == PlaylistSourceType.m3uUrl
        ? 'Asegúrate de que el enlace empiece por http(s) y sea accesible.'
        : 'Introducir servidor, usuario y contraseña (se genera M3U automáticamente).';

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 16),
          if (source == PlaylistSourceType.m3uUrl) ...[
            _CinematicTextField(
              key: m3uUrlFieldKey,
              controller: m3uUrlController,
              focusNode: m3uUrlFocus,
              label: 'URL M3U',
              hint: 'https://...',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmitted(),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'La URL es obligatoria';
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'Debe empezar por http:// o https://';
                }
                return null;
              },
            ),
          ] else ...[
            _CinematicTextField(
              key: serverFieldKey,
              controller: serverController,
              focusNode: serverFocus,
              label: 'Servidor',
              hint: 'http://mi-servidor:8080',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => userFocus.requestFocus(),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'El servidor es obligatorio';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _CinematicTextField(
              key: userFieldKey,
              controller: userController,
              focusNode: userFocus,
              label: 'Usuario',
              hint: 'username',
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => passFocus.requestFocus(),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'El usuario es obligatorio';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _CinematicTextField(
              key: passFieldKey,
              controller: passController,
              focusNode: passFocus,
              label: 'Contraseña',
              hint: 'password',
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmitted(),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'La contraseña es obligatoria';
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _StepNameReview extends StatelessWidget {
  const _StepNameReview({
    super.key,
    required this.source,
    required this.formKey,
    required this.nameController,
    required this.nameFocus,
    this.nameFieldKey,
    required this.m3uUrl,
    required this.server,
    required this.username,
    required this.password,
    required this.generatedUrl,
  });

  final PlaylistSourceType source;
  final GlobalKey<FormState> formKey;

  final TextEditingController nameController;
  final FocusNode nameFocus;
  final Key? nameFieldKey;

  final String m3uUrl;
  final String server;
  final String username;
  final String password;
  final String generatedUrl;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ponle un nombre',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Será el nombre que verás en tu biblioteca.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 16),
          _CinematicTextField(
            key: nameFieldKey,
            controller: nameController,
            focusNode: nameFocus,
            label: 'Nombre de la lista',
            hint: 'Mi IPTV',
            textInputAction: TextInputAction.done,
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'El nombre es obligatorio';
              return null;
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Resumen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          _SummaryTile(
            icon: source == PlaylistSourceType.m3uUrl ? Icons.link_rounded : Icons.flash_on_rounded,
            title: source == PlaylistSourceType.m3uUrl ? 'M3U por URL' : 'Xtream Codes',
            lines: source == PlaylistSourceType.m3uUrl
                ? [m3uUrl]
                : [
                    'URL generada: $generatedUrl',
                    'Servidor: $server',
                    'Usuario: $username',
                    'Contraseña: ${password.isEmpty ? '' : '••••••••'}',
                  ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                ...lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      l,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.75),
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.step,
    required this.canContinue,
    required this.onBack,
    required this.onNextOrSave,
    required this.isPhoneLike,
    required this.isCompact,
  });

  final int step;
  final bool canContinue;
  final VoidCallback onBack;
  final VoidCallback onNextOrSave;
  final bool isPhoneLike;
  final bool isCompact;

@override
  Widget build(BuildContext context) {
    final isLast = step == 2;
    final primaryText = isLast ? 'Guardar' : 'Continuar';
    final secondaryText = step == 0 ? 'Cancelar' : 'Atrás';

    final buttonHeight = isCompact ? (isPhoneLike ? 46.0 : 50.0) : (isPhoneLike ? 54.0 : 58.0);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.22)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                backgroundColor: Colors.white.withOpacity(0.08),
              ),
              child: Text(
                secondaryText,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: canContinue ? onNextOrSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withOpacity(0.20),
                disabledForegroundColor: Colors.white.withOpacity(0.55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                primaryText,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterHint extends StatelessWidget {
  const _FooterHint({
    required this.step,
    required this.source,
  });

  final int step;
  final PlaylistSourceType? source;

  @override
  Widget build(BuildContext context) {
    final text = switch (step) {
      0 => 'Elige cómo quieres añadir tu lista. Luego podrás editarla en Ajustes.',
      1 => (source == PlaylistSourceType.m3uUrl)
          ? 'Consejo: pega la URL completa (http/https). Si es privada, asegúrate de incluir usuario/clave si aplica.'
          : 'Consejo: el “Server URL” suele ser http(s)://dominio:puerto (sin /get.php).',
      2 => 'Dale un nombre corto y reconocible. Será el que verás en “Mis listas”.',
      _ => '',
    };

    if (text.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.white.withOpacity(0.85)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.82),
                        height: 1.25,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CinematicTextField extends StatelessWidget {
  const _CinematicTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white.withOpacity(0.85),
          fontWeight: FontWeight.w700,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.45)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.30), width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.8)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.9), width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CinematicBackground extends StatelessWidget {
  const _CinematicBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF05070F),
            Color(0xFF070B1C),
            Color(0xFF03040A),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -110,
            child: _GlowOrb(size: 310, color: Color(0xFF7C3AED)),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: _GlowOrb(size: 340, color: Color(0xFF22D3EE)),
          ),
          Positioned(
            top: 120,
            left: -80,
            child: _GlowOrb(size: 230, color: Color(0xFFFF2D95)),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.55),
            color.withOpacity(0.18),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
