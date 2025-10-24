import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart'; // Import main.dart for audioPlayerProvider

// ================= Pared =================
class Wall extends PositionComponent with CollisionCallbacks {
  Wall({required super.position, required super.size, super.anchor = Anchor
      .topLeft});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()
      ..color = const Color(0xFF7E57C2));
  }
}

// ================= Meta =================
class Goal extends PositionComponent with CollisionCallbacks {
  Goal({required super.position, super.anchor = Anchor.center});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = Vector2.all(40); // Tamaño más pequeño para la meta
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, size.x / 2, Paint()
      ..color = const Color(0xFF3D5AFE));
  }
}

// ================= Jugador =================
class Player extends PositionComponent
    with HasGameRef<SkullMazeGame>, CollisionCallbacks {
  Player({required super.position, super.anchor = Anchor.center});

  Vector2 _previousPosition = Vector2.zero();
  final double playerSpeed = 250;
  bool _goalReached = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = Vector2.all(20);
    add(CircleHitbox()
      ..radius = size.x / 2);
    _previousPosition = position.clone();
  }

  void tryMove(Vector2 delta, double dt) {
    _previousPosition = position.clone();
    position.add(delta * dt * playerSpeed);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints,
      PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Goal) {
      if (!_goalReached) {
        print('¡Meta alcanzada en el nivel ${gameRef.level}!');
        _goalReached = true;
        gameRef.nextLevel();
      }
    }
    if (other is Wall) {
      position = _previousPosition;
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Goal) {
      _goalReached = false;
    }
    super.onCollisionEnd(other);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, size.x / 2, Paint()
      ..color = const Color(0xFF18FFFF));
  }
}

// ================= Componente principal del juego =================
class SkullMazeGame extends FlameGame with HasCollisionDetection {
  Player? player;
  Goal goal = Goal(position: Vector2.zero());
  int level = 1;
  final List<Wall> walls = [];
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  static const double gyroSensitivity = 100.0;
  Vector2 _gyroDelta = Vector2.zero();
  late int effectiveGridSize;
  late double cellSize;
  bool isPaused = false;
  bool isVolumeOn = true;
  bool isVibrationOn = true;
  double volumeLevel = 1.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    effectiveGridSize = (canvasSize.x / 40).floor().clamp(10, 30).toInt();
    cellSize = canvasSize.x / effectiveGridSize;

    player = Player(position: Vector2(cellSize / 2, cellSize / 2));
    add(player!);
    add(goal);

    generateMaze();
    camera.follow(player!);

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      gyroscopeEvents.listen((event) {
        _gyroDelta =
            Vector2(event.y * gyroSensitivity, -event.x * gyroSensitivity);
      });
    }
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    effectiveGridSize = (newSize.x / 40).floor().clamp(10, 30).toInt();
    cellSize = newSize.x / effectiveGridSize;
    generateMaze();
    if (player != null) {
      player!.position = Vector2(cellSize / 2, cellSize / 2);
    }
    camera.viewport.size = newSize;
  }

  void generateMaze() {
    print('Generando laberinto para nivel $level...');
    for (var wall in walls) {
      wall.removeFromParent();
    }
    walls.clear();

    List<List<int>> mazeGrid = List.generate(
        effectiveGridSize, (_) => List.filled(effectiveGridSize, 1));
    Random rnd = Random();
    List<Vector2> stack = [Vector2(0, 0)];
    mazeGrid[0][0] = 0;

    while (stack.isNotEmpty) {
      var current = stack.last;
      int x = current.x.toInt();
      int y = current.y.toInt();

      List<List<int>> directions = [[2, 0], [-2, 0], [0, 2], [0, -2]];
      directions.shuffle(rnd);

      bool moved = false;
      for (var dir in directions) {
        int nx = x + dir[0];
        int ny = y + dir[1];
        if (nx >= 0 && nx < effectiveGridSize && ny >= 0 &&
            ny < effectiveGridSize && mazeGrid[ny][nx] == 1) {
          mazeGrid[ny][nx] = 0;
          mazeGrid[y + dir[1] ~/ 2][x + dir[0] ~/ 2] = 0;
          stack.add(Vector2(nx.toDouble(), ny.toDouble()));
          moved = true;
          break;
        }
      }
      if (!moved) {
        stack.removeLast();
      }
    }

    for (int y = 0; y < effectiveGridSize; y++) {
      for (int x = 0; x < effectiveGridSize; x++) {
        if (mazeGrid[y][x] == 1) {
          var wall = Wall(
            position: Vector2(x * cellSize, y * cellSize),
            size: Vector2.all(cellSize),
          );
          walls.add(wall);
          add(wall);
        }
      }
    }

    if (player != null) {
      player!.position = Vector2(cellSize / 2, cellSize / 2);
    }
    goal.position = Vector2((effectiveGridSize - 1) * cellSize + cellSize / 2,
        (effectiveGridSize - 1) * cellSize + cellSize / 2);
  }

  void nextLevel() {
    level++;
    generateMaze();
  }

  @override
  void update(double dt) {
    if (isPaused) return;
    super.update(dt);

    Vector2 moveDirection = Vector2.zero();

    // Keyboard controls for Web/Desktop
    if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyW)) {
        moveDirection.y = -1;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyS)) {
        moveDirection.y = 1;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
        moveDirection.x = -1;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
          _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
        moveDirection.x = 1;
      }
    }

    // Gyroscope controls for Mobile
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) &&
        _gyroDelta.length > 0.5) {
      moveDirection = _gyroDelta;
    }

    // Apply movement
    if (player != null && moveDirection != Vector2.zero()) {
      player!.tryMove(moveDirection.normalized(), dt);
    }

    if (joystickDirection != Vector2.zero()) {
      player?.tryMove(joystickDirection, dt);
    }
  }

  Vector2 joystickDirection = Vector2.zero();

  @override
  KeyEventResult onKeyEvent(KeyEvent event,
      Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);
    return KeyEventResult.handled;
  }
}

