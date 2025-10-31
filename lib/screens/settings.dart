import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/ranking_controller.dart';
import '../services/audio_service.dart'; // ⭐ AGREGAR

class Settings extends ConsumerWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioServiceProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A1B3D),
                  Color(0xFF1C1C1C),
                  Color(0xFF000000),
                ],
              ),
            ),
            child: Column(
              children: [
                // Encabezado con logo
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    height: size.height * 0.15,
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/skull_logo.png', height: 40),
                          const SizedBox(width: 10),
                          Text(
                            'Configuración',
                            style: GoogleFonts.pressStart2p(
                              textStyle: TextStyle(
                                color: const Color(0xFF7CFC00),
                                fontSize: size.width > 800 ? 24.0 : size.width * 0.06,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF0B2E62).withOpacity(0.3),
                                    offset: const Offset(0.5, 0.5),
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
                      const SizedBox(height: 20),
                      Text(
                        'Ajustes de Audio',
                        style: GoogleFonts.pressStart2p(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Toggle de Música
                      _buildToggleOption(
                        context,
                        ref,
                        'Música',
                        settingsState.musicEnabled,
                            (value) async {
                          await ref.read(settingsControllerProvider.notifier).toggleMusic(value);
                        },
                      ),
                      const SizedBox(height: 15),

                      // Toggle de Efectos de Sonido
                      _buildToggleOption(
                        context,
                        ref,
                        'Efectos de sonido',
                        settingsState.soundEffectsEnabled,
                            (value) async {
                          await ref.read(settingsControllerProvider.notifier).toggleSoundEffects(value);
                        },
                      ),
                      const SizedBox(height: 15),

                      // Control de Volumen
                      _buildVolumeSlider(
                        context,
                        ref,
                        settingsState.volumeLevel,
                      ),
                      const SizedBox(height: 30),

                      // Ajustes de Juego
                      Text(
                        'Ajustes de Juego',
                        style: GoogleFonts.pressStart2p(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Toggle de Vibración
                      _buildToggleOption(
                        context,
                        ref,
                        'Vibración',
                        settingsState.vibrationEnabled,
                            (value) async {
                          await ref.read(settingsControllerProvider.notifier).toggleVibration(value);
                        },
                      ),
                      const SizedBox(height: 15),

                      // Toggle de Notificaciones
                      _buildToggleOption(
                        context,
                        ref,
                        'Notificaciones',
                        settingsState.notificationsEnabled,
                            (value) async {
                          await ref.read(settingsControllerProvider.notifier).toggleNotifications(value);
                        },
                      ),
                      const SizedBox(height: 15),

                      // Toggle de Giroscopio
                      _buildToggleOption(
                        context,
                        ref,
                        'Giroscopio',
                        settingsState.gyroscopeEnabled,
                            (value) async {
                          await ref.read(settingsControllerProvider.notifier).toggleGyroscope(value);
                        },
                      ),
                      const SizedBox(height: 30),

                      // Botones de acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Botón Guardar
                          ElevatedButton(
                            onPressed: () async {
                              await ref.read(settingsControllerProvider.notifier).saveSettings();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ajustes guardados'),
                                    backgroundColor: Color(0xFF7CFC00),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7CFC00),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Guardar',
                              style: GoogleFonts.pressStart2p(
                                textStyle: const TextStyle(
                                  color: Color(0xFF000000),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          // Botón Restaurar
                          OutlinedButton(
                            onPressed: () async {
                              await ref.read(settingsControllerProvider.notifier).resetToDefault();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ajustes restaurados'),
                                    backgroundColor: Color(0xFF7CFC00),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFF007F)),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Restaurar',
                              style: GoogleFonts.pressStart2p(
                                textStyle: const TextStyle(
                                  color: Color(0xFFFF007F),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Botón de Cerrar Sesión
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await audioService.playClickSound();

                            // Mostrar confirmación
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1C1C1C),
                                title: Text(
                                  '¿Cerrar sesión?',
                                  style: GoogleFonts.pressStart2p(
                                    textStyle: const TextStyle(
                                      color: Color(0xFF7CFC00),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                content: Text(
                                  '¿Estás seguro de que quieres cerrar sesión?',
                                  style: GoogleFonts.openSans(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      'Cancelar',
                                      style: GoogleFonts.openSans(
                                        textStyle: const TextStyle(
                                          color: Color(0xFFB0BEC5),
                                        ),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text(
                                      'Cerrar sesión',
                                      style: GoogleFonts.openSans(
                                        textStyle: const TextStyle(
                                          color: Color(0xFFFF4500),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true && context.mounted) {
                              await ref.read(authControllerProvider.notifier).signOut();
                              context.go('/login');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4500),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cerrar Sesión',
                            style: GoogleFonts.pressStart2p(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
        selectedItemColor: const Color(0xFF7CFC00),
        unselectedItemColor: const Color(0xFFB0BEC5),
        backgroundColor: const Color(0xFF1C1C1C),
        type: BottomNavigationBarType.fixed,
        onTap: (index) async {
          await audioService.playClickSound();
          switch (index) {
            case 0:
              context.go('/character-customization');
              break;
            case 1:
              await ref.read(rankingControllerProvider.notifier).loadTopScores();
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

  Widget _buildToggleOption(
      BuildContext context,
      WidgetRef ref,
      String title,
      bool value,
      Function(bool) onChanged,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.pressStart2p(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Switch(
          value: value,
          activeColor: const Color(0xFF7CFC00),
          inactiveThumbColor: const Color(0xFFB0BEC5),
          inactiveTrackColor: const Color(0xFF1C1C1C),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildVolumeSlider(
      BuildContext context,
      WidgetRef ref,
      double value,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volumen: ${(value * 100).toInt()}%',
          style: GoogleFonts.pressStart2p(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF7CFC00),
            inactiveTrackColor: const Color(0xFFB0BEC5),
            thumbColor: const Color(0xFF7CFC00),
            overlayColor: const Color(0xFF7CFC00).withOpacity(0.3),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (newValue) async {
              await ref.read(settingsControllerProvider.notifier).setVolume(newValue);
            },
          ),
        ),
      ],
    );
  }
}