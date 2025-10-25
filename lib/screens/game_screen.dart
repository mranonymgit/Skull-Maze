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
import '../main.dart';

// ================= Pared =================
class Wall extends PositionComponent with CollisionCallbacks {
  final double wallThicknessRatio = 0.85; // 85% del tamaño de celda
  double _glowIntensity = 0.0;
  bool _increasing = true;

  Wall({required super.position, required super.size, super.anchor = Anchor.topLeft});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Calcular el tamaño de la pared
    double reducedSize = size.x * wallThicknessRatio;
    double offset = (size.x - reducedSize) / 2;

    // Hitbox rectangular ajustada
    add(RectangleHitbox(
      position: Vector2(offset, offset),
      size: Vector2.all(reducedSize),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Animación pulsante sincronizada
    if (_increasing) {
      _glowIntensity += dt * 1.5;
      if (_glowIntensity >= 1.0) {
        _glowIntensity = 1.0;
        _increasing = false;
      }
    } else {
      _glowIntensity -= dt * 1.5;
      if (_glowIntensity <= 0.3) {
        _glowIntensity = 0.3;
        _increasing = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Calcular el tamaño y posición de la pared
    double reducedSize = size.x * wallThicknessRatio;
    double offset = (size.x - reducedSize) / 2;
    double cornerRadius = reducedSize * 0.25; // Radio de las esquinas redondeadas

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(offset, offset, reducedSize, reducedSize),
      Radius.circular(cornerRadius),
    );

    // Color neón azul/púrpura brillante (estilo Pac-Man)
    final neonColor = Color.lerp(
      const Color(0xFF5E35B1).withOpacity(0.7),
      const Color(0xFF7C4DFF),
      _glowIntensity,
    )!;

    // Efecto de resplandor múltiple (glow) - capas exteriores
    for (int i = 5; i > 0; i--) {
      final glowPaint = Paint()
        ..color = neonColor.withOpacity(0.1 * _glowIntensity * i)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cornerRadius * 0.4 * i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offset - i, offset - i, reducedSize + i * 2, reducedSize + i * 2),
          Radius.circular(cornerRadius + i),
        ),
        glowPaint,
      );
    }

    // Rectángulo principal con color sólido
    final mainPaint = Paint()
      ..color = Color.lerp(neonColor, const Color(0xFF9575CD), 0.3)!;
    canvas.drawRRect(rect, mainPaint);

    // Borde brillante exterior
    final borderPaint = Paint()
      ..color = Color.lerp(const Color(0xFF7C4DFF), const Color(0xFFB39DDB), _glowIntensity * 0.8)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rect, borderPaint);

    // Highlight interior superior izquierdo (efecto 3D)
    final highlightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(offset + 2, offset + 2, reducedSize * 0.4, reducedSize * 0.4),
      Radius.circular(cornerRadius * 0.5),
    );
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.15 * _glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(highlightRect, highlightPaint);
  }
}

// ================= Pared de Contorno Neón =================
class NeonBorderWall extends PositionComponent with CollisionCallbacks {
  final double borderThickness;
  double _glowIntensity = 0.0;
  bool _increasing = true;

