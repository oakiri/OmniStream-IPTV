import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_event.dart';

/// Dialog "WOW" para añadir listas.
///
/// Fixes:
/// - El teclado ya no tapa los campos (AnimatedPadding + Scroll).
/// - Labels no se cortan (label superior en vez de floating label).
/// - Validación por pestaña (no obliga a rellenar Xtream si estás en M3U).
class AddPlaylistDialog extends StatefulWidget {
  const AddPlaylistDialog({super.key});

  @override
  State<AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<AddPlaylistDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _nameController = TextEditingController();
  final _m3uUrlController = TextEditingController();
  final _serverController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {})); // para revalidar por tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _m3uUrlController.dispose();
    _serverController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isM3u => _tabController.index == 0;

  String? _requiredIf(bool condition, String? v) {
    if (!condition) return null;
    if (v == null || v.trim().isEmpty) return 'Requerido';
    return null;
  }

  Future<void> _paste(TextEditingController c) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) setState(() => c.text = data!.text!);
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    String finalUrl;
    String? user;
    String? pass;

    if (_isM3u) {
      finalUrl = _m3uUrlController.text.trim();
    } else {
      var server = _serverController.text.trim();
      if (server.endsWith('/')) server = server.substring(0, server.length - 1);
      if (!server.startsWith('http://') && !server.startsWith('https://')) {
        server = 'http://$server';
      }
      user = _userController.text.trim();
      pass = _passwordController.text.trim();
      finalUrl = '$server/get.php?username=$user&password=$pass&type=m3u_plus&output=ts';
    }

    context.read<PlaylistProfileBloc>().add(
          AddProfileEvent(
            name: _nameController.text.trim(),
            url: finalUrl,
            username: user,
            password: pass,
          ),
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.white.withOpacity(0.04),
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212).withOpacity(0.94),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  resizeToAvoidBottomInset: true,
                  body: Column(
                    children: [
                      _Header(onClose: () => Navigator.pop(context)),

                      // Body scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _CinematicField(
                                  label: 'Nombre',
                                  icon: Icons.label_outline,
                                  controller: _nameController,
                                  validator: (v) => _requiredIf(true, v),
                                ),
                                const SizedBox(height: 18),

                                _Tabs(controller: _tabController),
                                const SizedBox(height: 18),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 160),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: _isM3u
                                      ? Column(
                                          key: const ValueKey('m3u'),
                                          children: [
                                            _CinematicField(
                                              label: 'URL M3U',
                                              helper: 'Pega aquí el enlace .m3u/.m3u8',
                                              icon: Icons.link,
                                              controller: _m3uUrlController,
                                              validator: (v) => _requiredIf(true, v),
                                              onPaste: () => _paste(_m3uUrlController),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          key: const ValueKey('xtream'),
                                          children: [
                                            _CinematicField(
                                              label: 'Servidor',
                                              helper: 'Ej: http://midominio:port',
                                              icon: Icons.dns,
                                              controller: _serverController,
                                              validator: (v) => _requiredIf(!_isM3u, v),
                                              onPaste: () => _paste(_serverController),
                                            ),
                                            const SizedBox(height: 14),
                                            _CinematicField(
                                              label: 'Usuario',
                                              icon: Icons.person_outline,
                                              controller: _userController,
                                              validator: (v) => _requiredIf(!_isM3u, v),
                                              onPaste: () => _paste(_userController),
                                            ),
                                            const SizedBox(height: 14),
                                            _CinematicField(
                                              label: 'Contraseña',
                                              icon: Icons.lock_outline,
                                              controller: _passwordController,
                                              validator: (v) => _requiredIf(!_isM3u, v),
                                              obscureText: _obscure,
                                              trailing: IconButton(
                                                icon: Icon(
                                                  _obscure ? Icons.visibility : Icons.visibility_off,
                                                  color: Colors.white24,
                                                  size: 18,
                                                ),
                                                onPressed: () => setState(() => _obscure = !_obscure),
                                                tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: BorderSide(color: Colors.white.withOpacity(0.10)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text('CANCELAR', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CinematicColors.accent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                child: Text('GUARDAR', style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CinematicColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CinematicColors.accent.withOpacity(0.25)),
            ),
            child: const Icon(Icons.add_link, color: CinematicColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'NUEVA LISTA',
              style: GoogleFonts.audiowide(color: Colors.white, fontSize: 16, letterSpacing: 1.2),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            tooltip: 'Cerrar',
          )
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final TabController controller;
  const _Tabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: CinematicColors.accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: CinematicColors.accent.withOpacity(0.30), blurRadius: 14)],
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w900, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
        tabs: const [Tab(text: 'M3U'), Tab(text: 'XTREAM')],
      ),
    );
  }
}

class _CinematicField extends StatelessWidget {
  final String label;
  final String? helper;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final VoidCallback? onPaste;
  final Widget? trailing;

  const _CinematicField({
    required this.label,
    this.helper,
    required this.icon,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.onPaste,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(helper!, style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
        ],
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
          cursorColor: CinematicColors.accent,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white30, size: 20),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null) trailing!,
                if (onPaste != null)
                  IconButton(
                    icon: const Icon(Icons.paste_rounded, color: Colors.white24, size: 18),
                    onPressed: onPaste,
                    tooltip: 'Pegar',
                  ),
              ],
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: CinematicColors.accent.withOpacity(0.75)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
