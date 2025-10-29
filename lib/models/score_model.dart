/// Modelo de Puntuación
/// Representa un registro de puntuación en el ranking global
class ScoreModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final int level;
  final int score;
  final int time; // en segundos
  final DateTime createdAt;
  final int rank; // Posición en el ranking (se calcula dinámicamente)

  ScoreModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.level,
    required this.score,
    required this.time,
    required this.createdAt,
    this.rank = 0,
  });

  /// Crea desde Firebase
  factory ScoreModel.fromMap(Map<String, dynamic> map, String id) {
    return ScoreModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anónimo',
      userPhoto: map['userPhoto'],
      level: map['level'] ?? 1,
      score: map['score'] ?? 0,
      time: map['time'] ?? 0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      rank: map['rank'] ?? 0,
    );
  }

  /// Convierte a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'level': level,
      'score': score,
      'time': time,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Calcula puntos basados en nivel, tiempo y dificultad
  static int calculateScore({
    required int level,
    required int timeInSeconds,
    required int gridSize,
  }) {
    // Base: 100 puntos por nivel
    int baseScore = level * 100;

    // Bonus por velocidad (menos tiempo = más puntos)
    int timeBonus = (600 - timeInSeconds).clamp(0, 500);

    // Bonus por dificultad (grid más grande = más puntos)
    int difficultyBonus = gridSize * 10;

    return baseScore + timeBonus + difficultyBonus;
  }

  /// Copia con cambios
  ScoreModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhoto,
    int? level,
    int? score,
    int? time,
    DateTime? createdAt,
    int? rank,
  }) {
    return ScoreModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      level: level ?? this.level,
      score: score ?? this.score,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      rank: rank ?? this.rank,
    );
  }

  @override
  String toString() {
    return 'ScoreModel(userName: $userName, level: $level, score: $score, rank: $rank)';
  }
}