  NeonBorderWall({
    required super.position,
    required super.size,
    this.borderThickness = 8.0,
    super.anchor = Anchor.topLeft,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Agregar hitbox para colisión
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Animación pulsante
    if (_increasing) {
      _glowIntensity += dt * 2;
      if (_glowIntensity >= 1.0) {
        _glowIntensity = 1.0;
        _increasing = false;
      }
    } else {
      _glowIntensity -= dt * 2;
      if (_glowIntensity <= 0.3) {
        _glowIntensity = 0.3;
        _increasing = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();

    // Color neón cian brillante
    final neonColor = Color.lerp(
      const Color(0xFF00FFFF).withOpacity(0.6),
      const Color(0xFF00FFFF),
      _glowIntensity,
    )!;

    // Efecto de resplandor múltiple (glow)
    for (int i = 3; i > 0; i--) {
      final glowPaint = Paint()
        ..color = neonColor.withOpacity(0.15 * _glowIntensity * i)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, borderThickness * i * 0.5);
      canvas.drawRect(rect, glowPaint);
    }

    // Borde principal neón
    final borderPaint = Paint()
      ..color = neonColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderThickness;
    canvas.drawRect(rect, borderPaint);

    // Línea interior más brillante
    final innerGlowPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.4 * _glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderThickness * 0.3;
    canvas.drawRect(rect.deflate(borderThickness * 0.3), innerGlowPaint);
  }
}

// ================= Meta =================
class Goal extends PositionComponent with CollisionCallbacks {
  Goal({
    required super.position,
    super.anchor = Anchor.center,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
  }

  void updateSizeAndPosition(double cellSize, int gridX, int gridY, Vector2 offset) {
    size = Vector2.all(cellSize * 0.6);
    position = Vector2(
        gridX * cellSize + cellSize / 2 + offset.x,
        gridY * cellSize + cellSize / 2 + offset.y
    );
    removeAll(children.whereType<RectangleHitbox>());
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, size.x / 2, Paint()..color = const Color(0xFF3D5AFE));
  }
}

// ================= Jugador =================
class Player extends PositionComponent
    with HasGameRef<SkullMazeGame>, CollisionCallbacks {
  Player({
    required super.position,
    super.anchor = Anchor.center,
  });

  Vector2 _previousPosition = Vector2.zero();
  final double playerSpeed = 2000;
  bool goalReached = false;

  int gridX = 0;
  int gridY = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox()..radius = size.x / 2);
    _previousPosition = position.clone();
  }

  void updateSizeAndPosition(double cellSize, Vector2 offset) {
    size = Vector2.all(cellSize * 0.4);
    position = Vector2(
        gridX * cellSize + cellSize / 2 + offset.x,
        gridY * cellSize + cellSize / 2 + offset.y
    );
    _previousPosition = position.clone();
    removeAll(children.whereType<CircleHitbox>());
    add(CircleHitbox()..radius = size.x / 2);
  }

  void updateGridPosition(double cellSize, Vector2 offset) {
    gridX = ((position.x - offset.x - cellSize / 2) / cellSize).round();
    gridY = ((position.y - offset.y - cellSize / 2) / cellSize).round();
  }

  void tryMove(Vector2 delta, double dt) {
    if (delta == Vector2.zero()) return;

    _previousPosition = position.clone();
    Vector2 newPosition = position + delta * dt * playerSpeed;

    bool canMove = true;
    for (var wall in gameRef.walls) {
      if (wall != null && _willCollide(newPosition, wall)) {
        canMove = false;
        break;
      }
    }

    if (canMove) {
      position = newPosition;
    } else {
      position = _previousPosition;
    }

    // Límites basados en el offset y tamaño del laberinto
    double mazeWidth = gameRef.effectiveGridSize * gameRef.cellSize;
    double mazeHeight = gameRef.effectiveGridSize * gameRef.cellSize;
    position.x = position.x.clamp(
        gameRef.mazeOffset.x + size.x / 2,
        gameRef.mazeOffset.x + mazeWidth - size.x / 2
    );
    position.y = position.y.clamp(
        gameRef.mazeOffset.y + size.y / 2,
        gameRef.mazeOffset.y + mazeHeight - size.y / 2
    );

    updateGridPosition(gameRef.cellSize, gameRef.mazeOffset);
  }

  bool _willCollide(Vector2 newPosition, Wall wall) {
    if (wall == null) return false;
    if (wall.size.x <= 0 || wall.size.y <= 0) return false;

    // Calcular el rectángulo de la pared (con tamaño reducido)
    double reducedSize = wall.size.x * wall.wallThicknessRatio;
    double offset = (wall.size.x - reducedSize) / 2;
    double wallLeft = wall.position.x + offset;
    double wallRight = wallLeft + reducedSize;
    double wallTop = wall.position.y + offset;
    double wallBottom = wallTop + reducedSize;

    double playerRadius = size.x / 2;
    if (playerRadius.isNaN || playerRadius.isInfinite) return false;

    // Encontrar el punto más cercano del rectángulo al círculo del jugador
    double closestX = newPosition.x.clamp(wallLeft, wallRight);
    double closestY = newPosition.y.clamp(wallTop, wallBottom);

    // Calcular distancia del centro del jugador al punto más cercano
    double dx = newPosition.x - closestX;
    double dy = newPosition.y - closestY;
    double distanceSquared = dx * dx + dy * dy;

    // Colisión si la distancia es menor que el radio del jugador
    return distanceSquared < (playerRadius * playerRadius);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Goal) {
      print('¡Meta alcanzada en el nivel ${gameRef.level}!');
      goalReached = true;
      gameRef.nextLevel();
    }
    if (other is Wall || other is NeonBorderWall) {
      position = _previousPosition;
      final Vector2 movementDelta = position - _previousPosition;
      if (movementDelta.x.abs() > movementDelta.y.abs()) {
        position.x = _previousPosition.x;
      } else {
        position.y = _previousPosition.y;
      }
    }
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
  Goal? goal;
  int level = 1;
  final List<Wall> walls = [];
  final List<NeonBorderWall> borderWalls = [];
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  static const double gyroSensitivity = 100.0;
  Vector2 _gyroDelta = Vector2.zero();
  late int effectiveGridSize;
  late double cellSize;
  bool isPaused = false;
  bool isVolumeOn = true;
  bool isVibrationOn = true;
  double volumeLevel = 1.0;

