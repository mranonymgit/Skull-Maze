import 'package:audioplayers/audioplayers.dart';

/// Servicio de Audio
/// Maneja toda la reproducción de música y efectos de sonido
class AudioService {
  // Instancia singleton
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Reproductores de audio
  AudioPlayer? _backgroundMusicPlayer;
  AudioPlayer? _levelMusicPlayer;

  // Estado del audio
  bool _isMusicEnabled = true;
  bool _areSoundEffectsEnabled = true;
  double _volumeLevel = 0.5;

  // Estado de reproducción
  bool _isBackgroundMusicPlaying = false;
  bool _isLevelMusicPlaying = false;
  bool _wasPlayingBeforePause = false;

  // Getters
  bool get isMusicEnabled => _isMusicEnabled;
  bool get areSoundEffectsEnabled => _areSoundEffectsEnabled;
  double get volumeLevel => _volumeLevel;
  bool get isBackgroundMusicPlaying => _isBackgroundMusicPlaying;
  bool get isLevelMusicPlaying => _isLevelMusicPlaying;

  /// Inicializa el servicio de audio
  Future<void> initialize() async {
    try {
      _backgroundMusicPlayer = AudioPlayer();
      _levelMusicPlayer = AudioPlayer();

      // Configurar listeners para saber cuándo termina una canción
      _backgroundMusicPlayer?.onPlayerStateChanged.listen((state) {
        _isBackgroundMusicPlaying = state == PlayerState.playing;
      });

      _levelMusicPlayer?.onPlayerStateChanged.listen((state) {
        _isLevelMusicPlaying = state == PlayerState.playing;
      });

      print('✅ Audio Service inicializado');
    } catch (e) {
      print('⚠️ Error al inicializar Audio Service: $e');
    }
  }

  // ==================== MÚSICA DE FONDO ====================

  /// Reproduce la música de ambiente (menú principal)
  Future<void> playBackgroundMusic() async {
    try {
      if (!_isMusicEnabled) {
        print('⚠️ Música deshabilitada');
        return;
      }

      // Si ya está reproduciendo, no hacer nada
      if (_isBackgroundMusicPlaying) {
        print('ℹ️ Música de fondo ya está reproduciendo');
        return;
      }

      await _backgroundMusicPlayer?.stop();
      await _backgroundMusicPlayer?.setReleaseMode(ReleaseMode.loop);
      await _backgroundMusicPlayer?.play(
        AssetSource('audio/ambient.mp3'),
        volume: _volumeLevel,
      );
      _isBackgroundMusicPlaying = true;
      print('🎵 Música de fondo reproduciendo');
    } catch (e) {
      print('❌ Error al reproducir música de fondo: $e');
    }
  }

  /// Pausa la música de fondo
  Future<void> pauseBackgroundMusic() async {
    try {
      if (_isBackgroundMusicPlaying) {
        await _backgroundMusicPlayer?.pause();
        _isBackgroundMusicPlaying = false;
        print('⏸️ Música de fondo pausada');
      }
    } catch (e) {
      print('❌ Error al pausar música de fondo: $e');
    }
  }

  /// Reanuda la música de fondo
  Future<void> resumeBackgroundMusic() async {
    try {
      if (!_isMusicEnabled) return;

      if (!_isBackgroundMusicPlaying) {
        await _backgroundMusicPlayer?.resume();
        _isBackgroundMusicPlaying = true;
        print('▶️ Música de fondo reanudada');
      }
    } catch (e) {
      print('❌ Error al reanudar música de fondo: $e');
    }
  }