// ================= Joystick Widget =================
class Joystick extends StatefulWidget {
  final Function(Vector2) onMove;

  const Joystick({super.key, required this.onMove});

  @override
  JoystickState createState() => JoystickState();
}

class JoystickState extends State<Joystick> {
  Offset _position = Offset.zero;
  final double _joystickRadius = 60;
  final double _knobRadius = 20;

  void _handlePan(Offset localPosition) {
    final center = Offset(_joystickRadius, _joystickRadius);
    Offset newPosition = localPosition - center;

    double distance = newPosition.distance;
    if (distance > _joystickRadius - _knobRadius) {
      newPosition = Offset.fromDirection(
          newPosition.direction, _joystickRadius - _knobRadius);
    }

    setState(() {
      _position = newPosition;
    });

    if (distance > 10) { // Dead zone
      widget.onMove(
          Vector2(newPosition.dx, newPosition.dy).normalized() * 0.25);
    } else {
      widget.onMove(Vector2.zero());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _handlePan(details.localPosition),
      onPanUpdate: (details) => _handlePan(details.localPosition),
      onPanEnd: (_) {
        setState(() => _position = Offset.zero);
        widget.onMove(Vector2.zero());
      },
      child: Container(
        width: _joystickRadius * 2,
        height: _joystickRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.3),
        ),
        child: Center(
          child: Transform.translate(
            offset: _position,
            child: Container(
              width: _knobRadius * 2,
              height: _knobRadius * 2,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFB0BEC5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ================= Pantalla del juego =================

// Provider para mantener una única instancia del juego
final gameProvider = StateProvider<SkullMazeGame?>((ref) => null);

class GameScreen extends ConsumerStatefulWidget {
  final String level;

  const GameScreen({super.key, required this.level});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  static AudioPlayer? _levelMusicPlayer;

  // Variables para la animación de fundido
  double _overlayOpacity = 0.0;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    // Creamos la instancia del juego aquí
    final newGame = SkullMazeGame()
      ..level = int.parse(widget.level);
    Future.microtask(() =>
    ref
        .read(gameProvider.notifier)
        .state = newGame);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLevelMusic(newGame);
    });
  }

  Future<void> _playClickSound() async {
    final game = ref.read(gameProvider);
    if (game != null && game.isVolumeOn) {
      final clickPlayer = AudioPlayer();
      await clickPlayer.play(
          AssetSource('audio/pause.mp3'), volume: game.volumeLevel);
      // No disponer inmediatamente para que se escuche
    }
  }

  Future<void> _playOptionClickSound() async {
    final game = ref.read(gameProvider);
    if (game != null && game.isVolumeOn) {
      final clickPlayer = AudioPlayer();
      await clickPlayer.play(
          AssetSource('audio/b_menu.mp3'), volume: game.volumeLevel);
    }
  }

  Future<void> _startLevelMusic(SkullMazeGame game) async {
    final globalPlayer = ref.read(audioPlayerProvider);
    await globalPlayer.pause();

    if (game.isVolumeOn) {
      await _levelMusicPlayer?.stop();
      await _levelMusicPlayer?.dispose();

      _levelMusicPlayer = AudioPlayer();
      await _levelMusicPlayer!.setSource(AssetSource('audio/level.mp3'));
      await _levelMusicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _levelMusicPlayer!.setVolume(game.volumeLevel);
      await _levelMusicPlayer!.resume();
    }
  }

  @override
  void dispose() {
    _levelMusicPlayer?.stop();
    _levelMusicPlayer?.dispose();
    _levelMusicPlayer = null;

    // Reanuda la música global solo si no estamos en medio de una salida controlada
    if (!_isExiting) {
      final globalPlayer = ref.read(audioPlayerProvider);
      globalPlayer.resume();
    }

    // Limpia el provider del juego al salir de la pantalla
    Future.microtask(() =>
    ref
        .read(gameProvider.notifier)
        .state = null);
    super.dispose();
  }

  void _showPauseMenu() {
    final game = ref.read(gameProvider);
    if (game == null) return;

    _playClickSound();
    _levelMusicPlayer?.pause();
    game.isPaused = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // StatefulBuilder permite actualizar la UI del diálogo
        return StatefulBuilder(
          builder: (context, setStateDialog) { // Renombrado para claridad
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1C),
              title: Text('Pausa', style: GoogleFonts.pressStart2p(
                  color: const Color(0xFF7CFC00))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      _playOptionClickSound();
                      Navigator.pop(context); // Cierra el diálogo
                      // La lógica de reanudar está en el `then` de showDialog
                    },
                    child: Text('Reanudar',
                        style: GoogleFonts.openSans(color: const Color(
                            0xFFB0BEC5))),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Volumen:',
                          style: GoogleFonts.openSans(color: const Color(
                              0xFFB0BEC5))),
                      Expanded(
                        child: Slider(
                          value: game.volumeLevel,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: '${(game.volumeLevel * 100).round()}%',
                          onChanged: (value) async {
                            // Actualiza el estado visual del slider y el volumen del juego
                            setStateDialog(() {
                              game.volumeLevel = value;
                            });
                            // Aplica el volumen a la música en tiempo real
                            await _levelMusicPlayer?.setVolume(value);
                          },
                          activeColor: const Color(0xFF7CFC00),
                          inactiveColor: const Color(0xFFB0BEC5),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Vibración: ',
                          style: GoogleFonts.openSans(color: const Color(
                              0xFFB0BEC5))),
                      Switch(
                        value: game.isVibrationOn,
                        onChanged: (value) {
                          setStateDialog(() {
                            game.isVibrationOn = value;
                          });
                          print('Vibración ${game.isVibrationOn
                              ? "activada"
                              : "desactivada"}');
                        },
                        activeColor: const Color(0xFF7CFC00),
                        inactiveThumbColor: const Color(0xFFB0BEC5),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // 1. Marca que estamos saliendo para una gestión correcta del audio.
                      _isExiting = true;
                      _playOptionClickSound();

                      // 2. Cierra el menú de pausa.
                      Navigator.of(context).pop();

                      // 3. Activa la animación de fundido actualizando el estado del Widget padre.
                      setState(() {
                        _overlayOpacity = 1.0;
                      });

                      // 4. Espera a que la animación termine y luego navega.
                      Future.delayed(const Duration(milliseconds: 500), () {
                        game.isPaused = false;
                        final globalPlayer = ref.read(audioPlayerProvider);
                        globalPlayer.resume();
                        GoRouter.of(context).go('/main_menu');
                      });
                    },
                    child: Text('Salir al Menú',
                        style: GoogleFonts.openSans(color: const Color(
                            0xFFB0BEC5))),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Se ejecuta al cerrar el diálogo, solo reanuda si no estamos saliendo.
      if (!_isExiting) {
        game.isPaused = false;
        if (game.isVolumeOn) {
          _levelMusicPlayer?.resume();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);

    // Muestra un indicador de carga mientras el juego se inicializa
    if (game == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GameWidget(game: game),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.pause, color: Colors.white, size: 30),
              onPressed: _showPauseMenu,
            ),
          ),
          if (isMobile)
            Positioned(
              bottom: 40,
              left: 40,
              child: Joystick(
                onMove: (direction) {
                  game.joystickDirection = direction;
                },
              ),
            ),

          // WIDGET DE SUPERPOSICIÓN PARA FUNDIDO A NEGRO
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _overlayOpacity,
              duration: const Duration(milliseconds: 500),
              child: Container(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}