  List<List<int>> currentMazeGrid = [];
  Vector2 _lastCanvasSize = Vector2.zero();
  bool _isFirstLoad = true;

  // Offset para centrar el laberinto
  Vector2 mazeOffset = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _calculateGridAndCellSize();
    _initializeGameComponents();
    _setupGyroscope();
    _isFirstLoad = false;
  }

  void _calculateGridAndCellSize() {
    // Usar un porcentaje del espacio disponible (90% para dejar márgenes)
    double availableWidth = canvasSize.x * 0.9;
    double availableHeight = canvasSize.y * 0.9;
    double usableSize = min(availableWidth, availableHeight);

    // Determinar gridSize solo la primera vez
    if (_isFirstLoad || currentMazeGrid.isEmpty) {
      if (usableSize < 400) {
        effectiveGridSize = (usableSize / 35).floor().clamp(10, 15).toInt();
      } else if (usableSize < 600) {
        effectiveGridSize = (usableSize / 40).floor().clamp(15, 20).toInt();
      } else if (usableSize < 800) {
        effectiveGridSize = (usableSize / 40).floor().clamp(18, 25).toInt();
      } else {
        effectiveGridSize = (usableSize / 45).floor().clamp(20, 30).toInt();
      }
    }

    // Calcular cellSize para usar el máximo espacio disponible
    cellSize = usableSize / effectiveGridSize;

    // Calcular offset para centrar el laberinto
    double mazeWidth = effectiveGridSize * cellSize;
    double mazeHeight = effectiveGridSize * cellSize;
    mazeOffset = Vector2(
        (canvasSize.x - mazeWidth) / 2,
        (canvasSize.y - mazeHeight) / 2
    );

    print('Tamaño canvas: ${canvasSize.x} x ${canvasSize.y}');
    print('Grid: ${effectiveGridSize}x${effectiveGridSize}');
    print('Cell size: $cellSize');
    print('Maze offset: $mazeOffset');
  }

  void _initializeGameComponents() {
    player = Player(
      position: Vector2(cellSize / 2 + mazeOffset.x, cellSize / 2 + mazeOffset.y),
    );
    player!.size = Vector2.all(cellSize * 0.4);
    player!.gridX = 0;
    player!.gridY = 0;
    add(player!);

    goal = Goal(
      position: Vector2.zero(),
    );
    add(goal!);

    generateMaze();

    camera.follow(player!);
  }

  void _setupGyroscope() {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      gyroscopeEvents.listen((event) {
        _gyroDelta = Vector2(event.y * gyroSensitivity, -event.x * gyroSensitivity);
      });
    }
  }

  void _createBorderWalls() {
    // Remover paredes de contorno anteriores
    for (var border in borderWalls) {
      border.removeFromParent();
    }
    borderWalls.clear();

    double mazeWidth = effectiveGridSize * cellSize;
    double mazeHeight = effectiveGridSize * cellSize;
    double borderThickness = cellSize * 0.4;

    // Pared superior
    var topWall = NeonBorderWall(
      position: Vector2(mazeOffset.x - borderThickness, mazeOffset.y - borderThickness),
      size: Vector2(mazeWidth + borderThickness * 2, borderThickness),
      borderThickness: borderThickness * 0.3,
    );
    borderWalls.add(topWall);
    add(topWall);

    // Pared inferior
    var bottomWall = NeonBorderWall(
      position: Vector2(mazeOffset.x - borderThickness, mazeOffset.y + mazeHeight),
      size: Vector2(mazeWidth + borderThickness * 2, borderThickness),
      borderThickness: borderThickness * 0.3,
    );
    borderWalls.add(bottomWall);
    add(bottomWall);

    // Pared izquierda
    var leftWall = NeonBorderWall(
      position: Vector2(mazeOffset.x - borderThickness, mazeOffset.y - borderThickness),
      size: Vector2(borderThickness, mazeHeight + borderThickness * 2),
      borderThickness: borderThickness * 0.3,
    );
    borderWalls.add(leftWall);
    add(leftWall);

    // Pared derecha
    var rightWall = NeonBorderWall(
      position: Vector2(mazeOffset.x + mazeWidth, mazeOffset.y - borderThickness),
      size: Vector2(borderThickness, mazeHeight + borderThickness * 2),
      borderThickness: borderThickness * 0.3,
    );
    borderWalls.add(rightWall);
    add(rightWall);

    print('Paredes de contorno neón creadas');
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);

    if ((_lastCanvasSize - newSize).length < 10) return;

    _lastCanvasSize = newSize.clone();

    _calculateGridAndCellSize();
    _rescaleMaze();

    camera.viewport.size = newSize;
  }

  void _rescaleMaze() {
    if (currentMazeGrid.isEmpty) return;

    print('Re-escalando laberinto centrado...');

    if (player != null) {
      player!.updateSizeAndPosition(cellSize, mazeOffset);
    }

    if (goal != null) {
      int goalX = effectiveGridSize - 2;
      int goalY = effectiveGridSize - 2;
      goal!.updateSizeAndPosition(cellSize, goalX, goalY, mazeOffset);
    }

    for (var wall in walls) {
      wall.removeFromParent();
    }
    walls.clear();

    for (int y = 0; y < effectiveGridSize; y++) {
      for (int x = 0; x < effectiveGridSize; x++) {
        if (currentMazeGrid[y][x] == 1) {
          var wall = Wall(
            position: Vector2(x * cellSize + mazeOffset.x, y * cellSize + mazeOffset.y),
            size: Vector2.all(cellSize),
          );
          walls.add(wall);
          add(wall);
        }
      }
    }

    // Recrear paredes de contorno
    _createBorderWalls();

    print('Re-escalado completo. Cell size: $cellSize, Offset: $mazeOffset');
  }

  void generateMaze() {
    print('Generando laberinto para nivel $level...');

    for (var wall in walls) {
      wall.removeFromParent();
    }
    walls.clear();

    currentMazeGrid = List.generate(effectiveGridSize, (_) => List.filled(effectiveGridSize, 1));
    Random rnd = Random();

    // Empezar desde una posición interior, no en el borde
    List<Vector2> stack = [Vector2(1, 1)];
    currentMazeGrid[1][1] = 0;

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

        // Asegurar que no se generen caminos en los bordes exteriores
        if (nx > 0 && nx < effectiveGridSize - 1 &&
            ny > 0 && ny < effectiveGridSize - 1 &&
            currentMazeGrid[ny][nx] == 1) {
          currentMazeGrid[ny][nx] = 0;
          currentMazeGrid[y + dir[1] ~/ 2][x + dir[0] ~/ 2] = 0;
          stack.add(Vector2(nx.toDouble(), ny.toDouble()));
          moved = true;
          break;
        }
      }
      if (!moved) {
        stack.removeLast();
      }
    }

    // Definir posición de la meta (alejada del borde)
    int endX = effectiveGridSize - 2;
    int endY = effectiveGridSize - 2;

    // Asegurar que hay un camino desde el inicio hasta la meta
    currentMazeGrid[endY][endX] = 0;

    // Crear camino desde (1,1) hasta la meta si es necesario
    int cx = 1, cy = 1;
    while (cx != endX || cy != endY) {
      currentMazeGrid[cy][cx] = 0;
      if (cx < endX && rnd.nextBool()) {
        cx++;
      } else if (cy < endY) {
        cy++;
      } else if (cx < endX) {
        cx++;
      }
      if (cx >= effectiveGridSize - 1) cx = effectiveGridSize - 2;
      if (cy >= effectiveGridSize - 1) cy = effectiveGridSize - 2;
    }
    currentMazeGrid[endY][endX] = 0;

    // Los bordes ya son paredes por defecto (se inicializó todo con 1)
    // Solo necesitamos abrir la entrada en la esquina superior izquierda
    currentMazeGrid[0][0] = 0;
    currentMazeGrid[0][1] = 0;
    currentMazeGrid[1][0] = 0;

    for (int y = 0; y < effectiveGridSize; y++) {
      for (int x = 0; x < effectiveGridSize; x++) {
        if (currentMazeGrid[y][x] == 1) {
          var wall = Wall(
            position: Vector2(x * cellSize + mazeOffset.x, y * cellSize + mazeOffset.y),
            size: Vector2.all(cellSize),
          );
          walls.add(wall);
          add(wall);
        }
      }
    }

    if (player != null) {
      player!.gridX = 0;
      player!.gridY = 0;
      player!.updateSizeAndPosition(cellSize, mazeOffset);
    }

    if (goal != null) {
      goal!.updateSizeAndPosition(cellSize, endX, endY, mazeOffset);
    }

    // Crear paredes de contorno neón
    _createBorderWalls();
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
  double _joystickRadius = 60;
  double _knobRadius = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenSize = MediaQuery.of(context).size;
    final minDimension = min(screenSize.width, screenSize.height);

    if (minDimension < 400) {
      _joystickRadius = 50;
      _knobRadius = 18;
    } else if (minDimension < 600) {
      _joystickRadius = 60;
      _knobRadius = 20;
    } else {
      _joystickRadius = 70;
      _knobRadius = 25;
    }
  }

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
      return;
    }
  }

  Future<void> _playOptionClickSound(SkullMazeGame game) async {
    if (game.isVolumeOn) {
      return;
    }
  }

  Future<void> _startLevelMusic(SkullMazeGame game, BuildContext context, WidgetRef ref) async {
    final globalPlayer = ref.read(audioPlayerProvider);
    await globalPlayer.pause();

    if (game.isVolumeOn) {
      return;
    }
  }

  static AudioPlayer? _levelMusicPlayer;

  void _showPauseMenu(BuildContext context, WidgetRef ref, SkullMazeGame game) {
    _playClickSound(game);
    if (game.isVolumeOn && _levelMusicPlayer != null) {
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
                    label: '${(game.volumeLevel * 100).round()}%',
                    onChanged: (value) async {
                      game.volumeLevel = value;
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
                  _levelMusicPlayer = null;
                }
                final globalPlayer = ref.read(audioPlayerProvider);
                if (context.mounted) {
                  context.go('/levels');
                }
              },
              child: Text('Salir', style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5))),
            ),
            TextButton(
              onPressed: game.player != null && game.player!.goalReached
                  ? () async {
                await _playOptionClickSound(game);
                game.nextLevel();
                if (_levelMusicPlayer != null) {
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

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          final isMobile = kIsWeb
              ? screenSize.width < 600
              : (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (_levelMusicPlayer == null && game.isVolumeOn) {
              await _startLevelMusic(game, context, ref);
            }
          });

          final minDimension = min(screenSize.width, screenSize.height);
          final joystickBottomPadding = isMobile ? minDimension * 0.05 : 20.0;
          final joystickLeftPadding = isMobile ? minDimension * 0.05 : 20.0;
          final pauseButtonSize = isMobile ? minDimension * 0.08 : 30.0;
          final pauseButtonPadding = isMobile ? minDimension * 0.02 : 10.0;

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
                        left: joystickLeftPadding,
                        bottom: joystickBottomPadding,
                        child: Joystick(
                          onMove: (Vector2 direction) {
                            if (game.player != null && direction.length > 0) {
                              game.player!.tryMove(direction, 0.05);
                            }
                          },
                        ),
                      ),
                    Positioned(
                      top: pauseButtonPadding,
                      right: pauseButtonPadding,
                      child: IconButton(
                        icon: Icon(
                          Icons.pause,
                          color: const Color(0xFFB0BEC5),
                          size: pauseButtonSize,
                        ),
                        onPressed: () => _showPauseMenu(context, ref, game),
                        padding: EdgeInsets.all(pauseButtonPadding / 2),
                        constraints: BoxConstraints(
                          minWidth: pauseButtonSize * 1.5,
                          minHeight: pauseButtonSize * 1.5,
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