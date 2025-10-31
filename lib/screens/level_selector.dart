import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../controllers/game_controller.dart';
import '../controllers/ranking_controller.dart';
import '../services/audio_service.dart'; // ⭐ AGREGAR

class LevelSelector extends ConsumerWidget {
  const LevelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final maxLevelUnlocked = ref.watch(maxLevelUnlockedProvider);
    final audioService = ref.watch(audioServiceProvider);

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
                // Header con título
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    height: size.height * 0.15,
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'Selector de Niveles',
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
                    ),
                  ),
                ),

                // Camino de niveles estilo Candy Crush
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 50, // 50 niveles totales
                    itemBuilder: (context, index) {
                      final level = index + 1;
                      final isUnlocked = level <= maxLevelUnlocked;

                      return Column(
                        children: [
                          if (index > 0) // Línea conectora
                            Container(
                              height: 40,
                              width: 4,
                              color: const Color(0xFFFF007F),
                            ),
                          GestureDetector(
                            onTap: isUnlocked
                                ? () async {
                              await audioService.playSelectSound();

                              // Iniciar nuevo juego con el controller
                              await ref.read(gameControllerProvider.notifier).startNewGame(level);

                              if (context.mounted) {
                                context.go('/game/$level');
                              }
                            }
                                : () async {
                              await audioService.playClickSound();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nivel bloqueado. Completa los niveles anteriores.'),
                                  backgroundColor: Color(0xFFFF4500),
                                ),
                              );
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnlocked
                                    ? const Color(0xFF7CFC00)
                                    : Colors.grey.withOpacity(0.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF007F).withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isUnlocked
                                    ? Text(
                                  '$level',
                                  style: GoogleFonts.pressStart2p(
                                    textStyle: const TextStyle(
                                      color: Color(0xFF000000),
                                      fontSize: 24,
                                    ),
                                  ),
                                )
                                    : const Icon(
                                  Icons.lock,
                                  color: Color(0xFF000000),
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
        currentIndex: 2, // "Niveles" como pantalla actual
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
            // Cargar ranking antes de navegar
              await ref.read(rankingControllerProvider.notifier).loadTopScores();
              context.go('/rankings');
              break;
            case 2:
            // Ya en niveles
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }
}