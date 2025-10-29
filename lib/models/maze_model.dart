import 'dart:math';

/// Modelo del Laberinto
/// Representa la estructura del laberinto generado
class MazeModel {
  final int gridSize;
  final List<List<int>> grid; // 0 = camino, 1 = pared
  final MazePosition startPosition;
  final MazePosition goalPosition;
  final DateTime generatedAt;
  final int seed; // Semilla para regenerar el mismo laberinto

  MazeModel({
    required this.gridSize,
    required this.grid,
    required this.startPosition,
    required this.goalPosition,
    required this.generatedAt,
    required this.seed,
  });

  /// Genera un nuevo laberinto aleatorio
  factory MazeModel.generate({
    required int gridSize,
    int? seed,
  }) {
    final Random rnd = seed != null ? Random(seed) : Random();
    final int actualSeed = seed ?? DateTime.now().millisecondsSinceEpoch;

    // Inicializar grid con paredes
    List<List<int>> grid = List.generate(
      gridSize,
          (_) => List.filled(gridSize, 1),
    );

    // Algoritmo de generación de laberinto (Recursive Backtracking)
    List<MazePosition> stack = [MazePosition(1, 1)];
    grid[1][1] = 0;

    while (stack.isNotEmpty) {
      var current = stack.last;
      int x = current.x;
      int y = current.y;

      List<List<int>> directions = [
        [2, 0],  // Derecha
        [-2, 0], // Izquierda
        [0, 2],  // Abajo
        [0, -2], // Arriba
      ];
      directions.shuffle(rnd);

      bool moved = false;
      for (var dir in directions) {
        int nx = x + dir[0];
        int ny = y + dir[1];

        if (nx > 0 && nx < gridSize - 1 &&
            ny > 0 && ny < gridSize - 1 &&
            grid[ny][nx] == 1) {
          grid[ny][nx] = 0;
          grid[y + dir[1] ~/ 2][x + dir[0] ~/ 2] = 0;
          stack.add(MazePosition(nx, ny));
          moved = true;
          break;
        }
      }
      if (!moved) {
        stack.removeLast();
      }
    }

    // Asegurar camino desde inicio hasta meta
    int endX = gridSize - 2;
    int endY = gridSize - 2;
    grid[endY][endX] = 0;

    // Crear camino garantizado (por si acaso)
    int cx = 1, cy = 1;
    while (cx != endX || cy != endY) {
      grid[cy][cx] = 0;
      if (cx < endX && rnd.nextBool()) {
        cx++;
      } else if (cy < endY) {
        cy++;
      } else if (cx < endX) {
        cx++;
      }
      if (cx >= gridSize - 1) cx = gridSize - 2;
      if (cy >= gridSize - 1) cy = gridSize - 2;
    }
    grid[endY][endX] = 0;

    // Limpiar entrada y salida
    grid[0][0] = 0;
    grid[0][1] = 0;
    grid[1][0] = 0;

    return MazeModel(
      gridSize: gridSize,
      grid: grid,
      startPosition: MazePosition(0, 0),
      goalPosition: MazePosition(endX, endY),
      generatedAt: DateTime.now(),
      seed: actualSeed,
    );
  }

  /// Verifica si una posición es válida (es camino)
  bool isValidPosition(int x, int y) {
    if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) {
      return false;
    }
    return grid[y][x] == 0;
  }

  /// Obtiene las posiciones vecinas válidas
  List<MazePosition> getNeighbors(MazePosition position) {
    List<MazePosition> neighbors = [];
    final directions = [
      [0, -1], // Arriba
      [0, 1],  // Abajo
      [-1, 0], // Izquierda
      [1, 0],  // Derecha
    ];

    for (var dir in directions) {
      int nx = position.x + dir[0];
      int ny = position.y + dir[1];
      if (isValidPosition(nx, ny)) {
        neighbors.add(MazePosition(nx, ny));
      }
    }

    return neighbors;
  }

  /// Crea desde Map (para guardar/cargar estado)
  factory MazeModel.fromMap(Map<String, dynamic> map) {
    return MazeModel(
      gridSize: map['gridSize'] ?? 15,
      grid: (map['grid'] as List).map((row) => List<int>.from(row)).toList(),
      startPosition: MazePosition.fromMap(map['startPosition']),
      goalPosition: MazePosition.fromMap(map['goalPosition']),
      generatedAt: DateTime.parse(map['generatedAt'] ?? DateTime.now().toIso8601String()),
      seed: map['seed'] ?? 0,
    );
  }

  /// Convierte a Map para guardar
  Map<String, dynamic> toMap() {
    return {
      'gridSize': gridSize,
      'grid': grid,
      'startPosition': startPosition.toMap(),
      'goalPosition': goalPosition.toMap(),
      'generatedAt': generatedAt.toIso8601String(),
      'seed': seed,
    };
  }

  @override
  String toString() {
    return 'MazeModel(gridSize: $gridSize, seed: $seed)';
  }
}

/// Posición en el laberinto
class MazePosition {
  final int x;
  final int y;

  MazePosition(this.x, this.y);

  factory MazePosition.fromMap(Map<String, dynamic> map) {
    return MazePosition(map['x'] ?? 0, map['y'] ?? 0);
  }

  Map<String, dynamic> toMap() {
    return {'x': x, 'y': y};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MazePosition && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'MazePosition($x, $y)';
}