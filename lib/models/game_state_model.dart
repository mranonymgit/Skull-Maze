import 'maze_model.dart';
import 'player_model.dart';

/// Estado completo del juego
/// Permite guardar y restaurar el progreso si el jugador sale
class GameStateModel {
  final String userId;
  final int currentLevel;
  final MazeModel maze;
  final PlayerModel player;
  final int currentScore;
  final int elapsedTime; // en segundos
  final bool isPaused;
  final DateTime lastSaved;
  final GameStatus status;

  GameStateModel({
    required this.userId,
    required this.currentLevel,
    required this.maze,
    required this.player,
    this.currentScore = 0,
    this.elapsedTime = 0,
    this.isPaused = false,
    required this.lastSaved,
    this.status = GameStatus.playing,
  });

  /// Crea un nuevo estado de juego
  factory GameStateModel.newGame({
    required String userId,
    required int level,
    required int gridSize,
    int selectedCharacter = 1,
  }) {
    return GameStateModel(
      userId: userId,
      currentLevel: level,
      maze: MazeModel.generate(gridSize: gridSize),
      player: PlayerModel.initial(selectedCharacter: selectedCharacter),
      lastSaved: DateTime.now(),
      status: GameStatus.playing,
    );
  }

  /// Crea desde Map (para cargar estado guardado)
  factory GameStateModel.fromMap(Map<String, dynamic> map) {
    return GameStateModel(
      userId: map['userId'] ?? '',
      currentLevel: map['currentLevel'] ?? 1,
      maze: MazeModel.fromMap(map['maze']),
      player: PlayerModel.fromMap(map['player']),
      currentScore: map['currentScore'] ?? 0,
      elapsedTime: map['elapsedTime'] ?? 0,
      isPaused: map['isPaused'] ?? false,
      lastSaved: DateTime.parse(map['lastSaved'] ?? DateTime.now().toIso8601String()),
      status: GameStatus.values.firstWhere(
            (s) => s.toString() == map['status'],
        orElse: () => GameStatus.playing,
      ),
    );
  }

  /// Convierte a Map para guardar en Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentLevel': currentLevel,
      'maze': maze.toMap(),
      'player': player.toMap(),
      'currentScore': currentScore,
      'elapsedTime': elapsedTime,
      'isPaused': isPaused,
      'lastSaved': lastSaved.toIso8601String(),
      'status': status.toString(),
    };
  }

  /// Copia con cambios
  GameStateModel copyWith({
    String? userId,
    int? currentLevel,
    MazeModel? maze,
    PlayerModel? player,
    int? currentScore,
    int? elapsedTime,
    bool? isPaused,
    DateTime? lastSaved,
    GameStatus? status,
  }) {
    return GameStateModel(
      userId: userId ?? this.userId,
      currentLevel: currentLevel ?? this.currentLevel,
      maze: maze ?? this.maze,
      player: player ?? this.player,
      currentScore: currentScore ?? this.currentScore,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      isPaused: isPaused ?? this.isPaused,
      lastSaved: lastSaved ?? this.lastSaved,
      status: status ?? this.status,
    );
  }

  /// Verifica si el jugador alcanzó la meta
  bool hasReachedGoal() {
    return player.isAtPosition(maze.goalPosition.x, maze.goalPosition.y);
  }

  /// Calcula la puntuación actual
  int calculateCurrentScore() {
    return currentLevel * 100 + (600 - elapsedTime).clamp(0, 500);
  }

  @override
  String toString() {
    return 'GameStateModel(level: $currentLevel, score: $currentScore, status: $status)';
  }
}

/// Estados posibles del juego
enum GameStatus {
  playing,
  paused,
  completed,
  gameOver,
}

/// Extensión para obtener texto descriptivo
extension GameStatusExtension on GameStatus {
  String get displayText {
    switch (this) {
      case GameStatus.playing:
        return 'Jugando';
      case GameStatus.paused:
        return 'Pausado';
      case GameStatus.completed:
        return 'Completado';
      case GameStatus.gameOver:
        return 'Game Over';
    }
  }
}