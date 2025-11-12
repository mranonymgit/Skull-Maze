import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/ranking_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/user_model.dart';

// ==================== SERVICIOS ====================

/// Provider del servicio de Firebase
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// Provider del servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider del servicio de base de datos
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provider del servicio de audio
final audioServiceProvider = Provider<AudioService>((ref) {
  final audioService = AudioService();

  // Inicializar audio service de forma segura
  audioService.initialize().then((_) {
    // NO reproducir música automáticamente
    // El usuario debe interactuar primero (hacer clic en login)
    print('✅ Audio Service listo (música en espera de interacción del usuario)');
  }).catchError((e) {
    print('⚠️ No se pudo inicializar audio service: $e');
  });

  // Limpiar al destruir
  ref.onDispose(() {
    audioService.dispose();
  });

  return audioService;
});

// ==================== CONTROLLERS ====================
// Los providers de controllers ya están definidos en sus respectivos archivos

// ==================== PROVIDERS DE ESTADO ====================

/// Provider que verifica si el usuario está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isAuthenticated;
});

/// Provider del ID del usuario actual
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});

/// Provider del nivel actual del usuario
final currentLevelProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.currentLevel ?? 1;
});

/// Provider del personaje seleccionado
final selectedCharacterProvider = Provider<int>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return settings.selectedCharacter;
});

/// Provider del máximo nivel desbloqueado
final maxLevelUnlockedProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.maxLevelUnlocked ?? 1;
});

// ==================== PROVIDERS DE CONFIGURACIÓN ====================

/// Provider de música habilitada
final musicEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return settings.musicEnabled;
});

/// Provider de efectos de sonido habilitados
final soundEffectsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return settings.soundEffectsEnabled;
});

/// Provider de vibración habilitada
final vibrationEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return settings.vibrationEnabled;
});

/// Provider de giroscopio habilitado
final gyroscopeEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return settings.gyroscopeEnabled;
});

/// Provider del nivel de volumen
final volumeLevelProvider = Provider<double>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  return settings.volumeLevel;
});

// ==================== PROVIDERS DE JUEGO ====================

/// Provider del estado del juego actual
final currentGameStateProvider = Provider((ref) {
  final gameState = ref.watch(gameControllerProvider);
  return gameState.gameState;
});

/// Provider que indica si hay un juego en curso
final isPlayingProvider = Provider<bool>((ref) {
  final gameState = ref.watch(gameControllerProvider);
  return gameState.isPlaying;
});

/// Provider que indica si el juego está pausado
final isPausedProvider = Provider<bool>((ref) {
  final gameState = ref.watch(gameControllerProvider);
  return gameState.isPaused;
});

// Provider para obtener fácilmente la imagen del personaje seleccionado
final selectedCharacterImageProvider = Provider<String>((ref) {
  return ref.watch(settingsControllerProvider).selectedCharacterImage;
});

// ==================== PROVIDERS DE RANKING ====================

/// Provider de las mejores puntuaciones
final topScoresProvider = Provider((ref) {
  final rankingState = ref.watch(rankingControllerProvider);
  return rankingState.scores;
});

/// Provider que indica si hay puntuaciones cargadas
final hasScoresProvider = Provider<bool>((ref) {
  final rankingState = ref.watch(rankingControllerProvider);
  return rankingState.hasScores;
});

// ==================== PROVIDERS DE UI ====================

/// Provider del índice de navegación actual (para BottomNavigationBar)
final navigationIndexProvider = StateProvider<int>((ref) => 2); // Default: Levels

/// Provider del tema oscuro/claro (opcional para futuro)
final isDarkModeProvider = StateProvider<bool>((ref) => true);

// ==================== PROVIDERS DE INICIALIZACIÓN ====================

/// Provider para inicializar todos los servicios
final initializationProvider = FutureProvider<void>((ref) async {
  // Inicializar Firebase Service
  await FirebaseService.initialize();

  // Inicializar Audio Service
  final audioService = ref.read(audioServiceProvider);
  await audioService.initialize();

  print('✅ Todos los servicios inicializados');
});