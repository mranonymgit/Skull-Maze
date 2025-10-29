/// Modelo del Jugador en el juego
/// Representa la posición y estado actual del jugador en el laberinto
class PlayerModel {
  final int gridX;
  final int gridY;
  final double velocityX;
  final double velocityY;
  final int selectedCharacter; // 1-4
  final bool isMoving;

  PlayerModel({
    required this.gridX,
    required this.gridY,
    this.velocityX = 0.0,
    this.velocityY = 0.0,
    this.selectedCharacter = 1,
    this.isMoving = false,
  });

  /// Crea el jugador en posición inicial
  factory PlayerModel.initial({int selectedCharacter = 1}) {
    return PlayerModel(
      gridX: 0,
      gridY: 0,
      selectedCharacter: selectedCharacter,
    );
  }

  /// Crea desde Map (para guardar/cargar estado)
  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      gridX: map['gridX'] ?? 0,
      gridY: map['gridY'] ?? 0,
      velocityX: (map['velocityX'] ?? 0.0).toDouble(),
      velocityY: (map['velocityY'] ?? 0.0).toDouble(),
      selectedCharacter: map['selectedCharacter'] ?? 1,
      isMoving: map['isMoving'] ?? false,
    );
  }

  /// Convierte a Map para guardar
  Map<String, dynamic> toMap() {
    return {
      'gridX': gridX,
      'gridY': gridY,
      'velocityX': velocityX,
      'velocityY': velocityY,
      'selectedCharacter': selectedCharacter,
      'isMoving': isMoving,
    };
  }

  /// Copia con cambios
  PlayerModel copyWith({
    int? gridX,
    int? gridY,
    double? velocityX,
    double? velocityY,
    int? selectedCharacter,
    bool? isMoving,
  }) {
    return PlayerModel(
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      isMoving: isMoving ?? this.isMoving,
    );
  }

  /// Verifica si el jugador está en una posición específica
  bool isAtPosition(int x, int y) {
    return gridX == x && gridY == y;
  }

  @override
  String toString() {
    return 'PlayerModel(position: ($gridX, $gridY), character: $selectedCharacter)';
  }
}