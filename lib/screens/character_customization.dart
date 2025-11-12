import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../controllers/settings_controller.dart';
import '../controllers/ranking_controller.dart';

// ====== 1. Modelo simple de Personaje ======
// (Úsalo para que sea fácil agregar/cambiar nombres e imágenes)
class Character {
  final int id;
  final String name;
  final String imagePath;

  const Character({
    required this.id,
    required this.name,
    required this.imagePath,
  });
}

const List<Character> characters = [
  Character(id: 1, name: 'Snoopy', imagePath: 'assets/images/Snoopy.png'),
  Character(id: 2, name: 'Catty', imagePath: 'assets/images/Catty.png'),
  Character(id: 3, name: 'Doggy', imagePath: 'assets/images/Doggy.png'),
  Character(id: 4, name: 'Robo', imagePath: 'assets/images/Robo.png'),
  Character(id: 5, name: 'Setty', imagePath: 'assets/images/Setty.png'),
  Character(id: 6, name: 'Special Hallowen', imagePath: 'assets/images/Special Halloween.png'),
];

class CharacterCustomization extends ConsumerWidget {
  const CharacterCustomization({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCharacter = ref.watch(selectedCharacterProvider);
    final audioService = ref.watch(audioServiceProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final padding = width * 0.04;
        final logoHeight = (height * 0.08).clamp(50.0, 120.0);
        final characterSize = (width * 0.18).clamp(80.0, 150.0);
        final fontSizeTitle = (width * 0.05).clamp(18.0, 28.0);
        final fontSizeSubtitle = (width * 0.035).clamp(14.0, 20.0);
        final fontSizeName = (width * 0.025).clamp(12.0, 16.0);

        return Scaffold(
          extendBody: true,
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Container(
                width: width,
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
                    // === LOGO Y TÍTULO (sin cambios) ===
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/skull_logo.png',
                              height: logoHeight,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: width * 0.02),
                            Text(
                              'Personajes',
                              style: GoogleFonts.pressStart2p(
                                textStyle: TextStyle(
                                  color: const Color(0xFF7CFC00),
                                  fontSize: fontSizeTitle,
                                  letterSpacing: 1.5,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xFF0B2E62),
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
                    SizedBox(height: height * 0.02),
                    Text(
                      'Selecciona tu personaje',
                      style: GoogleFonts.pressStart2p(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: fontSizeSubtitle,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.02),

                    // === GRID DE LOS 6 PERSONAJES (o más si agregas) ===
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Wrap(
                        spacing: width * 0.04,
                        runSpacing: width * 0.04,
                        alignment: WrapAlignment.center,
                        children: characters.map((char) => _buildCharacterOption(
                          context,
                          ref,
                          char,
                          characterSize,
                          selectedCharacter,
                          audioService,
                          fontSizeName,
                        )).toList(),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                  ],
                ),
              ),
            ),
          ),

          // === BARRA INFERIOR (sin cambios) ===
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Personajes'),
              BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Ranking'),
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Niveles'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
            ],
            currentIndex: 0,
            selectedItemColor: const Color(0xFF7CFC00),
            unselectedItemColor: const Color(0xFFB0BEC5),
            backgroundColor: const Color(0xFF1C1C1C),
            type: BottomNavigationBarType.fixed,
            iconSize: 26,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (index) async {
              await audioService.playClickSound();
              switch (index) {
                case 0:
                  break;
                case 1:
                  await ref.read(rankingControllerProvider.notifier).loadTopScores();
                  context.go('/rankings');
                  break;
                case 2:
                  context.go('/levels');
                  break;
                case 3:
                  context.go('/settings');
                  break;
              }
            },
          ),
        );
      },
    );
  }

  // ====== Opción de personaje: Imagen + Nombre debajo ======
  Widget _buildCharacterOption(
      BuildContext context,
      WidgetRef ref,
      Character char,
      double size,
      int selectedId,
      dynamic audioService,
      double fontSizeName,
      ) {
    final isSelected = selectedId == char.id;

    return GestureDetector(
      onTap: () async {
        await audioService.playSelectSound();
        await ref.read(settingsControllerProvider.notifier).selectCharacter(char.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${char.name} ha sido seleccionado.'),
              backgroundColor: const Color(0xFF7CFC00),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Círculo con imagen y efectos
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7CFC00).withOpacity(0.2),
              border: Border.all(
                color: isSelected ? const Color(0xFFFFE87C) : const Color(0xFFFF007F),
                width: isSelected ? 4 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? const Color(0xFFFFE87C) : const Color(0xFFFF007F))
                      .withOpacity(0.5),
                  spreadRadius: isSelected ? 4 : 2,
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Image.asset(
                    char.imagePath,
                    width: size * 0.6,
                    height: size * 0.6,
                    fit: BoxFit.contain,
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7CFC00),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF000000),
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: size * 0.05),
          // Nombre debajo (se resalta si está seleccionado)
          Text(
            char.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.pressStart2p(
              textStyle: TextStyle(
                color: isSelected ? const Color(0xFF7CFC00) : Colors.white,
                fontSize: fontSizeName,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}