import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../controllers/settings_controller.dart';
import '../controllers/ranking_controller.dart';

class CharacterCustomization extends ConsumerWidget {
  const CharacterCustomization({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCharacter = ref.watch(selectedCharacterProvider);
    final audioService = ref.watch(audioServiceProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        // Padding y tamaños dinámicos
        final double padding = width * 0.04;
        final double logoHeight = (height * 0.08).clamp(50.0, 120.0);
        final double characterSize = (width * 0.18).clamp(80.0, 150.0);
        final double fontSizeTitle = (width * 0.05).clamp(18.0, 28.0);
        final double fontSizeSubtitle = (width * 0.035).clamp(14.0, 20.0);

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
                    // Header con logo
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

                    // Grid de personajes
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Wrap(
                        spacing: width * 0.04,
                        runSpacing: width * 0.04,
                        alignment: WrapAlignment.center,
                        children: List.generate(
                          4,
                              (index) => _buildCharacterOption(
                            context,
                            ref,
                            index + 1,
                            characterSize,
                            selectedCharacter,
                            audioService,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
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

  Widget _buildCharacterOption(
      BuildContext context,
      WidgetRef ref,
      int index,
      double characterSize,
      int selectedCharacter,
      dynamic audioService,
      ) {
    final isSelected = selectedCharacter == index;

    return GestureDetector(
      onTap: () async {
        await audioService.playSelectSound();

        // Actualizar personaje seleccionado con el controller
        await ref.read(settingsControllerProvider.notifier).selectCharacter(index);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Personaje $index seleccionado'),
              backgroundColor: const Color(0xFF7CFC00),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        width: characterSize,
        height: characterSize,
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
                'assets/images/skull_player.png',
                width: characterSize * 0.6,
                height: characterSize * 0.6,
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
    );
  }
}