  /// Detiene la música de fondo
  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundMusicPlayer?.stop();
      _isBackgroundMusicPlaying = false;
      print('⏹️ Música de fondo detenida');
    } catch (e) {
      print('❌ Error al detener música de fondo: $e');
    }
  }

  // ==================== MÚSICA DE NIVEL ====================

  /// Reproduce la música del nivel (durante el juego)
  Future<void> playLevelMusic() async {
    try {
      if (!_isMusicEnabled) return;

      // Pausar música de fondo
      await pauseBackgroundMusic();

      // Reproducir música de nivel
      await _levelMusicPlayer?.stop();
      await _levelMusicPlayer?.setReleaseMode(ReleaseMode.loop);
      await _levelMusicPlayer?.play(
        AssetSource('audio/level.mp3'),
        volume: _volumeLevel,
      );
      _isLevelMusicPlaying = true;
      print('🎵 Música de nivel reproduciendo');
    } catch (e) {
      print('❌ Error al reproducir música de nivel: $e');
    }
  }

  /// Pausa la música del nivel
  Future<void> pauseLevelMusic() async {
    try {
      if (_isLevelMusicPlaying) {
        await _levelMusicPlayer?.pause();
        _isLevelMusicPlaying = false;
        print('⏸️ Música de nivel pausada');
      }
    } catch (e) {
      print('❌ Error al pausar música de nivel: $e');
    }
  }

  /// Reanuda la música del nivel
  Future<void> resumeLevelMusic() async {
    try {
      if (!_isMusicEnabled) return;

      if (!_isLevelMusicPlaying) {
        await _levelMusicPlayer?.resume();
        _isLevelMusicPlaying = true;
        print('▶️ Música de nivel reanudada');
      }
    } catch (e) {
      print('❌ Error al reanudar música de nivel: $e');
    }
  }

  /// Detiene la música del nivel y reanuda la de fondo
  Future<void> stopLevelMusic() async {
    try {
      await _levelMusicPlayer?.stop();
      _isLevelMusicPlaying = false;

      // Reanudar música de fondo
      await playBackgroundMusic();
      print('⏹️ Música de nivel detenida, música de fondo reanudada');
    } catch (e) {
      print('❌ Error al detener música de nivel: $e');
    }
  }

  // ==================== EFECTOS DE SONIDO ====================

  /// Reproduce un efecto de sonido (NO PAUSA LA MÚSICA)
  Future<void> playSoundEffect(SoundEffect effect) async {
    try {
      if (!_areSoundEffectsEnabled) return;

      // Crear un nuevo AudioPlayer para cada efecto (se reproduce independientemente)
      final effectPlayer = AudioPlayer();
      await effectPlayer.play(
        AssetSource(effect.path),
        volume: _volumeLevel * 0.8,
      );

      // Limpiar el reproductor después de terminar
      effectPlayer.onPlayerComplete.listen((_) {
        effectPlayer.dispose();
      });

      // NO hacer print para efectos (demasiado verbose)
    } catch (e) {
      // Silenciar errores de efectos para no saturar logs
    }
  }

  /// Reproduce el sonido de click
  Future<void> playClickSound() async {
    await playSoundEffect(SoundEffect.click);
  }

  /// Reproduce el sonido de selección
  Future<void> playSelectSound() async {
    await playSoundEffect(SoundEffect.selected);
  }

  /// Reproduce el sonido de toggle/switch
  Future<void> playToggleSound() async {
    await playSoundEffect(SoundEffect.toggle);
  }

  /// Reproduce el sonido de guardar
  Future<void> playSaveSound() async {
    await playSoundEffect(SoundEffect.save);
  }

  /// Reproduce el sonido del jugador
  Future<void> playPlayerSound() async {
    await playSoundEffect(SoundEffect.player);
  }

  /// Reproduce el sonido de victoria
  Future<void> playVictorySound() async {
    await playSoundEffect(SoundEffect.victory);
  }

  /// Reproduce el sonido de derrota
  Future<void> playDefeatSound() async {
    await playSoundEffect(SoundEffect.defeat);
  }

  /// Reproduce el sonido de éxito en sublaberinto
  Future<void> playSuccessSound() async {
    await playSoundEffect(SoundEffect.click); // o crea un nuevo asset: 'audio/success.mp3'
  }

  // ==================== CONFIGURACIÓN ====================

  /// Habilita/deshabilita la música
  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;

    if (enabled) {
      // Reanudar la música que estaba sonando
      if (_isLevelMusicPlaying || _wasPlayingBeforePause) {
        await resumeLevelMusic();
      } else {
        await resumeBackgroundMusic();
      }
    } else {
      // Guardar estado antes de pausar
      _wasPlayingBeforePause = _isBackgroundMusicPlaying || _isLevelMusicPlaying;
      await pauseBackgroundMusic();
      await pauseLevelMusic();
    }

    print('🎵 Música ${enabled ? 'habilitada' : 'deshabilitada'}');
  }

  /// Habilita/deshabilita los efectos de sonido
  void setSoundEffectsEnabled(bool enabled) {
    _areSoundEffectsEnabled = enabled;
    print('🔊 Efectos de sonido ${enabled ? 'habilitados' : 'deshabilitados'}');
  }

  /// Ajusta el volumen general
  Future<void> setVolume(double volume) async {
    _volumeLevel = volume.clamp(0.0, 1.0);

    await _backgroundMusicPlayer?.setVolume(_volumeLevel);
    await _levelMusicPlayer?.setVolume(_volumeLevel);

    print('🔊 Volumen ajustado: ${(_volumeLevel * 100).toInt()}%');
  }

  /// Aplica configuraciones de audio desde UserModel
  Future<void> applySettings({
    required bool musicEnabled,
    required bool soundEffectsEnabled,
    required double volume,
  }) async {
    _isMusicEnabled = musicEnabled;
    _areSoundEffectsEnabled = soundEffectsEnabled;
    await setVolume(volume);

    if (!musicEnabled) {
      await pauseBackgroundMusic();
      await pauseLevelMusic();
    }

    print('✅ Configuraciones de audio aplicadas');
  }

  // ==================== CICLO DE VIDA ====================

  /// Llamar cuando la app pasa a background
  Future<void> onAppPaused() async {
    print('📱 App pausada - pausando música');
    _wasPlayingBeforePause = _isBackgroundMusicPlaying || _isLevelMusicPlaying;

    await pauseBackgroundMusic();
    await pauseLevelMusic();
  }

  /// Llamar cuando la app vuelve a foreground
  Future<void> onAppResumed() async {
    print('📱 App reanudada - reanudando música');

    if (!_isMusicEnabled) return;

    if (_wasPlayingBeforePause) {
      if (_isLevelMusicPlaying) {
        await resumeLevelMusic();
      } else {
        await resumeBackgroundMusic();
      }
      _wasPlayingBeforePause = false;
    }
  }

  // ==================== LIMPIEZA ====================

  /// Libera todos los recursos de audio
  Future<void> dispose() async {
    try {
      await _backgroundMusicPlayer?.stop();
      await _backgroundMusicPlayer?.dispose();

      await _levelMusicPlayer?.stop();
      await _levelMusicPlayer?.dispose();

      print('✅ Audio Service cerrado');
    } catch (e) {
      print('❌ Error al cerrar Audio Service: $e');
    }
  }
}

/// Enum de efectos de sonido disponibles
enum SoundEffect {
  click('audio/click.mp3'),
  selected('audio/selected.mp3'),
  toggle('audio/toggle.mp3'),
  save('audio/save.mp3'),
  player('audio/player.mp3'),
  victory('audio/victory.mp3'),
  defeat('audio/defeat.mp3');

  final String path;
  const SoundEffect(this.path);
}