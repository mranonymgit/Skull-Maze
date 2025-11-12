import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // Para haptic feedback
import '../providers/app_providers.dart';
import '../controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/ranking_controller.dart';
import '../services/audio_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoutAnimationController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _logoutAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _logoutAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _logoutAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoutAnimationController,
      curve: const Interval(0.0, 0.9, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _logoutAnimationController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    // Haptic feedback
    if (ref.read(settingsControllerProvider).vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }

    await ref.read(audioServiceProvider).playClickSound();

    // Animar el botón antes del diálogo
    _logoutAnimationController.forward();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLogoutDialog(),
    );

    if (confirmed == true && context.mounted) {
      // Animación de salida suave
      await _slideController.reverse();
      await Future.delayed(const Duration(milliseconds: 150));

      await ref.read(authControllerProvider.notifier).signOut();
      context.pushReplacement('/login'); // Más suave que .go()
    } else {
      // Revertir animación si cancela
      _logoutAnimationController.reverse();
    }
  }

  Widget _buildLogoutDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A1B3D).withOpacity(0.95),
              const Color(0xFF1C1C1C).withOpacity(0.95),
              Colors.black.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7CFC00).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7CFC00).withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de advertencia animado
            Container(
              padding: const EdgeInsets.all(20),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) => Transform.scale(
                  scale: 1.0 + (0.1 * (value - 0.5).abs() * 2),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4500).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF4500).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF4500),
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '¿Cerrar Sesión?',
                style: GoogleFonts.pressStart2p(
                  textStyle: const TextStyle(
                    color: Color(0xFF7CFC00),
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            // Mensaje
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Text(
                '¿Estás seguro de que quieres cerrar sesión?\n\nTus ajustes se guardarán automáticamente.',
                style: GoogleFonts.openSans(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 25),
            // Botones
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFB0BEC5).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.openSans(
                            textStyle: const TextStyle(
                              color: Color(0xFFB0BEC5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4500), Color(0xFFFF6B6B)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4500).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Cerrar Sesión',
                          style: GoogleFonts.openSans(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioServiceProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A1B3D),
              const Color(0xFF1C1C1C),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // === HEADER CON PARALLAX ===
                  _buildAnimatedHeader(size),

                  // === CONTENIDO PRINCIPAL ===
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: isSmallScreen ? 10 : 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // AUDIO SETTINGS
                                _buildSectionHeader('audio', '🎵 Ajustes de Audio'),
                                const SizedBox(height: 20),

                                _buildAnimatedToggle(
                                  context,
                                  ref,
                                  'Música de fondo',
                                  Icons.music_note,
                                  settingsState.musicEnabled,
                                      () async {
                                    await ref.read(settingsControllerProvider.notifier).toggleMusic(!settingsState.musicEnabled);
                                  },
                                ),
                                const SizedBox(height: 15),

                                _buildAnimatedToggle(
                                  context,
                                  ref,
                                  'Efectos de sonido',
                                  Icons.volume_up,
                                  settingsState.soundEffectsEnabled,
                                      () async {
                                    await ref.read(settingsControllerProvider.notifier).toggleSoundEffects(!settingsState.soundEffectsEnabled);
                                  },
                                ),
                                const SizedBox(height: 20),

                                _buildAnimatedVolumeSlider(
                                  context,
                                  ref,
                                  settingsState.volumeLevel,
                                ),
                                const SizedBox(height: 35),

                                // GAME SETTINGS
                                _buildSectionHeader('game', '🎮 Ajustes de Juego'),
                                const SizedBox(height: 20),

                                _buildAnimatedToggle(
                                  context,
                                  ref,
                                  'Vibración háptica',
                                  Icons.vibration,
                                  settingsState.vibrationEnabled,
                                      () async {
                                    await ref.read(settingsControllerProvider.notifier).toggleVibration(!settingsState.vibrationEnabled);
                                  },
                                ),
                                const SizedBox(height: 15),

                                _buildAnimatedToggle(
                                  context,
                                  ref,
                                  'Notificaciones push',
                                  Icons.notifications,
                                  settingsState.notificationsEnabled,
                                      () async {
                                    await ref.read(settingsControllerProvider.notifier).toggleNotifications(!settingsState.notificationsEnabled);
                                  },
                                ),
                                const SizedBox(height: 15),

                                _buildAnimatedToggle(
                                  context,
                                  ref,
                                  'Controles por acelerómetro',
                                  Icons.screen_rotation,
                                  settingsState.gyroscopeEnabled,
                                      () async {
                                    await ref.read(settingsControllerProvider.notifier).toggleGyroscope(!settingsState.gyroscopeEnabled);
                                  },
                                ),
                                const SizedBox(height: 40),

                                // ACTION BUTTONS
                                _buildActionButtons(context, ref),
                                const SizedBox(height: 50),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // === LOGOUT BUTTON ANIMADO ===
                  _buildAnimatedLogoutButton(size, audioService),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildEnhancedBottomNav(audioService, ref),
    );
  }

  Widget _buildAnimatedHeader(Size size) {
    return Container(
      height: size.height * 0.15,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
        ),
      ),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 800),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Image.asset(
                    'assets/images/skull_logo.png',
                    height: 45,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    'CONFIGURACIÓN',
                    style: GoogleFonts.pressStart2p(
                      textStyle: TextStyle(
                        color: const Color(0xFF7CFC00),
                        fontSize: size.width > 800 ? 22 : 18,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF7CFC00).withOpacity(0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String key, String title) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: key == 'audio' ? const Color(0xFF7CFC00) : const Color(0xFFFF007F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.pressStart2p(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedToggle(
      BuildContext context,
      WidgetRef ref,
      String title,
      IconData icon,
      bool value,
      VoidCallback onChanged,
      ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? const Color(0xFF7CFC00) : Colors.transparent,
            width: value ? 1.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: (value ? const Color(0xFF7CFC00) : Colors.white).withOpacity(0.1),
              blurRadius: value ? 12 : 0,
              spreadRadius: value ? 1 : 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value ? const Color(0xFF7CFC00).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: value ? const Color(0xFF7CFC00) : const Color(0xFFB0BEC5), size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.openSans(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Transform.scale(
              scale: value ? 1.1 : 1.0,
              child: Switch(
                value: value,
                activeColor: const Color(0xFF7CFC00),
                activeTrackColor: const Color(0xFF7CFC00).withOpacity(0.3),
                inactiveThumbColor: const Color(0xFFB0BEC5),
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                onChanged: (newValue) {
                  onChanged();
                  HapticFeedback.selectionClick(); // Feedback háptico
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedVolumeSlider(
      BuildContext context,
      WidgetRef ref,
      double value,
      ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7CFC00).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.volume_up, color: const Color(0xFF7CFC00), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Volumen',
                      style: GoogleFonts.openSans(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(value * 100).toInt()}%',
                  style: GoogleFonts.openSans(
                    textStyle: TextStyle(
                      color: const Color(0xFF7CFC00),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: const Color(0xFF7CFC00),
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                thumbColor: const Color(0xFF7CFC00),
                overlayColor: const Color(0xFF7CFC00).withOpacity(0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (newValue) {
                  ref.read(settingsControllerProvider.notifier).setVolume(newValue);
                  HapticFeedback.selectionClick();
                },
                onChangeEnd: (newValue) {
                  HapticFeedback.mediumImpact();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            ref,
            'Guardar',
            Icons.save,
            const Color(0xFF7CFC00),
                () async {
              HapticFeedback.mediumImpact();
              await ref.read(settingsControllerProvider.notifier).saveSettings();
              if (context.mounted) {
                _showSuccessSnackBar('¡Ajustes guardados!');
              }
            },
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            context,
            ref,
            'Restaurar',
            Icons.refresh,
            const Color(0xFFFF007F),
                () async {
              HapticFeedback.heavyImpact();
              await ref.read(settingsControllerProvider.notifier).resetToDefault();
              if (context.mounted) {
                _showSuccessSnackBar('¡Ajustes restaurados!');
              }
            },
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      WidgetRef ref,
      String text,
      IconData icon,
      Color color,
      VoidCallback onPressed, {
        bool isOutlined = false,
      }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => GestureDetector(
        onTapDown: (_) => HapticFeedback.selectionClick(),
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isOutlined
                ? null
                : LinearGradient(
              colors: [color, color.withOpacity(0.8)],
            ),
            border: isOutlined
                ? Border.all(color: color, width: 2)
                : null,
            color: isOutlined ? Colors.transparent : null,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isOutlined ? color : Colors.black, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.pressStart2p(
                  textStyle: TextStyle(
                    color: isOutlined ? color : Colors.black,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogoutButton(Size size, AudioService audioService) {
    return AnimatedBuilder(
      animation: _logoutAnimation,
      builder: (context, child) {
        final scale = _logoutAnimation.value;
        final opacity = 1.0 - (_logoutAnimation.value * 0.3);

        return Container(
          width: size.width,
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: Transform.scale(
            scale: 1.0 + (0.1 * scale),
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4500), Color(0xFFFF6B6B)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4500).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        tween: Tween(begin: 0.0, end: scale),
                        builder: (context, bounceValue, child) => Transform.translate(
                          offset: Offset(bounceValue * 5, 0),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CERRAR SESIÓN',
                        style: GoogleFonts.pressStart2p(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedBottomNav(AudioService audioService, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C).withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF7CFC00).withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF7CFC00),
        unselectedItemColor: const Color(0xFFB0BEC5),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: 3,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Personajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            activeIcon: Icon(Icons.leaderboard),
            label: 'Ranking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Niveles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
        onTap: (index) async {
          HapticFeedback.lightImpact();
          await audioService.playClickSound();

          // Pequeña pausa para que se sienta la transición
          await Future.delayed(const Duration(milliseconds: 100));

          switch (index) {
            case 0:
              context.push('/character-customization');
              break;
            case 1:
              await ref.read(rankingControllerProvider.notifier).loadTopScores();
              context.push('/rankings');
              break;
            case 2:
              context.push('/levels');
              break;
            case 3:
              break;
          }
        },
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF7CFC00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }
}