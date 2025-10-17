import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart'; // Importa el audioPlayerProvider

class Settings extends ConsumerStatefulWidget {
  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  bool _musicEnabled = true;
  bool _soundEffectsEnabled = true;
  bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final audioPlayer = ref.watch(audioPlayerProvider); // Accede al AudioPlayer global
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A1B3D), // Morado oscuro
                  Color(0xFF1C1C1C), // Gris oscuro
                  Color(0xFF000000), // Negro
                ],
              ),
            ),
            child: Column(
              children: [
                // Encabezado con logo
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Container(
                    height: size.height * 0.15,
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/skull_logo.png', height: 40),
                          SizedBox(width: 10),
                          Text(
                            'Configuración',
                            style: GoogleFonts.pressStart2p(
                              textStyle: TextStyle(
                                color: Color(0xFF7CFC00), // Verde neón
                                fontSize: size.width > 800 ? 24.0 : size.width * 0.06,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF0B2E62).withOpacity(0.3),
                                    offset: Offset(0.5, 0.5),
                                    blurRadius: 5,
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
                // Contenido
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Ajustes',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildToggleOption(context, 'Música', _musicEnabled, (value) {
                        setState(() => _musicEnabled = value);
                        if (!value) {
                          audioPlayer.pause();
                        } else {
                          audioPlayer.resume();
                        }
                      }),
                      SizedBox(height: 15),
                      _buildToggleOption(context, 'Efectos de sonido', _soundEffectsEnabled, (value) {
                        setState(() => _soundEffectsEnabled = value);
                      }),
                      SizedBox(height: 15),
                      _buildToggleOption(context, 'Notificaciones', _notificationsEnabled, (value) {
                        setState(() => _notificationsEnabled = value);
                      }),
                      SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_soundEffectsEnabled) {
                              final effectPlayer = AudioPlayer(); // AudioPlayer local para efectos
                              await effectPlayer.play(AssetSource('audio/save.mp3'), volume: 0.8); // Sin bucle
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ajustes guardados')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7CFC00),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Guardar',
                            style: GoogleFonts.pressStart2p(
                              textStyle: TextStyle(
                                color: Color(0xFF000000),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Personajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Niveles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
        currentIndex: 3, // Configuración seleccionado
        selectedItemColor: Color(0xFF7CFC00),
        unselectedItemColor: Color(0xFFB0BEC5),
        backgroundColor: Color(0xFF1C1C1C),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/character-customization');
              break;
            case 1:
              context.go('/rankings');
              break;
            case 2:
              context.go('/levels');
              break;
            case 3:
              break;
          }
        },
      ),
    );
  }

  Widget _buildToggleOption(BuildContext context, String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.pressStart2p(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        Switch(
          value: value,
          activeColor: Color(0xFF7CFC00),
          inactiveThumbColor: Color(0xFFB0BEC5),
          inactiveTrackColor: Color(0xFF1C1C1C),
          onChanged: (newValue) async {
            if (_soundEffectsEnabled) {
              final effectPlayer = AudioPlayer(); // AudioPlayer local para efectos
              await effectPlayer.play(AssetSource('audio/toggle.mp3'), volume: 0.8); // Sin bucle
            }
            onChanged(newValue);
          },
        ),
      ],
    );
  }
}