import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/score_model.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';

/// Controller del Ranking
/// Maneja la obtención y visualización del ranking global
class RankingController extends StateNotifier<RankingState> {
  final DatabaseService _databaseService;
  final AudioService _audioService;

  RankingController({
    required DatabaseService databaseService,
    required AudioService audioService,
  })  : _databaseService = databaseService,
        _audioService = audioService,
        super(RankingState.initial());

  /// Carga el ranking global (top scores)
  Future<void> loadTopScores({int limit = 100}) async {
    try {
      state = RankingState.loading();

      final scores = await _databaseService.getTopScores(limit: limit);

      state = RankingState.loaded(scores);
      print('✅ Ranking cargado: ${scores.length} registros');
    } catch (e) {
      state = RankingState.error(e.toString());
      print('❌ Error al cargar ranking: $e');
    }
  }

  /// Carga las puntuaciones de un usuario específico
  Future<void> loadUserScores(String userId) async {
    try {
      state = RankingState.loading();

      final scores = await _databaseService.getUserScores(userId);

      state = RankingState.loaded(scores);
      print('✅ Puntuaciones del usuario cargadas: ${scores.length} registros');
    } catch (e) {
      state = RankingState.error(e.toString());
      print('❌ Error al cargar puntuaciones del usuario: $e');
    }
  }

  /// Reproduce sonido al seleccionar un jugador
  Future<void> onPlayerSelected() async {
    await _audioService.playPlayerSound();
  }

  /// Actualiza el ranking (refresca los datos)
  Future<void> refreshRanking() async {
    await loadTopScores();
  }

  /// Obtiene la posición de un usuario en el ranking
  int? getUserRank(String userId) {
    if (state.scores.isEmpty) return null;

    final userScores = state.scores.where((s) => s.userId == userId);
    if (userScores.isEmpty) return null;

    final bestScore = userScores.reduce((a, b) => a.score > b.score ? a : b);
    return bestScore.rank;
  }

  /// Obtiene el mejor score de un usuario
  ScoreModel? getUserBestScore(String userId) {
    if (state.scores.isEmpty) return null;

    final userScores = state.scores.where((s) => s.userId == userId);
    if (userScores.isEmpty) return null;

    return userScores.reduce((a, b) => a.score > b.score ? a : b);
  }

  /// Filtra el ranking por nivel
  List<ScoreModel> getScoresByLevel(int level) {
    return state.scores.where((s) => s.level == level).toList();
  }

  /// Obtiene los top N jugadores
  List<ScoreModel> getTopPlayers(int n) {
    return state.scores.take(n).toList();
  }
}

/// Estado del RankingController
class RankingState {
  final List<ScoreModel> scores;
  final bool isLoading;
  final String? errorMessage;

  RankingState({
    this.scores = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasScores => scores.isNotEmpty;
  bool get hasError => errorMessage != null;

  factory RankingState.initial() {
    return RankingState();
  }

  factory RankingState.loading() {
    return RankingState(isLoading: true);
  }

  factory RankingState.loaded(List<ScoreModel> scores) {
    return RankingState(scores: scores);
  }

  factory RankingState.error(String message) {
    return RankingState(errorMessage: message);
  }
}

/// Provider del RankingController
final rankingControllerProvider = StateNotifierProvider<RankingController, RankingState>((ref) {
  return RankingController(
    databaseService: DatabaseService(),
    audioService: AudioService(),
  );
});

/// Provider para el stream del ranking en tiempo real (opcional)
final rankingStreamProvider = StreamProvider<List<ScoreModel>>((ref) {
  return DatabaseService().topScoresStream(limit: 100);
});