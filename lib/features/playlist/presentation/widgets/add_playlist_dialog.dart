import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omnistream_iptv/features/playlist/domain/entities/playlist_profile.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';
import 'package:uuid/uuid.dart';

class AddPlaylistDialog extends StatefulWidget {
  const AddPlaylistDialog({super.key});

  @override
  State<AddPlaylistDialog> createState() => _AddPlaylistDialogState();
}

class _AddPlaylistDialogState extends State<AddPlaylistDialog> with SingleTickerProviderStateMixin {
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
        finalUrl = _m3uUrlController.text.trim();
      } else {
        String server = _serverController.text.trim();
        if (!server.startsWith('http://') && !server.startsWith('https://')) {
          server = 'http://$server';
        }
        final user = _userController.text.trim();
        final pass = _passwordController.text.trim();
        finalUrl = '$server/get.php?username=$user&password=$pass&type=m3u_plus&output=ts';
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

  @override
  Widget build(BuildContext context) {
    // Usamos Dialog con background transparente para que el Scaffold de abajo tenga control
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // ESTO ES LA CLAVE: El Scaffold empuja el contenido hacia arriba cuando sale el teclado
        resizeToAvoidBottomInset: true, 
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), // Fondo Gris Oscuro Premium
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12), // Borde sutil
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CABECERA
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: const Text(
                      'Añadir Nueva Lista',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // FORMULARIO
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(_nameController, 'Nombre de la lista', Icons.label),
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
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey,
                              tabs: const [
                                Tab(text: "M3U"),
                                Tab(text: "Xtream Codes"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // CONTENIDO TABS
                          SizedBox(
                            height: 200, // Altura fija para evitar saltos bruscos
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // TAB 1: M3U
                                Center(
                                  child: _buildTextField(_m3uUrlController, 'URL (.m3u)', Icons.link, maxLines: 3),
                                ),
                                // TAB 2: Xtream
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTextField(_serverController, 'Servidor (http://...)', Icons.dns),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildTextField(_userController, 'Usuario', Icons.person)),
                                        const SizedBox(width: 12),
                                        Expanded(child: _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),
                          
                          // BOTONES ACCIÓN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                onPressed: _submit,
                                child: const Text('GUARDAR LISTA', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {bool isPassword = false, int maxLines = 1}
  ) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: isPassword,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (v) {
        // Validación simple: solo validamos si la pestaña actual corresponde al campo
        bool isM3uTab = _tabController.index == 0;
        if (label.contains('Nombre') && (v == null || v.isEmpty)) return 'Requerido';
        if (isM3uTab && label.contains('URL') && (v == null || v.isEmpty)) return 'Requerido';
        if (!isM3uTab && !label.contains('URL') && !label.contains('Nombre') && (v == null || v.isEmpty)) return 'Requerido';
        return null;
      },
    );
  }
}