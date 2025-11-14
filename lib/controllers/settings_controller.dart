import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/audio_service.dart';
import 'auth_controller.dart';
import '../screens/character_customization.dart';

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

  Future<void> _loadUserSettings() async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      // Buscamos la imagen del personaje guardado
      final selectedChar = characters.firstWhere(
            (c) => c.id == user.selectedCharacter,
        orElse: () => characters.first,
      );

      state = SettingsState(
        musicEnabled: user.musicEnabled,
        soundEffectsEnabled: user.soundEnabled,
        vibrationEnabled: user.vibrationEnabled,
        notificationsEnabled: user.notificationsEnabled,
        accelerometerEnabled: user.accelerometerEnabled,  // ✅ CAMBIADO
        volumeLevel: user.volumeLevel,
        selectedCharacter: user.selectedCharacter,
        selectedCharacterImage: selectedChar.imagePath,
      );
    } catch (e) {
      print('Error al cargar configuraciones: $e');
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

  /// Habilita/deshabilita el ACELERÓMETRO ✅
  Future<void> toggleAccelerometer(bool enabled) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(accelerometerEnabled: enabled);

      await _databaseService.updateUserSettings(
        user.id,
        accelerometerEnabled: enabled,  // ✅ CAMBIADO
      );

      final updatedUser = user.copyWith(accelerometerEnabled: enabled);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      if (state.soundEffectsEnabled) {
        await _audioService.playToggleSound();
      }

      print('📱 Acelerómetro ${enabled ? 'activado' : 'desactivado'}');  // ✅ CAMBIADO
    } catch (e) {
      print('❌ Error al cambiar acelerómetro: $e');
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

      final updatedUser = user.copyWith(volumeLevel: clampedVolume);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      print('🔊 Volumen ajustado: ${(clampedVolume * 100).toInt()}%');
    } catch (e) {
      print('❌ Error al ajustar volumen: $e');
    }
  }

  /// Selecciona un personaje y guarda su imagen
  Future<void> selectCharacter(int characterId) async {
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      state = state.copyWith(selectedCharacter: characterId);

      final selectedChar = characters.firstWhere(
            (c) => c.id == characterId,
        orElse: () => characters.first,
      );
      state = state.copyWith(selectedCharacterImage: selectedChar.imagePath);

      await _databaseService.updateSelectedCharacter(user.id, characterId);

      final updatedUser = user.copyWith(selectedCharacter: characterId);
      _ref.read(authControllerProvider.notifier).updateUser(updatedUser);

      if (state.soundEffectsEnabled) {
        await _audioService.playSelectSound();
      }

      print('Personaje ${selectedChar.name} seleccionado (ID: $characterId)');
    } catch (e) {
      print('Error al seleccionar personaje: $e');
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
        accelerometerEnabled: state.accelerometerEnabled,  // ✅ CAMBIADO
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
        accelerometerEnabled: false,  // ✅ CAMBIADO
        volumeLevel: 0.5,
      );

      await _audioService.applySettings(
        musicEnabled: true,
        soundEffectsEnabled: true,
        volume: 0.5,
      );

      final updatedUser = user.copyWith(
        musicEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        notificationsEnabled: false,
        accelerometerEnabled: false,  // ✅ CAMBIADO
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
  final bool accelerometerEnabled;  // ✅ CAMBIADO
  final double volumeLevel;
  final int selectedCharacter;
  final String selectedCharacterImage;

  SettingsState({
    this.musicEnabled = true,
    this.soundEffectsEnabled = true,
    this.vibrationEnabled = true,
    this.notificationsEnabled = false,
    this.accelerometerEnabled = false,  // ✅ CAMBIADO
    this.volumeLevel = 0.5,
    this.selectedCharacter = 1,
    this.selectedCharacterImage = 'assets/images/Snoopy.png',
  });

  factory SettingsState.initial() {
    return SettingsState();
  }

  SettingsState copyWith({
    bool? musicEnabled,
    bool? soundEffectsEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    bool? accelerometerEnabled,  // ✅ CAMBIADO
    double? volumeLevel,
    int? selectedCharacter,
    String? selectedCharacterImage,
  }) {
    return SettingsState(
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      accelerometerEnabled: accelerometerEnabled ?? this.accelerometerEnabled,  // ✅ CAMBIADO
      volumeLevel: volumeLevel ?? this.volumeLevel,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      selectedCharacterImage: selectedCharacterImage ?? this.selectedCharacterImage,
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