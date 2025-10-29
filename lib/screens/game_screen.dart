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
  import 'dart:async' as async;
  import 'dart:async' show StreamSubscription;
  import '../main.dart';

  // ================= Pared Optimizada =================
  class Wall extends PositionComponent with CollisionCallbacks {
    final double wallThicknessRatio = 0.85;
    static const Color neonColor = Color(0xFF7C4DFF);
    static const Color borderColor = Color(0xFFB39DDB);

    late Paint _mainPaint;
    late Paint _borderPaint;
    late RRect _rect;
    late double _reducedSize;
    late double _offset;

    Wall({required super.position, required super.size, super.anchor = Anchor.topLeft});

    @override
    Future<void> onLoad() async {
      super.onLoad();

      _reducedSize = size.x * wallThicknessRatio;
      _offset = (size.x - _reducedSize) / 2;
      double cornerRadius = _reducedSize * 0.25;

      _rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(_offset, _offset, _reducedSize, _reducedSize),
        Radius.circular(cornerRadius),
      );

      _mainPaint = Paint()..color = neonColor.withOpacity(0.85);
      _borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      add(RectangleHitbox(
        position: Vector2(_offset, _offset),
        size: Vector2.all(_reducedSize),
      ));
    }

    @override
    void render(Canvas canvas) {
      canvas.drawRRect(_rect, _mainPaint);
      canvas.drawRRect(_rect, _borderPaint);
    }
  }

  // ================= Pared de Contorno Neón Optimizada =================
  class NeonBorderWall extends PositionComponent with CollisionCallbacks {
    final double borderThickness;
    static const Color neonCyan = Color(0xFF00FFFF);

    late Paint _borderPaint;
    late Rect _rect;

    NeonBorderWall({
      required super.position,
      required super.size,
      this.borderThickness = 8.0,
      super.anchor = Anchor.topLeft,
    });

    @override
    Future<void> onLoad() async {
      super.onLoad();

      _rect = size.toRect();
      _borderPaint = Paint()
        ..color = neonCyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderThickness;

      add(RectangleHitbox());
    }

    @override
    void render(Canvas canvas) {
      canvas.drawRect(_rect, _borderPaint);
    }
  }

  // ================= Meta Optimizada =================
  class Goal extends PositionComponent with CollisionCallbacks {
    static const Color goalColor = Color(0xFF3D5AFE);
    late Paint _paint;
    late double _radius;

    Goal({
      required super.position,
      super.anchor = Anchor.center,
    });

    @override
    Future<void> onLoad() async {
      super.onLoad();
      _paint = Paint()..color = goalColor;
      _radius = size.x / 2;
      add(RectangleHitbox());
    }

    void updateSizeAndPosition(double cellSize, int gridX, int gridY, Vector2 offset) {
      size = Vector2.all(cellSize * 0.6);
      _radius = size.x / 2;
      position = Vector2(
          gridX * cellSize + cellSize / 2 + offset.x,
          gridY * cellSize + cellSize / 2 + offset.y
      );
      removeAll(children.whereType<RectangleHitbox>());
      add(RectangleHitbox());
    }

    @override
    void render(Canvas canvas) {
      canvas.drawCircle(Offset.zero, _radius, _paint);
    }
  }

  // ================= Jugador Optimizado =================
  class Player extends PositionComponent
      with HasGameRef<SkullMazeGame>, CollisionCallbacks {
    Player({
      required super.position,
      super.anchor = Anchor.center,
    });

    Vector2 _previousPosition = Vector2.zero();
    Vector2 _velocity = Vector2.zero();
    final double playerSpeed = 250.0;
    final double acceleration = 1200.0;
    final double deceleration = 1500.0;
    final double maxSpeed = 300.0;
    bool goalReached = false;

    static const Color playerColor = Color(0xFF18FFFF);
    late Paint _paint;
    late double _radius;

    int gridX = 0;
    int gridY = 0;

    @override
    Future<void> onLoad() async {
      super.onLoad();
      _paint = Paint()..color = playerColor;
      _radius = size.x / 2;
      add(CircleHitbox()..radius = _radius);
      _previousPosition = position.clone();
    }

    void updateSizeAndPosition(double cellSize, Vector2 offset) {
      size = Vector2.all(cellSize * 0.4);
      _radius = size.x / 2;
      position = Vector2(
          gridX * cellSize + cellSize / 2 + offset.x,
          gridY * cellSize + cellSize / 2 + offset.y
      );
      _previousPosition = position.clone();
      removeAll(children.whereType<CircleHitbox>());
      add(CircleHitbox()..radius = _radius);
    }

    void updateGridPosition(double cellSize, Vector2 offset) {
      gridX = ((position.x - offset.x - cellSize / 2) / cellSize).round();
      gridY = ((position.y - offset.y - cellSize / 2) / cellSize).round();
    }

    void applyInput(Vector2 input, double dt) {
      if (input.length > 0.1) {
        _velocity += input * acceleration * dt;
        if (_velocity.length > maxSpeed) {
          _velocity = _velocity.normalized() * maxSpeed;
        }
      } else {
        double currentSpeed = _velocity.length;
        if (currentSpeed > 0) {
          double newSpeed = max(0, currentSpeed - deceleration * dt);
          _velocity = _velocity.normalized() * newSpeed;
        }
      }
    }

    @override
    void update(double dt) {
      super.update(dt);

      if (_velocity.length > 0.01) {
        _previousPosition = position.clone();
        Vector2 newPosition = position + _velocity * dt;

        bool canMove = true;
        for (var wall in gameRef.walls) {
          if (_willCollide(newPosition, wall)) {
            canMove = false;

            Vector2 correction = _resolveCollision(newPosition, wall);
            newPosition = correction;
            _velocity *= 0.5;
            break;
          }
        }

        if (canMove) {
          position = newPosition;
        } else {
          position = newPosition;
        }

        double mazeWidth = gameRef.effectiveGridSize * gameRef.cellSize;
        double mazeHeight = gameRef.effectiveGridSize * gameRef.cellSize;

        double minX = gameRef.mazeOffset.x + size.x / 2;
        double maxX = gameRef.mazeOffset.x + mazeWidth - size.x / 2;
        double minY = gameRef.mazeOffset.y + size.y / 2;
        double maxY = gameRef.mazeOffset.y + mazeHeight - size.y / 2;

        if (position.x < minX || position.x > maxX) {
          position.x = position.x.clamp(minX, maxX);
          _velocity.x = 0;
        }
        if (position.y < minY || position.y > maxY) {
          position.y = position.y.clamp(minY, maxY);
          _velocity.y = 0;
        }

        updateGridPosition(gameRef.cellSize, gameRef.mazeOffset);
      }
    }

    Vector2 _resolveCollision(Vector2 newPosition, Wall wall) {
      double reducedSize = wall.size.x * wall.wallThicknessRatio;
      double offset = (wall.size.x - reducedSize) / 2;
      double wallLeft = wall.position.x + offset;
      double wallRight = wallLeft + reducedSize;
      double wallTop = wall.position.y + offset;
      double wallBottom = wallTop + reducedSize;

      double playerRadius = size.x / 2;

      double closestX = newPosition.x.clamp(wallLeft, wallRight);
      double closestY = newPosition.y.clamp(wallTop, wallBottom);

      double dx = newPosition.x - closestX;
      double dy = newPosition.y - closestY;
      double distance = sqrt(dx * dx + dy * dy);

      if (distance < playerRadius) {
        double overlap = playerRadius - distance;
        if (distance > 0) {
          double normalX = dx / distance;
          double normalY = dy / distance;
          return Vector2(
            newPosition.x + normalX * overlap,
            newPosition.y + normalY * overlap,
          );
        } else {
          return _previousPosition;
        }
      }
      return newPosition;
    }

    bool _willCollide(Vector2 newPosition, Wall wall) {
      double reducedSize = wall.size.x * wall.wallThicknessRatio;
      double offset = (wall.size.x - reducedSize) / 2;
      double wallLeft = wall.position.x + offset;
      double wallRight = wallLeft + reducedSize;
      double wallTop = wall.position.y + offset;
      double wallBottom = wallTop + reducedSize;

      double playerRadius = size.x / 2;

      double closestX = newPosition.x.clamp(wallLeft, wallRight);
      double closestY = newPosition.y.clamp(wallTop, wallBottom);

      double dx = newPosition.x - closestX;
      double dy = newPosition.y - closestY;
      double distanceSquared = dx * dx + dy * dy;

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
    }

    @override
    void render(Canvas canvas) {
      canvas.drawCircle(Offset.zero, _radius, _paint);
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
    Vector2 _inputDirection = Vector2.zero();
    static const double gyroSensitivity = 15.0;
    Vector2 _gyroInput = Vector2.zero();
    StreamSubscription<GyroscopeEvent>? _gyroSubscription;
    late int effectiveGridSize;
    late double cellSize;
    bool isPaused = false;
    bool isVolumeOn = true;
    bool isVibrationOn = true;
    bool useGyroscope = false;
    double volumeLevel = 1.0;

    List<List<int>> currentMazeGrid = [];
    Vector2 _lastCanvasSize = Vector2.zero();
    bool _isFirstLoad = true;

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
      double availableWidth = canvasSize.x * 0.9;
      double availableHeight = canvasSize.y * 0.9;
      double usableSize = min(availableWidth, availableHeight);

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

      cellSize = usableSize / effectiveGridSize;

      double mazeWidth = effectiveGridSize * cellSize;
      double mazeHeight = effectiveGridSize * cellSize;
      mazeOffset = Vector2(
          (canvasSize.x - mazeWidth) / 2,
          (canvasSize.y - mazeHeight) / 2
      );
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
        _gyroSubscription = gyroscopeEvents.listen((event) {
          if (useGyroscope && !isPaused) {
            _gyroInput = Vector2(-event.y, event.x);
          } else {
            _gyroInput = Vector2.zero();
          }
        });
      }
    }

    void toggleGyroscope(bool enabled) {
      useGyroscope = enabled;
      if (!enabled) {
        _gyroInput = Vector2.zero();
      }
    }

    @override
    void onRemove() {
      _gyroSubscription?.cancel();
      super.onRemove();
    }

    void _createBorderWalls() {
      for (var border in borderWalls) {
        border.removeFromParent();
      }
      borderWalls.clear();

      double mazeWidth = effectiveGridSize * cellSize;
      double mazeHeight = effectiveGridSize * cellSize;
      double borderThickness = cellSize * 0.4;

      var topWall = NeonBorderWall(
        position: Vector2(mazeOffset.x - borderThickness, mazeOffset.y - borderThickness),
        size: Vector2(mazeWidth + borderThickness * 2, borderThickness),
        borderThickness: borderThickness * 0.3,
      );
      borderWalls.add(topWall);
      add(topWall);

      var bottomWall = NeonBorderWall(
        position: Vector2(mazeOffset.x - borderThickness, mazeOffset.y + mazeHeight),
        size: Vector2(mazeWidth + borderThickness * 2, borderThickness),
        borderThickness: borderThickness * 0.3,
      );
      borderWalls.add(bottomWall);
      add(bottomWall);

      var leftWall = NeonBorderWall(
        position: Vector2(mazeOffset.x - borderThickness, mazeOffset.y - borderThickness),
        size: Vector2(borderThickness, mazeHeight + borderThickness * 2),
        borderThickness: borderThickness * 0.3,
      );
      borderWalls.add(leftWall);
      add(leftWall);

      var rightWall = NeonBorderWall(
        position: Vector2(mazeOffset.x + mazeWidth, mazeOffset.y - borderThickness),
        size: Vector2(borderThickness, mazeHeight + borderThickness * 2),
        borderThickness: borderThickness * 0.3,
      );
      borderWalls.add(rightWall);
      add(rightWall);
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

      _createBorderWalls();
    }

    void generateMaze() {
      for (var wall in walls) {
        wall.removeFromParent();
      }
      walls.clear();

      currentMazeGrid = List.generate(effectiveGridSize, (_) => List.filled(effectiveGridSize, 1));
      Random rnd = Random();

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

      int endX = effectiveGridSize - 2;
      int endY = effectiveGridSize - 2;

      currentMazeGrid[endY][endX] = 0;

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

      _createBorderWalls();
    }

    void nextLevel() {
      level++;
      generateMaze();
    }

    @override
    void update(double dt) {
      super.update(dt);

      if (!isPaused && player != null) {
        _inputDirection = Vector2.zero();

        if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
          if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
              _pressedKeys.contains(LogicalKeyboardKey.keyW)) {
            _inputDirection.y -= 1;
          }
          if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
              _pressedKeys.contains(LogicalKeyboardKey.keyS)) {
            _inputDirection.y += 1;
          }
          if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
              _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
            _inputDirection.x -= 1;
          }
          if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
              _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
            _inputDirection.x += 1;
          }
        }

        if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) && useGyroscope) {
          if (_gyroInput.length > 0.5) {
            _inputDirection = _gyroInput.normalized() * gyroSensitivity;
          }
        }

        if (_inputDirection.length > 0) {
          _inputDirection = _inputDirection.normalized();
        }

        player!.applyInput(_inputDirection, dt);
      }
    }
  }

  // ================= Control Buttons Widget =================
  class DirectionalButtons extends StatefulWidget {
    final Function(Vector2) onDirectionChange;
    final bool isLandscape;

    const DirectionalButtons({
      super.key,
      required this.onDirectionChange,
      required this.isLandscape,
    });

    @override
    State<DirectionalButtons> createState() => _DirectionalButtonsState();
  }

  class _DirectionalButtonsState extends State<DirectionalButtons> {
    final Set<String> _pressedButtons = {};
    async.Timer? _updateTimer;

    void _updateDirection() {
      Vector2 direction = Vector2.zero();

      if (_pressedButtons.contains('up')) direction.y -= 1;
      if (_pressedButtons.contains('down')) direction.y += 1;
      if (_pressedButtons.contains('left')) direction.x -= 1;
      if (_pressedButtons.contains('right')) direction.x += 1;

      widget.onDirectionChange(direction.length > 0 ? direction.normalized() : Vector2.zero());
    }

    void _startContinuousUpdate(String direction) {
      setState(() => _pressedButtons.add(direction));
      _updateDirection();

      _updateTimer?.cancel();
      _updateTimer = async.Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (_pressedButtons.contains(direction)) {
          _updateDirection();
        }
      });
    }

    void _stopContinuousUpdate(String direction) {
      setState(() => _pressedButtons.remove(direction));
      _updateDirection();

      if (_pressedButtons.isEmpty) {
        _updateTimer?.cancel();
        _updateTimer = null;
      }
    }

    @override
    void dispose() {
      _updateTimer?.cancel();
      super.dispose();
    }

    Widget _buildButton({
      required IconData icon,
      required String direction,
      required double size,
    }) {
      final isPressed = _pressedButtons.contains(direction);

      return Listener(
        onPointerDown: (_) {
          HapticFeedback.lightImpact();
          _startContinuousUpdate(direction);
        },
        onPointerUp: (_) {
          _stopContinuousUpdate(direction);
        },
        onPointerCancel: (_) {
          _stopContinuousUpdate(direction);
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isPressed
                ? const Color(0xFF7CFC00).withOpacity(0.6)
                : const Color(0xFF424242).withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF7CFC00),
              width: 2,
            ),
            boxShadow: isPressed ? [
              BoxShadow(
                color: const Color(0xFF7CFC00).withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ] : [],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      final screenSize = MediaQuery.of(context).size;
      final minDimension = min(screenSize.width, screenSize.height);
      final buttonSize = minDimension * 0.12;
      final spacing = minDimension * 0.02;

      if (widget.isLandscape) {
        return Padding(
          padding: EdgeInsets.all(minDimension * 0.03),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(
                icon: Icons.arrow_upward,
                direction: 'up',
                size: buttonSize,
              ),
              SizedBox(height: spacing),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildButton(
                    icon: Icons.arrow_back,
                    direction: 'left',
                    size: buttonSize,
                  ),
                  SizedBox(width: spacing),
                  _buildButton(
                    icon: Icons.arrow_downward,
                    direction: 'down',
                    size: buttonSize,
                  ),
                  SizedBox(width: spacing),
                  _buildButton(
                    icon: Icons.arrow_forward,
                    direction: 'right',
                    size: buttonSize,
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        return Padding(
          padding: EdgeInsets.all(minDimension * 0.03),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(
                icon: Icons.arrow_upward,
                direction: 'up',
                size: buttonSize,
              ),
              SizedBox(height: spacing),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildButton(
                    icon: Icons.arrow_back,
                    direction: 'left',
                    size: buttonSize,
                  ),
                  SizedBox(width: buttonSize + spacing * 2),
                  _buildButton(
                    icon: Icons.arrow_forward,
                    direction: 'right',
                    size: buttonSize,
                  ),
                ],
              ),
              SizedBox(height: spacing),
              _buildButton(
                icon: Icons.arrow_downward,
                direction: 'down',
                size: buttonSize,
              ),
            ],
          ),
        );
      }
    }
  }

  // ================= Pantalla del juego =================
  class GameScreen extends ConsumerStatefulWidget {
    final String level;

    const GameScreen({super.key, required this.level});

    @override
    ConsumerState<GameScreen> createState() => _GameScreenState();
  }

  class _GameScreenState extends ConsumerState<GameScreen> {
    static AudioPlayer? _levelMusicPlayer;
    late SkullMazeGame game;

    @override
    void initState() {
      super.initState();
      game = SkullMazeGame()..level = int.parse(widget.level);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startLevelMusic();
      });
    }

    @override
    void dispose() {
      _stopLevelMusic();
      game.onRemove();
      super.dispose();
    }

    Future<void> _playClickSound() async {
      if (game.isVolumeOn) {
        final clickPlayer = AudioPlayer();
        await clickPlayer.play(AssetSource('audio/click.mp3'));
        await clickPlayer.setVolume(game.volumeLevel);
      }
    }

    Future<void> _startLevelMusic() async {
      final globalPlayer = ref.read(audioPlayerProvider);
      await globalPlayer.pause();

      if (game.isVolumeOn && _levelMusicPlayer == null) {
        _levelMusicPlayer = AudioPlayer();
        await _levelMusicPlayer!.setReleaseMode(ReleaseMode.loop);
        await _levelMusicPlayer!.play(AssetSource('audio/level.mp3'));
        await _levelMusicPlayer!.setVolume(game.volumeLevel);
      }
    }

    Future<void> _stopLevelMusic() async {
      if (_levelMusicPlayer != null) {
        await _levelMusicPlayer!.stop();
        await _levelMusicPlayer!.dispose();
        _levelMusicPlayer = null;
      }
    }

    void _showPauseMenu() {
      _playClickSound();
      if (game.isVolumeOn && _levelMusicPlayer != null) {
        _levelMusicPlayer!.pause();
      }
      game.isPaused = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF1C1C1C),
            title: Text('Pausa', style: GoogleFonts.pressStart2p(color: const Color(0xFF7CFC00))),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () async {
                      await _playClickSound();
                      game.isPaused = false;
                      if (game.isVolumeOn && _levelMusicPlayer != null) {
                        _levelMusicPlayer!.resume();
                      }
                      Navigator.pop(context);
                    },
                    child: Text('Reanudar', style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5))),
                  ),
                  const SizedBox(height: 10),
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
                            setDialogState(() {
                              game.volumeLevel = value;
                            });
                            setState(() {});
                            if (_levelMusicPlayer != null) {
                              await _levelMusicPlayer!.setVolume(value);
                            }
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
                          setDialogState(() {
                            game.isVibrationOn = value;
                          });
                          setState(() {});
                          if (value) {
                            HapticFeedback.mediumImpact();
                          }
                        },
                        activeColor: const Color(0xFF7CFC00),
                        inactiveThumbColor: const Color(0xFFB0BEC5),
                      ),
                    ],
                  ),
                  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS))
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Giroscopio: ', style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5))),
                        Switch(
                          value: game.useGyroscope,
                          onChanged: (value) {
                            setDialogState(() {
                              game.toggleGyroscope(value);
                            });
                            setState(() {});
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
                      await _playClickSound();
                      await _stopLevelMusic();
                      final globalPlayer = ref.read(audioPlayerProvider);
                      await globalPlayer.resume();
                      if (mounted && context.mounted) {
                        Navigator.pop(context);
                        context.go('/levels');
                      }
                    },
                    child: Text('Salir', style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5))),
                  ),
                  TextButton(
                    onPressed: game.player != null && game.player!.goalReached
                        ? () async {
                      await _playClickSound();
                      if (game.isVibrationOn) {
                        HapticFeedback.heavyImpact();
                      }
                      game.nextLevel();
                      await _stopLevelMusic();
                      await _startLevelMusic();
                      Navigator.pop(context);
                      game.isPaused = false;
                    }
                        : null,
                    child: Text('Siguiente Nivel', style: GoogleFonts.openSans(color: const Color(0xFFB0BEC5))),
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
                      if (isMobile && !game.useGyroscope)
                        Positioned(
                          left: isLandscape ? controlsHorizontalPadding : null,
                          right: isLandscape ? null : controlsHorizontalPadding,
                          bottom: controlsBottomPadding,
                          child: DirectionalButtons(
                            onDirectionChange: (Vector2 direction) {
                              if (game.player != null && !game.isPaused) {
                                game._inputDirection = direction;
                              }
                            },
                            isLandscape: isLandscape,
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
                          onPressed: () {
                            if (game.isVibrationOn) {
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
                      if (isMobile && game.useGyroscope)
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