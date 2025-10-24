import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart'; // Import main.dart for audioPlayerProvider

// ================= Pared =================
class Wall extends PositionComponent with CollisionCallbacks {
  Wall({required super.position, required super.size, super.anchor = Anchor.topLeft});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = const Color(0xFF7E57C2));
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
    canvas.drawCircle(Offset.zero, size.x / 2, Paint()..color = const Color(0xFF3D5AFE));
  }
}

// ================= Jugador =================
// Define la clase para el personaje del jugador.
class Player extends PositionComponent
    with HasGameRef<SkullMazeGame>, CollisionCallbacks {
  // Constructor que recibe la posición inicial del jugador. El ancla por defecto es el centro.
  Player({required super.position, super.anchor = Anchor.center});

  Vector2 _previousPosition = Vector2.zero(); // Almacena la posición anterior del jugador para revertir movimientos no válidos.
  final double playerSpeed = 2000; // Define la velocidad de movimiento del jugador.
  bool _goalReached = false; // Bandera para saber si el jugador ha alcanzado la meta.

  @override
  Future<void> onLoad() async {
    super.onLoad(); // Llama al metodo onLoad de la clase padre.
    size = Vector2.all(20); // Establece el tamaño del jugador a 20x20 píxeles.
    add(CircleHitbox()..radius = size.x / 2); // Añade un 'hitbox' circular para colisiones precisas.
    _previousPosition = position.clone(); // Guarda la posición inicial como la "anterior".
  }

  // Intenta mover al jugador con verificación de colisiones.
  void tryMove(Vector2 delta, double dt) {
    if (delta == Vector2.zero()) return; // Evita movimientos nulos.

    _previousPosition = position.clone(); // Guarda la posición actual antes de moverse.
    Vector2 newPosition = position + delta * dt * playerSpeed; // Calcula la nueva posición.

    // Verifica colisiones con las paredes antes de mover.
    bool canMove = true;
    for (var wall in gameRef.walls) {
      if (wall != null && _willCollide(newPosition, wall)) {
        canMove = false;
        break;
      }
    }

    if (canMove) {
      position = newPosition; // Aplica el movimiento si no hay colisión.
    } else {
      position = _previousPosition; // Revierte a la posición anterior si hay colisión.
    }

    // Limita la posición del jugador para que no se salga de los límites del lienzo del juego.
    position.x = position.x.clamp(size.x / 2, gameRef.canvasSize.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, gameRef.canvasSize.y - size.y / 2);
  }

  bool _willCollide(Vector2 newPosition, Wall wall) {
    if (wall == null) return false;
    // Verificar que el tamaño de la pared no sea inválido
    if (wall.size.x <= 0 || wall.size.y <= 0) return false;

    // Calcular la distancia del centro del círculo a los bordes del rectángulo
    double circleRadius = size.x / 2;
    if (circleRadius.isNaN || circleRadius.isInfinite) return false;
    double circleDistanceX = (newPosition.x - wall.position.x - wall.size.x / 2).abs();
    double circleDistanceY = (newPosition.y - wall.position.y - wall.size.y / 2).abs();
    if (circleDistanceX.isNaN || circleDistanceX.isInfinite || circleDistanceY.isNaN || circleDistanceY.isInfinite) return false;

    if (circleDistanceX > (wall.size.x / 2 + circleRadius)) return false;
    if (circleDistanceY > (wall.size.y / 2 + circleRadius)) return false;

    if (circleDistanceX <= (wall.size.x / 2)) return true;
    if (circleDistanceY <= (wall.size.y / 2)) return true;

    // Validar las restas antes de calcular el cuadrado
    double deltaX = circleDistanceX - wall.size.x / 2;
    double deltaY = circleDistanceY - wall.size.y / 2;
    if (deltaX.isNaN || deltaX.isInfinite || deltaY.isNaN || deltaY.isInfinite) return false;

    double cornerDistanceSq = deltaX * deltaX + deltaY * deltaY;

    return cornerDistanceSq <= circleRadius * circleRadius;
  }

  @override
  // Se llama cuando el jugador colisiona con otro componente.
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other); // Llama al metodo de la clase padre.
    if (other is Goal) {
      // Si la colisión es con la meta...
      print('¡Meta alcanzada en el nivel ${gameRef.level}!'); // Imprime un mensaje en la consola.
      _goalReached = true; // Marca que la meta ha sido alcanzada.
      gameRef.nextLevel(); // Llama al metodo para pasar al siguiente nivel.
    }
    if (other is Wall) {
      // Si la colisión es con un muro...
      position = _previousPosition; // ...revierte la posición del jugador a la que tenía antes de moverse.
      final Vector2 movementDelta = position - _previousPosition; // Calcula la diferencia de posición entre la posición actual y la anterior.
      if (movementDelta.x.abs() > movementDelta.y.abs()) {
        position.x = _previousPosition.x;
      } else {
        position.y = _previousPosition.y;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Dibuja al jugador en el lienzo del juego.
    canvas.drawCircle(Offset.zero, size.x / 2, Paint()
      ..color = const Color(0xFF18FFFF)); // Dibuja un círculo de color cian.
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
  bool isPaused = false; // Estado de pausa
  bool isVolumeOn = true; // Estado del volumen
  bool isVibrationOn = true; // Estado de vibración
  double volumeLevel = 1.0; // Nivel de volumen (0.0 a 1.0)

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

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      gyroscopeEvents.listen((event) {
        _gyroDelta = Vector2(event.y * gyroSensitivity, -event.x * gyroSensitivity);
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

    List<List<int>> mazeGrid = List.generate(effectiveGridSize, (_) => List.filled(effectiveGridSize, 1));
    Random rnd = Random();
    List<Vector2> stack = [Vector2(0, 0)];
    mazeGrid[0][0] = 0; // Punto de inicio siempre abierto

    while (stack.isNotEmpty) {
      var current = stack.last;
      int x = current.x.toInt();
      int y = current.y.toInt();

      List<List<int>> directions = [
        [2, 0],
        [-2, 0],
        [0, 2],
        [0, -2],
      ];
      directions.shuffle(rnd);

      bool moved = false;
      for (var dir in directions) {
        int nx = x + dir[0];
        int ny = y + dir[1];

        if (nx >= 0 && nx < effectiveGridSize && ny >= 0 && ny < effectiveGridSize && mazeGrid[ny][nx] == 1) {
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

    // Asegurar camino a la meta
    int endX = effectiveGridSize - 1;
    int endY = effectiveGridSize - 1;
    if (mazeGrid[endY][endX] == 1) {
      // Si la meta está bloqueada, abrir un camino hacia ella
      List<List<int>> path = [];
      int cx = 0, cy = 0;
      while (cx != endX || cy != endY) {
        mazeGrid[cy][cx] = 0;
        path.add([cx, cy]);
        int nextX = cx;
        int nextY = cy;
        if (cx < endX) nextX++;
        else if (cx > endX) nextX--;
        else if (cy < endY) nextY++;
        else if (cy > endY) nextY--;
        cx = nextX;
        cy = nextY;
      }
      mazeGrid[endY][endX] = 0; // Asegurar que la meta esté abierta
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
    goal.position = Vector2((effectiveGridSize - 1) * cellSize + cellSize / 2, (effectiveGridSize - 1) * cellSize + cellSize / 2);
  }

  void nextLevel() {
    level++;
    generateMaze();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isPaused) {
      Vector2 keyboardDelta = Vector2.zero();
      if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) || _pressedKeys.contains(LogicalKeyboardKey.keyW)) {
          keyboardDelta.y = -1;
        }
        if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) || _pressedKeys.contains(LogicalKeyboardKey.keyS)) {
          keyboardDelta.y = 1;
        }
        if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
          keyboardDelta.x = -1;
        }
        if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) || _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
          keyboardDelta.x = 1;
        }
        if (keyboardDelta != Vector2.zero() && player != null) {
          player!.tryMove(keyboardDelta.normalized() * dt, dt);
        }
      }

      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) && player != null && _gyroDelta.length > 0.5) {
        player!.tryMove(_gyroDelta.normalized(), dt);
        _gyroDelta = Vector2.zero();
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _position = details.localPosition - Offset(_joystickRadius, _joystickRadius);
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _position = details.localPosition - Offset(_joystickRadius, _joystickRadius);
          double distance = _position.distance;
          if (distance > _joystickRadius - _knobRadius) {
            double angle = _position.direction;
            _position = Offset.fromDirection(angle, _joystickRadius - _knobRadius);
          }
          if (distance > 10) {
            widget.onMove(Vector2(
                _position.dx / (_joystickRadius - _knobRadius), _position.dy / (_joystickRadius - _knobRadius))
                .normalized() *
                0.25);
          } else {
            widget.onMove(Vector2.zero());
          }
        });
      },
      onPanEnd: (_) {
        setState(() {
          _position = Offset.zero;
          widget.onMove(Vector2.zero());
        });
      },
      child: Container(
        width: _joystickRadius * 2,
        height: _joystickRadius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.3),
        ),
        child: Stack(
          children: [
            Positioned(
              left: _joystickRadius + _position.dx - _knobRadius,
              top: _joystickRadius + _position.dy - _knobRadius,
              child: Container(
                width: _knobRadius * 2,
                height: _knobRadius * 2,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB0BEC5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Pantalla del juego =================
class GameScreen extends ConsumerWidget {
  final String level;

  const GameScreen({super.key, required this.level});

  Future<void> _playClickSound(SkullMazeGame game) async {
    if (game.isVolumeOn) {
      // Comentado temporalmente para evitar errores si los archivos no existen
      // final clickPlayer = AudioPlayer();
      // await clickPlayer.play(AssetSource('audio/pause.mp3'), volume: game.volumeLevel);
      // await clickPlayer.dispose();
      return; // Desactiva audio temporalmente
    }
  }

  Future<void> _playOptionClickSound(SkullMazeGame game) async {
    if (game.isVolumeOn) {
      // Comentado temporalmente para evitar errores si los archivos no existen
      // final clickPlayer = AudioPlayer();
      // await clickPlayer.play(AssetSource('audio/b_menu.mp3'), volume: game.volumeLevel);
      // await clickPlayer.dispose();
      return; // Desactiva audio temporalmente
    }
  }

  Future<void> _startLevelMusic(SkullMazeGame game, BuildContext context, WidgetRef ref) async {
    // Pause global music
    final globalPlayer = ref.read(audioPlayerProvider);
    await globalPlayer.pause();

    if (game.isVolumeOn) {
      // Comentado temporalmente para evitar errores si los archivos no existen
      // final levelMusicPlayer = AudioPlayer();
      // await levelMusicPlayer.setSource(AssetSource('audio/level.mp3'));
      // await levelMusicPlayer.setReleaseMode(ReleaseMode.loop);
      // await levelMusicPlayer.setVolume(0.0);
      // await levelMusicPlayer.play(AssetSource('audio/level.mp3'));
      // const fadeDuration = Duration(seconds: 2);
      // const steps = 20;
      // final durationStep = fadeDuration.inMilliseconds ~/ steps;
      // double currentVolume = 0.0;
      // double volumeStep = game.volumeLevel / steps;
      // for (int i = 0; i < steps; i++) {
      //   if (!context.mounted) {
      //     await levelMusicPlayer.stop();
      //     await levelMusicPlayer.dispose();
      //     return;
      //   }
      //   currentVolume += volumeStep;
      //   await levelMusicPlayer.setVolume(currentVolume.clamp(0.0, game.volumeLevel));
      //   await Future.delayed(Duration(milliseconds: durationStep));
      // }
      // await levelMusicPlayer.setVolume(game.volumeLevel);
      // _levelMusicPlayer = levelMusicPlayer;
      return; // Desactiva audio temporalmente
    }
  }

  static AudioPlayer? _levelMusicPlayer;

  void _showPauseMenu(BuildContext context, WidgetRef ref) {
    final game = SkullMazeGame()..level = int.parse(level);
    _playClickSound(game);
    if (game.isVolumeOn && _levelMusicPlayer != null) {
      // Comentado temporalmente para evitar errores
      // _levelMusicPlayer!.pause();
    }
    game.isPaused = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: Text('Pausa', style: GoogleFonts.pressStart2p(color: const Color(0xFF7CFC00))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                await _playOptionClickSound(game);
                game.isPaused = false;
                if (game.isVolumeOn && _levelMusicPlayer != null) {
                  // Comentado temporalmente para evitar errores
                  // await _levelMusicPlayer!.setVolume(game.volumeLevel);
                  // await _levelMusicPlayer!.resume();
                }
                Navigator.pop(context);
              },
              child: Text('Reanudar', style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5))),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Volumen: ', style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5))),
                Expanded(
                  child: Slider(
                    value: game.volumeLevel,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: (game.volumeLevel * 100).round().toString() + '%',
                    onChanged: (value) async {
                      game.volumeLevel = value;
                      // Comentado temporalmente para evitar errores
                      // if (game.isVolumeOn && _levelMusicPlayer != null) {
                      //   await _levelMusicPlayer!.setVolume(value);
                      // }
                      print('Volumen ajustado a $value');
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
                Text('Vibración: ', style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5))),
                Switch(
                  value: game.isVibrationOn,
                  onChanged: (value) {
                    game.isVibrationOn = value;
                    print('Vibración ${game.isVibrationOn ? "activada" : "desactivada"}');
                  },
                  activeColor: const Color(0xFF7CFC00),
                  inactiveThumbColor: const Color(0xFFB0BEC5),
                ),
              ],
            ),
            TextButton(
              onPressed: () async {
                await _playOptionClickSound(game);
                if (_levelMusicPlayer != null) {
                  // Comentado temporalmente para evitar errores
                  // await _levelMusicPlayer!.stop();
                  // await _levelMusicPlayer!.dispose();
                  _levelMusicPlayer = null;
                }
                // Resume global music
                final globalPlayer = ref.read(audioPlayerProvider);
                // Comentado temporalmente para evitar errores
                // await globalPlayer.setVolume(0.8);
                // await globalPlayer.resume();
                context.go('/levels');
              },
              child: Text('Salir', style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5))),
            ),
            TextButton(
              onPressed: game.player != null && game.player!._goalReached
                  ? () async {
                await _playOptionClickSound(game);
                game.nextLevel();
                if (_levelMusicPlayer != null) {
                  // Comentado temporalmente para evitar errores
                  // await _levelMusicPlayer!.stop();
                  // await _levelMusicPlayer!.dispose();
                  _levelMusicPlayer = null;
                }
                await _startLevelMusic(game, context, ref);
                Navigator.pop(context);
              }
                  : null,
              child: Text('Siguiente Nivel', style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = SkullMazeGame()..level = int.parse(level);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = kIsWeb ? screenSize.width < 600 : (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_levelMusicPlayer == null && game.isVolumeOn) {
        await _startLevelMusic(game, context, ref);
      }
    });

    return Scaffold(
      body: Container(
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
                game._pressedKeys.add(event.logicalKey);
              } else if (event is RawKeyUpEvent) {
                game._pressedKeys.remove(event.logicalKey);
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameWidget(
                  game: game,
                  focusNode: FocusNode(),
                ),
                if (isMobile)
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Joystick(
                      onMove: (Vector2 direction) {
                        if (game.player != null && direction.length > 0) {
                          game.player!.tryMove(direction, 0.05);
                        }
                      },
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.pause, color: Color(0xFFB0BEC5), size: 30),
                    onPressed: () => _showPauseMenu(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}