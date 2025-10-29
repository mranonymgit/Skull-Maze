/// Modelo de Nivel
/// Representa un nivel del juego con su configuración y estado
class LevelModel {
  final int levelNumber;
  final int gridSize;
  final int difficulty; // 1-5
  final bool isCompleted;
  final bool isUnlocked;
  final int bestScore;
  final int bestTime; // en segundos
  final DateTime? completedAt;
  final int attempts;

  LevelModel({
    required this.levelNumber,
    required this.gridSize,
    this.difficulty = 1,
    this.isCompleted = false,
    this.isUnlocked = false,
    this.bestScore = 0,
    this.bestTime = 0,
    this.completedAt,
    this.attempts = 0,
  });

  /// Calcula el tamaño de grid basado en el nivel
  static int calculateGridSize(int level) {
    if (level <= 5) return 15;
    if (level <= 10) return 20;
    if (level <= 20) return 25;
    return 30;
  }

  /// Calcula la dificultad basada en el nivel
  static int calculateDifficulty(int level) {
    if (level <= 5) return 1;
    if (level <= 10) return 2;
    if (level <= 20) return 3;
    if (level <= 50) return 4;
    return 5;
  }

  /// Crea un nivel desde Firebase
  factory LevelModel.fromMap(Map<String, dynamic> map, int levelNumber) {
    return LevelModel(
      levelNumber: levelNumber,
      gridSize: map['gridSize'] ?? calculateGridSize(levelNumber),
      difficulty: map['difficulty'] ?? calculateDifficulty(levelNumber),
      isCompleted: map['isCompleted'] ?? false,
      isUnlocked: map['isUnlocked'] ?? false,
      bestScore: map['bestScore'] ?? 0,
      bestTime: map['bestTime'] ?? 0,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      attempts: map['attempts'] ?? 0,
    );
  }

  /// Convierte a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'levelNumber': levelNumber,
      'gridSize': gridSize,
      'difficulty': difficulty,
      'isCompleted': isCompleted,
      'isUnlocked': isUnlocked,
      'bestScore': bestScore,
      'bestTime': bestTime,
      'completedAt': completedAt?.toIso8601String(),
      'attempts': attempts,
    };
  }

  /// Copia con cambios
  LevelModel copyWith({
    int? levelNumber,
    int? gridSize,
    int? difficulty,
    bool? isCompleted,
    bool? isUnlocked,
    int? bestScore,
    int? bestTime,
    DateTime? completedAt,
    int? attempts,
  }) {
    return LevelModel(
      levelNumber: levelNumber ?? this.levelNumber,
      gridSize: gridSize ?? this.gridSize,
      difficulty: difficulty ?? this.difficulty,
      isCompleted: isCompleted ?? this.isCompleted,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      bestScore: bestScore ?? this.bestScore,
      bestTime: bestTime ?? this.bestTime,
      completedAt: completedAt ?? this.completedAt,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  String toString() {
    return 'LevelModel(level: $levelNumber, gridSize: $gridSize, difficulty: $difficulty, completed: $isCompleted)';
  }
}