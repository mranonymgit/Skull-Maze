import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async' as async;
import '../providers/app_providers.dart';
import '../controllers/game_controller.dart';
import '../controllers/settings_controller.dart';

// IMPORTACION DE TODAS LAS CLASES
import 'package:skull_maze/class/wall.dart';
import 'package:skull_maze/class/NeonWall.dart';
import 'package:skull_maze/class/goal.dart';
import 'package:skull_maze/class/player.dart';
import 'package:skull_maze/class/directional_buttons.dart';
import 'package:skull_maze/class/main_game.dart';


// ================= Pantalla del juego =================
class GameScreen extends ConsumerStatefulWidget {
  final String level;

  const GameScreen({super.key, required this.level});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late SkullMazeGame game;

  @override
  void initState() {
    super.initState();

    game = SkullMazeGame()..level = int.parse(widget.level);

    // Configurar callback para cuando se alcance la meta
    game.onGoalReachedCallback = _onGoalReached;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLevelMusic();

      // Aplicar configuraciones del usuario al juego
      final settings = ref.read(settingsControllerProvider);
      game.useGyroscope = settings.gyroscopeEnabled;
    });
  }

  @override
  void dispose() {
    _stopLevelMusic(); // Esto ya detiene level y resume background
    game.onRemove();
    super.dispose();
  }

  Future<void> _startLevelMusic() async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.playLevelMusic();
  }

  Future<void> _stopLevelMusic() async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.stopLevelMusic();
  }

  Future<void> _onGoalReached() async {
    // Completar nivel con el controller
    await ref.read(gameControllerProvider.notifier).completeLevel();

    if (mounted) {
      _showLevelCompleteDialog();
    }
  }

  void _showLevelCompleteDialog() {
    final audioService = ref.read(audioServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: Text(
          '¡Nivel Completado!',
          style: GoogleFonts.pressStart2p(
            color: const Color(0xFF7CFC00),
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              color: Color(0xFFFFE87C),
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'Nivel ${widget.level} completado',
              style: GoogleFonts.openSans(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await audioService.playClickSound();
              await _stopLevelMusic();

              if (mounted && context.mounted) {
                Navigator.pop(context);
                context.go('/levels');
              }
            },
            child: Text(
              'Menú',
              style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await audioService.playSelectSound();

              // Siguiente nivel
              await ref.read(gameControllerProvider.notifier).nextLevel();

              if (mounted && context.mounted) {
                Navigator.pop(context);
                final nextLevel = int.parse(widget.level) + 1;
                context.go('/game/$nextLevel');
              }
            },
            child: Text(
              'Siguiente',
              style: GoogleFonts.openSans(color: const Color(0xFF7CFC00)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPauseMenu() {
    final audioService = ref.read(audioServiceProvider);
    final settings = ref.read(settingsControllerProvider);

    audioService.playClickSound();
    audioService.pauseLevelMusic();
    game.isPaused = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          title: Text(
            'Pausa',
            style: GoogleFonts.pressStart2p(color: const Color(0xFF7CFC00)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () async {
                    await audioService.playClickSound();
                    game.isPaused = false;
                    await audioService.resumeLevelMusic();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Reanudar',
                    style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5)),
                  ),
                ),
                const SizedBox(height: 10),

                // Control de volumen
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Volumen: ',
                      style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5)),
                    ),
                    Expanded(
                      child: Slider(
                        value: settings.volumeLevel,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(settings.volumeLevel * 100).round()}%',
                        onChanged: (value) async {
                          ref.read(settingsControllerProvider.notifier).setVolume(value);
                          setDialogState(() {});
                        },
                        activeColor: const Color(0xFF7CFC00),
                        inactiveColor: const Color(0xFFB0BEC5),
                      ),
                    ),
                  ],
                ),

                // Switch de vibración
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vibración: ',
                      style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5)),
                    ),
                    Switch(
                      value: settings.vibrationEnabled,
                      onChanged: (value) async {
                        ref.read(settingsControllerProvider.notifier).toggleVibration(value);
                        setDialogState(() {});
                        if (value) {
                          HapticFeedback.mediumImpact();
                        }
                      },
                      activeColor: const Color(0xFF7CFC00),
                      inactiveThumbColor: const Color(0xFFB0BEC5),
                    ),
                  ],
                ),

                // Switch de giroscopio
                if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS))
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Giroscopio: ',
                        style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5)),
                      ),
                      Switch(
                        value: settings.gyroscopeEnabled,
                        onChanged: (value) async {
                          ref.read(settingsControllerProvider.notifier).toggleGyroscope(value);
                          game.toggleGyroscope(value);
                          setDialogState(() {});
                          if (value) {
                            HapticFeedback.mediumImpact();
                          }
                        },
                        activeColor: const Color(0xFF7CFC00),
                        inactiveThumbColor: const Color(0xFFB0BEC5),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),

                TextButton(
                  onPressed: () async {
                    await audioService.playClickSound();
                    await _stopLevelMusic(); // Detiene level music y resume background

                    if (mounted && context.mounted) {
                      Navigator.pop(context);
                      context.go('/levels');
                    }
                  },
                  child: Text(
                    'Salir al Menú',
                    style: GoogleFonts.openSans(color: const Color(0xFFFF4500)),
                  ),
                ),

                TextButton(
                  onPressed: () async {
                    await audioService.playClickSound();
                    await ref.read(gameControllerProvider.notifier).restartLevel();

                    if (mounted && context.mounted) {
                      Navigator.pop(context);
                      game.isPaused = false;
                      game.generateMaze();
                      await audioService.resumeLevelMusic();
                    }
                  },
                  child: Text(
                    'Reiniciar Nivel',
                    style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          final orientation = MediaQuery.of(context).orientation;
          final isLandscape = orientation == Orientation.landscape;

          final isMobile = kIsWeb
              ? screenSize.width < 600
              : (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

          final minDimension = min(screenSize.width, screenSize.height);
          final pauseButtonSize = isMobile ? minDimension * 0.08 : 30.0;
          final pauseButtonPadding = isMobile ? minDimension * 0.02 : 10.0;
          final controlsBottomPadding = isMobile ? minDimension * 0.02 : 20.0;
          final controlsHorizontalPadding = isMobile ? minDimension * 0.02 : 20.0;

          return Container(
            width: screenSize.width,
            height: screenSize.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A1B3D), Color(0xFF1C1C1C), Color(0xFF000000)],
              ),
            ),
            child: SafeArea(
              child: RawKeyboardListener(
                focusNode: FocusNode()..requestFocus(),
                autofocus: true,
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent) {
                    game.pressedKeys.add(event.logicalKey);
                  } else if (event is RawKeyUpEvent) {
                    game.pressedKeys.remove(event.logicalKey);
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GameWidget(
                      game: game,
                      focusNode: FocusNode(),
                    ),

                    // Controles táctiles
                    if (isMobile && !settings.gyroscopeEnabled)
                      Positioned(
                        left: isLandscape ? controlsHorizontalPadding : null,
                        right: isLandscape ? null : controlsHorizontalPadding,
                        bottom: controlsBottomPadding,
                        child: DirectionalButtons(
                          onDirectionChange: (Vector2 direction) {
                            if (game.player != null && !game.isPaused) {
                              game.inputDirection = direction;
                            }
                          },
                          isLandscape: isLandscape,
                        ),
                      ),

                    // Botón de pausa
                    Positioned(
                      top: pauseButtonPadding,
                      right: pauseButtonPadding,
                      child: IconButton(
                        icon: Icon(
                          Icons.pause,
                          color: const Color(0xFFB0BEC5),
                          size: pauseButtonSize,
                        ),
                        onPressed: () {
                          if (settings.vibrationEnabled) {
                            HapticFeedback.lightImpact();
                          }
                          _showPauseMenu();
                        },
                        padding: EdgeInsets.all(pauseButtonPadding / 2),
                        constraints: BoxConstraints(
                          minWidth: pauseButtonSize * 1.5,
                          minHeight: pauseButtonSize * 1.5,
                        ),
                      ),
                    ),

                    // Indicador de giroscopio
                    if (isMobile && settings.gyroscopeEnabled)
                      Positioned(
                        bottom: controlsBottomPadding * 2,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7CFC00).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF7CFC00),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.screen_rotation,
                                  color: Color(0xFF7CFC00),
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Modo Giroscopio',
                                  style: GoogleFonts.openSans(
                                    color: const Color(0xFF7CFC00),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}