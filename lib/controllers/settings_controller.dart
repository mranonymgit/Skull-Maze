import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import 'auth_controller.dart';

/// Controller de Configuraciones
/// Maneja todas las configuraciones del usuario (audio, personalizaciones, etc.)
class SettingsController extends StateNotifier<SettingsState> {
  final DatabaseService _databaseService;
  final AudioService _audioService;
  final Ref _ref;

  SettingsController({
    required DatabaseService databaseService,
    required AudioService audioService,
    required Ref ref,
  })  : _databaseService = databaseService,
        _audioService = audioService,
        _ref = ref,
        super(SettingsState.initial()) {
    _loadUserSettings();
  }

  /// Carga las configuraciones del usuario
  Future<void> _loadUserSettings() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = SettingsState(
        musicEnabled: user.musicEnabled,
        soundEffectsEnabled: user.soundEnabled,
        vibrationEnabled: user.vibrationEnabled,
        notificationsEnabled: user.notificationsEnabled,
        gyroscopeEnabled: user.gyroscopeEnabled,
        volumeLevel: user.volumeLevel,
        selectedCharacter: user.selectedCharacter,
      );
    } catch (e) {
      print('❌ Error al cargar configuraciones: $e');
    }
  }

  /// Habilita/deshabilita la música
  Future<void> toggleMusic(bool enabled) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(musicEnabled: enabled);

      await _audioService.setMusicEnabled(enabled);
      await _databaseService.updateUserSettings(
        user.id,
        musicEnabled: enabled,
      );

      // Actualizar usuario en auth controller
      final updatedUser = user.copyWith(musicEnabled: enabled);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      print('🎵 Música ${enabled ? 'activada' : 'desactivada'}');
    } catch (e) {
      print('❌ Error al cambiar música: $e');
    }
  }

  /// Habilita/deshabilita los efectos de sonido
  Future<void> toggleSoundEffects(bool enabled) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(soundEffectsEnabled: enabled);

      _audioService.setSoundEffectsEnabled(enabled);
      await _databaseService.updateUserSettings(
        user.id,
        soundEnabled: enabled,
      );

      // Actualizar usuario en auth controller
      final updatedUser = user.copyWith(soundEnabled: enabled);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      if (enabled) {
        await _audioService.playToggleSound();
      }

      print('🔊 Efectos de sonido ${enabled ? 'activados' : 'desactivados'}');
    } catch (e) {
      print('❌ Error al cambiar efectos de sonido: $e');
    }
  }

  /// Habilita/deshabilita la vibración
  Future<void> toggleVibration(bool enabled) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(vibrationEnabled: enabled);

      await _databaseService.updateUserSettings(
        user.id,
        vibrationEnabled: enabled,
      );

      // Actualizar usuario en auth controller
      final updatedUser = user.copyWith(vibrationEnabled: enabled);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      if (enabled && state.soundEffectsEnabled) {
        await _audioService.playToggleSound();
      }

      print('📳 Vibración ${enabled ? 'activada' : 'desactivada'}');
    } catch (e) {
      print('❌ Error al cambiar vibración: $e');
    }
  }

  /// Habilita/deshabilita las notificaciones
  Future<void> toggleNotifications(bool enabled) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(notificationsEnabled: enabled);

      await _databaseService.updateUserSettings(
        user.id,
        notificationsEnabled: enabled,
      );

      // Actualizar usuario en auth controller
      final updatedUser = user.copyWith(notificationsEnabled: enabled);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      if (state.soundEffectsEnabled) {
        await _audioService.playToggleSound();
      }

      print('🔔 Notificaciones ${enabled ? 'activadas' : 'desactivadas'}');
    } catch (e) {
      print('❌ Error al cambiar notificaciones: $e');
    }
  }

  /// Habilita/deshabilita el giroscopio
  Future<void> toggleGyroscope(bool enabled) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(gyroscopeEnabled: enabled);

      await _databaseService.updateUserSettings(
        user.id,
        gyroscopeEnabled: enabled,
      );

      // Actualizar usuario en auth controller
      final updatedUser = user.copyWith(gyroscopeEnabled: enabled);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      if (state.soundEffectsEnabled) {
        await _audioService.playToggleSound();
      }

      print('📱 Giroscopio ${enabled ? 'activado' : 'desactivado'}');
    } catch (e) {
      print('❌ Error al cambiar giroscopio: $e');
    }
  }

  /// Ajusta el nivel de volumen
  Future<void> setVolume(double volume) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      final clampedVolume = volume.clamp(0.0, 1.0);
      state = state.copyWith(volumeLevel: clampedVolume);

      await _audioService.setVolume(clampedVolume);
      await _databaseService.updateUserSettings(
        user.id,
        volumeLevel: clampedVolume,
      );

      // Actualizar usuario en auth controller
      final updatedUser = user.copyWith(volumeLevel: clampedVolume);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      print('🔊 Volumen ajustado: ${(clampedVolume * 100).toInt()}%');
    } catch (e) {
      print('❌ Error al ajustar volumen: $e');
    }
  }

  /// Selecciona un personaje
  Future<void> selectCharacter(int character) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(selectedCharacter: character);

      await _databaseService.updateSelectedCharacter(user.id, character);

      // Actualizar usuario en auth controller
      final updatedUser = user.copyWith(selectedCharacter: character);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      if (state.soundEffectsEnabled) {
        await _audioService.playSelectSound();
      }

      print('👤 Personaje $character seleccionado');
    } catch (e) {
      print('❌ Error al seleccionar personaje: $e');
    }
  }

  /// Guarda todas las configuraciones
  Future<void> saveSettings() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      await _databaseService.updateUserSettings(
        user.id,
        musicEnabled: state.musicEnabled,
        soundEnabled: state.soundEffectsEnabled,
        vibrationEnabled: state.vibrationEnabled,
        notificationsEnabled: state.notificationsEnabled,
        gyroscopeEnabled: state.gyroscopeEnabled,
        volumeLevel: state.volumeLevel,
      );

      if (state.soundEffectsEnabled) {
        await _audioService.playSaveSound();
      }

      print('✅ Configuraciones guardadas');
    } catch (e) {
      print('❌ Error al guardar configuraciones: $e');
    }
  }

  /// Restaura configuraciones por defecto
  Future<void> resetToDefault() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = SettingsState.initial();

      await _databaseService.updateUserSettings(
        user.id,
        musicEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        notificationsEnabled: false,
        gyroscopeEnabled: false,
        volumeLevel: 0.5,
      );

      await _audioService.applySettings(
        musicEnabled: true,
        soundEffectsEnabled: true,
        volume: 0.5,
      );

      // Actualizar usuario en auth controller
      final updatedUser = user.copyWith(
        musicEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        notificationsEnabled: false,
        gyroscopeEnabled: false,
        volumeLevel: 0.5,
      );
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      await _audioService.playClickSound();

      print('🔄 Configuraciones restauradas');
    } catch (e) {
      print('❌ Error al restaurar configuraciones: $e');
    }
  }
}

/// Estado de las Configuraciones
class SettingsState {
  final bool musicEnabled;
  final bool soundEffectsEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final bool gyroscopeEnabled;
  final double volumeLevel;
  final int selectedCharacter;

  SettingsState({
    this.musicEnabled = true,
    this.soundEffectsEnabled = true,
    this.vibrationEnabled = true,
    this.notificationsEnabled = false,
    this.gyroscopeEnabled = false,
    this.volumeLevel = 0.5,
    this.selectedCharacter = 1,
  });

  factory SettingsState.initial() {
    return SettingsState();
  }

  SettingsState copyWith({
    bool? musicEnabled,
    bool? soundEffectsEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    bool? gyroscopeEnabled,
    double? volumeLevel,
    int? selectedCharacter,
  }) {
    return SettingsState(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      gyroscopeEnabled: gyroscopeEnabled ?? this.gyroscopeEnabled,
      volumeLevel: volumeLevel ?? this.volumeLevel,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
    );
  }
}

/// Provider del SettingsController
final settingsControllerProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(
    databaseService: DatabaseService(),
    audioService: AudioService(),
    ref: ref,
  );
});