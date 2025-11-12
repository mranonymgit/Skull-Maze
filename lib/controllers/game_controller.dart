import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state_model.dart';
import '../models/level_model.dart';
import '../models/score_model.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import 'auth_controller.dart';

/// Controller del Juego
/// Maneja toda la lógica del juego (niveles, puntuaciones, progreso)
class GameController extends StateNotifier<GameControllerState> {
  final DatabaseService _databaseService;
  final AudioService _audioService;
  final Ref _ref;

  GameController({
    required DatabaseService databaseService,
    required AudioService audioService,
    required Ref ref,
  })  : _databaseService = databaseService,
        _audioService = audioService,
        _ref = ref,
        super(GameControllerState.initial());

  /// Inicia un nuevo juego
  Future<void> startNewGame(int level) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      state = GameControllerState.loading();

      // Calcular grid size según el nivel
      final gridSize = LevelModel.calculateGridSize(level);

      // Crear nuevo estado de juego
      final gameState = GameStateModel.newGame(
        userId: user.id,
        level: level,
        gridSize: gridSize,
        selectedCharacter: user.selectedCharacter,
      );

      // Guardar estado inicial
      await _databaseService.saveGameState(gameState);

      // Reproducir música de nivel
      await _audioService.playLevelMusic();

      state = GameControllerState.playing(gameState);
      print('✅ Nuevo juego iniciado - Nivel $level');
    } catch (e) {
      state = GameControllerState.error(e.toString());
      print('❌ Error al iniciar juego: $e');
    }
  }

  /// Continúa un juego guardado
  Future<void> continueGame() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      state = GameControllerState.loading();

      final gameState = await _databaseService.getGameState(user.id);

      if (gameState == null) {
        // No hay juego guardado, iniciar nivel 1
        await startNewGame(user.currentLevel);
        return;
      }

      // Reproducir música de nivel
      await _audioService.playLevelMusic();

      state = GameControllerState.playing(gameState);
      print('✅ Juego continuado - Nivel ${gameState.currentLevel}');
    } catch (e) {
      state = GameControllerState.error(e.toString());
      print('❌ Error al continuar juego: $e');
    }
  }

  /// Actualiza el estado del juego
  Future<void> updateGameState(GameStateModel gameState) async {
    try {
      state = GameControllerState.playing(gameState);

      // Guardar automáticamente cada 10 segundos o cuando cambie nivel
      await _databaseService.saveGameState(gameState);
    } catch (e) {
      print('❌ Error al actualizar estado: $e');
    }
  }

  /// Pausa el juego
  Future<void> pauseGame() async {
    try {
      if (state.gameState == null) return;

      final pausedState = state.gameState!.copyWith(
        isPaused: true,
        lastSaved: DateTime.now(),
      );

      await _databaseService.saveGameState(pausedState);
      await _audioService.pauseLevelMusic();

      state = GameControllerState.paused(pausedState);
      print('⏸️ Juego pausado');
    } catch (e) {
      print('❌ Error al pausar juego: $e');
    }
  }

  /// Reanuda el juego
  Future<void> resumeGame() async {
    try {
      if (state.gameState == null) return;

      final resumedState = state.gameState!.copyWith(
        isPaused: false,
      );

      await _audioService.resumeLevelMusic();

      state = GameControllerState.playing(resumedState);
      print('▶️ Juego reanudado');
    } catch (e) {
      print('❌ Error al reanudar juego: $e');
    }
  }

  /// Completa el nivel actual
  Future<void> completeLevel() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null || state.gameState == null) return;

      final gameState = state.gameState!;

      // Calcular puntuación final
      final finalScore = ScoreModel.calculateScore(
        level: gameState.currentLevel,
        timeInSeconds: gameState.elapsedTime,
        gridSize: gameState.maze.gridSize,
      );

      // Crear registro de puntuación
      final score = ScoreModel(
        id: '',
        userId: user.id,
        userName: user.displayName ?? user.email,
        userPhoto: user.photoUrl,
        level: gameState.currentLevel,
        score: finalScore,
        time: gameState.elapsedTime,
        createdAt: DateTime.now(),
      );

      // Guardar puntuación
      await _databaseService.createScore(score);

      // Actualizar información del nivel
      final levelModel = LevelModel(
        levelNumber: gameState.currentLevel,
        gridSize: gameState.maze.gridSize,
        difficulty: LevelModel.calculateDifficulty(gameState.currentLevel),
        isCompleted: true,
        isUnlocked: true,
        bestScore: finalScore,
        bestTime: gameState.elapsedTime,
        completedAt: DateTime.now(),
        attempts: 1,
      );

      await _databaseService.updateUserLevel(user.id, levelModel);

      // Desbloquear siguiente nivel
      final nextLevel = gameState.currentLevel + 1;
      final nextLevelModel = LevelModel(
        levelNumber: nextLevel,
        gridSize: LevelModel.calculateGridSize(nextLevel),
        difficulty: LevelModel.calculateDifficulty(nextLevel),
        isUnlocked: true,
      );

      await _databaseService.updateUserLevel(user.id, nextLevelModel);

      // Actualizar usuario
      final updatedUser = user.copyWith(
        currentLevel: nextLevel,
        maxLevelUnlocked: nextLevel > user.maxLevelUnlocked ? nextLevel : user.maxLevelUnlocked,
        totalScore: user.totalScore + finalScore,
        gamesCompleted: user.gamesCompleted + 1,
      );

      await _databaseService.updateUser(updatedUser);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      // Reproducir sonido de victoria
      await _audioService.playVictorySound();

      // Actualizar estado
      final completedState = gameState.copyWith(
        status: GameStatus.completed,
        currentScore: finalScore,
      );

      state = GameControllerState.completed(completedState);
      print('🎉 Nivel ${gameState.currentLevel} completado - Puntuación: $finalScore');
    } catch (e) {
      print('❌ Error al completar nivel: $e');
    }
  }

  /// Pasa al siguiente nivel
  Future<void> nextLevel() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      await startNewGame(user.currentLevel);
    } catch (e) {
      print('❌ Error al pasar al siguiente nivel: $e');
    }
  }

  /// Sale del juego
  Future<void> exitGame() async {
    try {
      if (state.gameState != null) {
        await _databaseService.saveGameState(state.gameState!);
      }

      await _audioService.stopLevelMusic();
      state = GameControllerState.initial();
      print('🚪 Saliendo del juego');
    } catch (e) {
      print('❌ Error al salir del juego: $e');
    }
  }

  /// Reinicia el nivel actual
  Future<void> restartLevel() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null || state.gameState == null) return;

      await startNewGame(state.gameState!.currentLevel);
      print('🔄 Nivel reiniciado');
    } catch (e) {
      print('❌ Error al reiniciar nivel: $e');
    }
  }

  /// Obtiene el estado del juego actual
  GameStateModel? get currentGameState => state.gameState;

  /// Verifica si hay un juego en curso
  bool get isPlaying => state.isPlaying;
}

