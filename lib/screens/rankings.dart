import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart'; // Importa el audioPlayerProvider

class Rankings extends ConsumerWidget {
  const Rankings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                            'Ranking',
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
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Clasificación',
                        style: GoogleFonts.pressStart2p(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () async {
                              final effectPlayer = AudioPlayer(); // AudioPlayer local para efectos
                              await effectPlayer.play(AssetSource('audio/player.mp3'), volume: 0.8); // Sin bucle
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Jugador ${index + 1} seleccionado')),
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Color(0xFF7CFC00).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Color(0xFFFF007F), width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${index + 1}',
                                    style: GoogleFonts.pressStart2p(
                                      textStyle: TextStyle(
                                        color: Color(0xFF7CFC00),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Jugador ${index + 1}',
                                    style: GoogleFonts.pressStart2p(
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${1000 - index * 100} puntos',
                                    style: GoogleFonts.pressStart2p(
                                      textStyle: TextStyle(
                                        color: Color(0xFFFF007F),
                                        fontSize: 14,
                                      ),
                                    ),
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