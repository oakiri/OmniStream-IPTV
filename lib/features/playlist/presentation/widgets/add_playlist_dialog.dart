import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omnistream_iptv/core/widgets/cinematic_theme.dart';
import 'package:omnistream_iptv/features/playlist/presentation/bloc/playlist_profile_bloc.dart';

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
      String? username;
      String? password;

      if (_tabController.index == 0) {
        // M3U
        finalUrl = _m3uUrlController.text.trim();
      } else {
        // XTREAM
        String server = _serverController.text.trim();
        if (!server.startsWith('http://') && !server.startsWith('https://')) {
          server = 'http://$server';
        }
        username = _userController.text.trim();
        password = _passwordController.text.trim();
        finalUrl = '$server/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
      }

      // IMPORTANTE: Aquí enviamos los datos separados al Bloc
      context.read<PlaylistProfileBloc>().add(AddProfileEvent(
        name: _nameController.text.trim(),
        url: finalUrl,
        username: username,
        password: password,
      ));

      Navigator.of(context).pop();
    }
  }

  Future<void> _paste(TextEditingController ctrl) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) setState(() => ctrl.text = data!.text!);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650), // Altura segura
            decoration: BoxDecoration(
              color: const Color(0xFF101010).withOpacity(0.95), // Fondo oscuro sólido
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                // Cabecera WOW
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10))
                  ),
                  child: Text(
                    'AÑADIR LISTA', 
                    textAlign: TextAlign.center, 
                    style: GoogleFonts.audiowide(color: Colors.white, fontSize: 18, letterSpacing: 2)
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInput(_nameController, "Nombre", Icons.label, false, false),
                          const SizedBox(height: 24),
                          
                          // Tabs Limpias
                          Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.black, 
                              borderRadius: BorderRadius.circular(12), 
                              border: Border.all(color: Colors.white10)
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: CinematicColors.accent, 
                                borderRadius: BorderRadius.circular(12)
                              ),
                              labelColor: Colors.black,
                              unselectedLabelColor: Colors.grey,
                              labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                              overlayColor: MaterialStateProperty.all(Colors.transparent),
                              dividerColor: Colors.transparent,
                              tabs: const [Tab(text: "URL M3U"), Tab(text: "Xtream Codes")],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            height: 350,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // M3U
                                Column(children: [
                                  _buildInput(_m3uUrlController, "Enlace M3U", Icons.link, false, true),
                                ]),
                                // Xtream
                                Column(children: [
                                  _buildInput(_serverController, "Servidor (http://...)", Icons.dns, false, true),
                                  const SizedBox(height: 16),
                                  _buildInput(_userController, "Usuario", Icons.person, false, true),
                                  const SizedBox(height: 16),
                                  _buildInput(_passwordController, "Contraseña", Icons.lock, true, true),
                                ]),
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
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), 
                        child: Text("CANCELAR", style: GoogleFonts.montserrat(color: Colors.white54, fontWeight: FontWeight.bold))
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, 
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _submit,
                        child: Text("GUARDAR", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, bool isPass, bool paste) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16), // Texto legible
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white30, size: 20),
        suffixIcon: paste 
          ? IconButton(
              icon: const Icon(Icons.paste, size: 20, color: CinematicColors.accent), 
              onPressed: () => _paste(ctrl)
            ) 
          : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        // ARREGLO VISUAL: Padding generoso para que no se corte la fuente
        contentPadding: const EdgeInsets.fromLTRB(16, 22, 16, 22), 
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
    );
  }
}