/// Estado del GameController
class GameControllerState {
  final GameStateModel? gameState;
  final bool isLoading;
  final String? errorMessage;
  final GameControllerStatus status;

  GameControllerState({
    this.gameState,
    this.isLoading = false,
    this.errorMessage,
    this.status = GameControllerStatus.idle,
  });

  bool get isPlaying => status == GameControllerStatus.playing;
  bool get isPaused => status == GameControllerStatus.paused;
  bool get isCompleted => status == GameControllerStatus.completed;
  bool get hasError => errorMessage != null;

  factory GameControllerState.initial() {
    return GameControllerState(status: GameControllerStatus.idle);
  }

  factory GameControllerState.loading() {
    return GameControllerState(
      isLoading: true,
      status: GameControllerStatus.loading,
    );
  }

  factory GameControllerState.playing(GameStateModel gameState) {
    return GameControllerState(
      gameState: gameState,
      status: GameControllerStatus.playing,
    );
  }

  factory GameControllerState.paused(GameStateModel gameState) {
    return GameControllerState(
      gameState: gameState,
      status: GameControllerStatus.paused,
    );
  }

  factory GameControllerState.completed(GameStateModel gameState) {
    return GameControllerState(
      gameState: gameState,
      status: GameControllerStatus.completed,
    );
  }

  factory GameControllerState.error(String message) {
    return GameControllerState(
      errorMessage: message,
      status: GameControllerStatus.error,
    );
  }
}

/// Estados del controller
enum GameControllerStatus {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// Provider del GameController
final gameControllerProvider = StateNotifierProvider<GameController, GameControllerState>((ref) {
  return GameController(
    databaseService: DatabaseService(),
    audioService: AudioService(),
    ref: ref,
  );
});