import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async' as async;
import 'package:skull_maze/class/wall.dart';
import 'package:skull_maze/class/NeonWall.dart';
import 'package:skull_maze/class/goal.dart';
import 'package:skull_maze/class/player.dart';

// ================= The main game component =================
class SkullMazeGame extends FlameGame with HasCollisionDetection {
  Player? player;
  Goal? goal;
  int level = 1;
  final List<Wall> walls = [];
  final List<NeonBorderWall> borderWalls = [];
  final Set<LogicalKeyboardKey> pressedKeys = {};
  Vector2 inputDirection = Vector2.zero();
  static const double accelSensitivity = 0.9; // Ajuste para sensibilidad del acelerómetro
  Vector2 _accelInput = Vector2.zero();
  async.StreamSubscription<AccelerometerEvent>? _accelSubscription;
  late int effectiveGridSize;
  late double cellSize;
  bool isPaused = false;
  bool useAccelerometer = false;

  // Callbacks for to communicate with the UI
  Function()? onGoalReachedCallback;

  List<List<int>> currentMazeGrid = [];
  Vector2 _lastCanvasSize = Vector2.zero();
  bool _isFirstLoad = true;

  Vector2 mazeOffset = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _calculateGridAndCellSize();
    _initializeGameComponents();
    _setupAccelerometer();
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

  void _setupAccelerometer() {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      _accelSubscription = accelerometerEvents.listen((event) {
        if (useAccelerometer && !isPaused) {
          // Invertimos Y para que inclinar hacia adelante = arriba
          // X: izquierda/derecha
          _accelInput = Vector2(-event.x, event.y);
        } else {
          _accelInput = Vector2.zero();
        }
      });
    }
  }

  void toggleAccelerometer(bool enabled) {
    useAccelerometer = enabled;
    if (!enabled) {
      _accelInput = Vector2.zero();
    }
  }

  @override
  void onRemove() {
    _accelSubscription?.cancel();
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

  void onGoalReached() {
    if (onGoalReachedCallback != null) {
      onGoalReachedCallback!();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isPaused && player != null) {
      inputDirection = Vector2.zero();

      // Controles por teclado (web y escritorio)
      if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
        if (pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
            pressedKeys.contains(LogicalKeyboardKey.keyW)) {
          inputDirection.y -= 1;
        }
        if (pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
            pressedKeys.contains(LogicalKeyboardKey.keyS)) {
          inputDirection.y += 1;
        }
        if (pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
            pressedKeys.contains(LogicalKeyboardKey.keyA)) {
          inputDirection.x -= 1;
        }
        if (pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
            pressedKeys.contains(LogicalKeyboardKey.keyD)) {
          inputDirection.x += 1;
        }
      }

      // Controles por acelerómetro (móviles)
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) && useAccelerometer) {
        if (_accelInput.length > 0.3) { // Umbral para evitar deriva
          inputDirection = _accelInput.normalized() * accelSensitivity;
        }
      }

      if (inputDirection.length > 1) {
        inputDirection = inputDirection.normalized();
      }

      player!.applyInput(inputDirection, dt);
    }
  }
}