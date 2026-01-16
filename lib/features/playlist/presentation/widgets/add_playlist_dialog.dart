import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Portapapeles
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:uuid/uuid.dart';

class AddPlaylistDialog extends StatefulWidget {
  const AddPlaylistDialog({super.key});

  @override
  State<AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<AddPlaylistDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _m3uUrlController = TextEditingController();
  final _serverController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      String finalUrl = '';

      if (_tabController.index == 0) {
        // MODO M3U
        finalUrl = _m3uUrlController.text.trim();
      } else {
        // MODO XTREAM CODES
        String server = _serverController.text.trim();
        if (!server.startsWith('http://') && !server.startsWith('https://')) {
          server = 'http://$server';
        }

        final user = _userController.text.trim();
        final pass = _passwordController.text.trim();

        // Construimos URL manualmente para no tocar Base de Datos
        finalUrl =
            '$server/get.php?username=$user&password=$pass&type=m3u_plus&output=ts';
      }

      final profile = PlaylistProfile(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        url: finalUrl,
      );

      context.read<PlaylistProfileBloc>().add(AddProfileEvent(profile));
      Navigator.of(context).pop();
    }
  }

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        controller.text = data!.text!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- CABECERA ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: const Text(
                      'Añadir Nueva Lista',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // --- FORMULARIO ---
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Nombre de la lista',
                            icon: Icons.label,
                          ),
                          const SizedBox(height: 20),

                          // TABS
                          Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: "M3U"),
                                Tab(text: "Xtream Codes"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          // CONTENIDO CAMBIANTE
                          SizedBox(
                            height: 320,
                            child: TabBarView(
                              controller: _tabController,
                              // Si en tu Flutter esta propiedad existe y quieres,
                              // puedes descomentar para evitar recortes:
                              // clipBehavior: Clip.none,
                              children: [
                                // TAB 1: M3U
                                Padding(
                                  // ✅ CLAVE: aire arriba para que la label flotante no se recorte
                                  padding: const EdgeInsets.only(top: 10),
                                  child: _buildTextField(
                                    controller: _m3uUrlController,
                                    label: 'URL de la lista (.m3u)',
                                    icon: Icons.link,
                                    maxLines: 4,
                                    allowPaste: true,
                                  ),
                                ),

                                // TAB 2: XTREAM CODES
                                Padding(
                                  // ✅ CLAVE: aire arriba para que la label de “Servidor” no se recorte
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      _buildTextField(
                                        controller: _serverController,
                                        label: 'Servidor (http://...)',
                                        icon: Icons.dns,
                                        allowPaste: true,
                                      ),
                                      const SizedBox(height: 15),
                                      _buildTextField(
                                        controller: _userController,
                                        label: 'Usuario',
                                        icon: Icons.person,
                                      ),
                                      const SizedBox(height: 15),
                                      _buildTextField(
                                        controller: _passwordController,
                                        label: 'Contraseña',
                                        icon: Icons.lock,
                                        isPassword: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // --- BOTONES ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'CANCELAR',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 15),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 25,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _submit,
                                child: const Text(
                                  'GUARDAR',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    int maxLines = 1,
    bool allowPaste = false,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
      obscureText: isPassword,
      maxLines: maxLines,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Icon(icon, color: Colors.white30, size: 20),
        suffixIcon: allowPaste
            ? IconButton(
                icon: const Icon(
                  Icons.content_paste,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                onPressed: () => _pasteFromClipboard(controller),
                tooltip: 'Pegar',
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54, width: 1),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) {
        final isM3uTab = _tabController.index == 0;

        if (label.contains('Nombre') && (v == null || v.isEmpty)) {
          return 'Requerido';
        }

        if (isM3uTab && label.contains('URL') && (v == null || v.isEmpty)) {
          return 'Requerido';
        }

        if (!isM3uTab &&
            !label.contains('URL') &&
            !label.contains('Nombre') &&
            (v == null || v.isEmpty)) {
          return 'Requerido';
        }

        return null;
      },
    );
  }
}
