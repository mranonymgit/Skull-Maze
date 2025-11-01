  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../models/user_model.dart';
  import '../services/auth_service.dart';
  import '../services/database_service.dart';
  import '../services/audio_service.dart';

  /// Controller de Autenticación
  /// Maneja toda la lógica de login, registro y sesión
  class AuthController extends StateNotifier<AuthState> {
    final AuthService _authService;
    final DatabaseService _databaseService;
    final AudioService _audioService;

    AuthController({
      required AuthService authService,
      required DatabaseService databaseService,
      required AudioService audioService,
    })  : _authService = authService,
          _databaseService = databaseService,
          _audioService = audioService,
          super(AuthState.initial()) {
      _checkAuthStatus();
    }

    /// Verifica si hay un usuario autenticado al iniciar
    Future<void> _checkAuthStatus() async {
      try {
        if (_authService.isAuthenticated) {
          final userId = _authService.currentUser!.uid;
          final user = await _databaseService.getUser(userId);
          if (user != null) {
            state = AuthState.authenticated(user);
            await _audioService.applySettings(
              musicEnabled: user.musicEnabled,
              soundEffectsEnabled: user.soundEnabled,
              volume: user.volumeLevel,
            );
          }
        }
      } catch (e) {
        print('❌ Error al verificar estado de autenticación: $e');
      }
    }

    /// Registra un nuevo usuario con email y password
    Future<void> registerWithEmail({
      required String email,
      required String password,
      String? displayName,
    }) async {
      try {
        state = AuthState.loading();

        final user = await _authService.registerWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        );

        if (user != null) {
          state = AuthState.authenticated(user);
          await _audioService.playSelectSound();
        } else {
          state = AuthState.error('Error al registrar usuario');
        }
      } catch (e) {
        state = AuthState.error(e.toString());
        print('❌ Error en registro: $e');
      }
    }

    /// Inicia sesión con email y password
    Future<void> signInWithEmail({
      required String email,
      required String password,
    }) async {
      try {
        state = AuthState.loading();

        final user = await _authService.signInWithEmail(
          email: email,
          password: password,
        );

        if (user != null) {
          state = AuthState.authenticated(user);

          // Aplicar configuraciones de audio del usuario
          await _audioService.applySettings(
            musicEnabled: user.musicEnabled,
            soundEffectsEnabled: user.soundEnabled,
            volume: user.volumeLevel,
          );

          await _audioService.playSelectSound();
        } else {
          state = AuthState.error('Error al iniciar sesión');
        }
      } catch (e) {
        state = AuthState.error(e.toString());
        print('❌ Error en login: $e');
      }
    }

    /// Inicia sesión con Google (compatible con web)
    Future<void> signInWithGoogle() async {
      try {
        state = AuthState.loading();

        final user = await _authService.signInWithGoogle();

        if (user != null) {
          state = AuthState.authenticated(user);

          // Aplicar configuraciones de audio del usuario
          await _audioService.applySettings(
            musicEnabled: user.musicEnabled,
            soundEffectsEnabled: user.soundEnabled,
            volume: user.volumeLevel,
          );

          await _audioService.playSelectSound();
          print('✅ Login con Google exitoso');
        } else {
          // Usuario canceló el login
          state = AuthState.initial();
          print('⚠️ Login con Google cancelado por el usuario');
        }
      } catch (e) {
        state = AuthState.error(e.toString());
        print('❌ Error en login con Google: $e');
      }
    }

    /// Cierra sesión
    Future<void> signOut() async {
      try {
        await _authService.signOut();
        await _audioService.stopLevelMusic();
        state = AuthState.initial();
        await _audioService.playClickSound();
      } catch (e) {
        state = AuthState.error(e.toString());
        print('❌ Error al cerrar sesión: $e');
      }
    }

    /// Envía correo de recuperación de contraseña
    Future<void> sendPasswordResetEmail(String email) async {
      try {
        await _authService.sendPasswordResetEmail(email);
        await _audioService.playSaveSound();
      } catch (e) {
        print('❌ Error al enviar correo de recuperación: $e');
        rethrow;
      }
    }

    /// Actualiza los datos del usuario
    Future<void> updateUser(UserModel user) async {
      try {
        await _databaseService.updateUser(user);
        state = AuthState.authenticated(user);

        // Aplicar nuevas configuraciones de audio
        await _audioService.applySettings(
          musicEnabled: user.musicEnabled,
          soundEffectsEnabled: user.soundEnabled,
          volume: user.volumeLevel,
        );

        print('✅ Usuario actualizado');
      } catch (e) {
        print('❌ Error al actualizar usuario: $e');
        rethrow;
      }
    }

    /// Obtiene el usuario actual
    UserModel? get currentUser => state.user;

    /// Verifica si está autenticado
    bool get isAuthenticated => state.isAuthenticated;
  }

  /// Estado de Autenticación
  class AuthState {
    final UserModel? user;
    final bool isLoading;
    final String? errorMessage;

    AuthState({
      this.user,
      this.isLoading = false,
      this.errorMessage,
    });

    bool get isAuthenticated => user != null;
    bool get hasError => errorMessage != null;

    factory AuthState.initial() {
      return AuthState();
    }

    factory AuthState.loading() {
      return AuthState(isLoading: true);
    }

    factory AuthState.authenticated(UserModel user) {
      return AuthState(user: user);
    }

    factory AuthState.error(String message) {
      return AuthState(errorMessage: message);
    }
  }

  /// Provider del AuthController
  final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
    return AuthController(
      authService: AuthService(),
      databaseService: DatabaseService(),
      audioService: AudioService(),
    );
  });

  /// Provider del usuario actual (conveniente)
  final currentUserProvider = Provider<UserModel?>((ref) {
    return ref.watch(authControllerProvider).user;
  });