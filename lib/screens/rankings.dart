import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../controllers/ranking_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/audio_service.dart'; // ⭐ AGREGAR

class Rankings extends ConsumerStatefulWidget {
  const Rankings({super.key});

  @override
  ConsumerState<Rankings> createState() => _RankingsState();
}

class _RankingsState extends ConsumerState<Rankings> {
  @override
  void initState() {
    super.initState();
    // Cargar ranking al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rankingControllerProvider.notifier).loadTopScores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioServiceProvider);
    final rankingState = ref.watch(rankingControllerProvider);
    final size = MediaQuery.of(context).size;
    final currentUser = ref.watch(currentUserProvider);

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
                            'Ranking',
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
                    children: [
                      const SizedBox(height: 20),

                      // Botón de recargar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Clasificación Global',
                            style: GoogleFonts.pressStart2p(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Color(0xFF7CFC00)),
                            onPressed: rankingState.isLoading
                                ? null
                                : () async {
                              await audioService.playClickSound();
                              await ref.read(rankingControllerProvider.notifier).refreshRanking();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Loading, Error o Lista
                      if (rankingState.isLoading)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7CFC00),
                          ),
                        )
                      else if (rankingState.hasError)
                        Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFFF4500),
                                size: 48,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Error al cargar ranking',
                                style: GoogleFonts.openSans(
                                  textStyle: const TextStyle(
                                    color: Color(0xFFFF4500),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  await audioService.playClickSound();
                                  await ref.read(rankingControllerProvider.notifier).refreshRanking();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7CFC00),
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      else if (!rankingState.hasScores)
                          Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.leaderboard_outlined,
                                  color: Color(0xFFB0BEC5),
                                  size: 48,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No hay puntuaciones aún',
                                  style: GoogleFonts.openSans(
                                    textStyle: const TextStyle(
                                      color: Color(0xFFB0BEC5),
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '¡Sé el primero en jugar!',
                                  style: GoogleFonts.openSans(
                                    textStyle: const TextStyle(
                                      color: Color(0xFF7CFC00),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rankingState.scores.length > 20
                                ? 20
                                : rankingState.scores.length,
                            itemBuilder: (context, index) {
                              final score = rankingState.scores[index];
                              final isCurrentUser = currentUser?.id == score.userId;
                              final isTop3 = index < 3;

                              return GestureDetector(
                                onTap: () async {
                                  await ref.read(rankingControllerProvider.notifier).onPlayerSelected();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${score.userName} - Nivel ${score.level}'),
                                        backgroundColor: const Color(0xFF7CFC00),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser
                                        ? const Color(0xFFFFE87C).withOpacity(0.2)
                                        : const Color(0xFF7CFC00).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isTop3
                                          ? const Color(0xFFFFE87C)
                                          : const Color(0xFFFF007F),
                                      width: isTop3 ? 3 : 2,
                                    ),
                                    boxShadow: isTop3
                                        ? [
                                      BoxShadow(
                                        color: const Color(0xFFFFE87C).withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // Posición
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isTop3
                                              ? const Color(0xFFFFE87C)
                                              : const Color(0xFF7CFC00),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '#${score.rank}',
                                            style: GoogleFonts.pressStart2p(
                                              textStyle: const TextStyle(
                                                color: Color(0xFF000000),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),

                                      // Nombre del jugador
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              score.userName,
                                              style: GoogleFonts.pressStart2p(
                                                textStyle: TextStyle(
                                                  color: isCurrentUser
                                                      ? const Color(0xFFFFE87C)
                                                      : Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Nivel ${score.level}',
                                              style: GoogleFonts.openSans(
                                                textStyle: const TextStyle(
                                                  color: Color(0xFFB0BEC5),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Puntuación
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${score.score} pts',
                                            style: GoogleFonts.pressStart2p(
                                              textStyle: const TextStyle(
                                                color: Color(0xFFFF007F),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${score.time}s',
                                            style: GoogleFonts.openSans(
                                              textStyle: const TextStyle(
                                                color: Color(0xFFB0BEC5),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
        currentIndex: 1, // Ranking seleccionado
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
  }
}