import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // Para fuentes consistentes

// Provider para niveles desbloqueados (solo Nivel 1 por defecto)
final unlockedLevelsProvider = StateProvider<int>((ref) => 1);

class LevelSelector extends ConsumerWidget {
  const LevelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final unlockedLevels = ref.watch(unlockedLevelsProvider); // Niveles desbloqueados

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
                // Header con título
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Container(
                    height: size.height * 0.15,
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'Selector de Niveles',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(
                            color: Color(0xFF7CFC00), // Verde Eléctrico
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
                    ),
                  ),
                ),
                // Camino de niveles estilo Candy Crush
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: 5, // Ej. 10 niveles totales
                    itemBuilder: (context, index) {
                      final level = index + 1;
                      final isUnlocked = level <= unlockedLevels;
                      return Column(
                        children: [
                          if (index > 0) // Línea conectora
                            Container(
                              height: 40,
                              width: 4,
                              color: Color(0xFFFF007F), // Rosa para el "camino"
                            ),
                          GestureDetector(
                            onTap: isUnlocked
                                ? () => context.go('/game/$level')
                                : null,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnlocked ? Color(0xFF7CFC00) : Colors.grey.withOpacity(0.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFFF007F).withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isUnlocked
                                    ? Text(
                                  '$level',
                                  style: GoogleFonts.pressStart2p(
                                    textStyle: TextStyle(
                                      color: Color(0xFF000000),
                                      fontSize: 24,
                                    ),
                                  ),
                                )
                                    : Icon(
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
        selectedItemColor: Color(0xFF7CFC00), // Verde para seleccionado
        unselectedItemColor: Color(0xFFB0BEC5), // Gris claro
        backgroundColor: Color(0xFF1C1C1C), // Fondo oscuro
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
            // Ya en niveles, no navegar
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