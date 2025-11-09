import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/level_selector.dart';
import 'screens/character_customization.dart';
import 'screens/rankings.dart';
import 'screens/settings.dart';
import 'screens/game_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/register_screen.dart';

// Providers
import 'providers/app_providers.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error al inicializar Firebase: $e');
  }

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // Observar cambios en el ciclo de vida de la app
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final audioService = ref.read(audioServiceProvider);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      // App en background o inactiva
        audioService.onAppPaused();
        break;
      case AppLifecycleState.resumed:
      // App en foreground
        audioService.onAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      // App cerrada
        audioService.onAppPaused();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inicializar audio service de forma segura
    try {
      ref.read(audioServiceProvider);
      print('✅ Audio Service inicializado');
    } catch (e) {
      print('⚠️ Error al inicializar Audio Service: $e');
    }

    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuthenticated = ref.read(isAuthenticatedProvider);
        final isLoggingIn = state.matchedLocation == '/login';
        final isRegistering = state.matchedLocation == '/register';
        final isForgotPassword = state.matchedLocation == '/forgot-password';

        if (!isAuthenticated && !isLoggingIn && !isRegistering && !isForgotPassword) {
          return '/login';
        }

        if (isAuthenticated && (isLoggingIn || isRegistering)) {
          return '/levels';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/levels',
          builder: (context, state) => const LevelSelector(),
        ),
        GoRoute(
          path: '/character-customization',
          builder: (context, state) => const CharacterCustomization(),
        ),
        GoRoute(
          path: '/rankings',
          builder: (context, state) => const Rankings(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/game/:level',
          builder: (context, state) {
            final level = state.pathParameters['level']!;
            return GameScreen(level: level);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Skull Maze',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}