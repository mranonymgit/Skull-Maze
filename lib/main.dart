import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/level_selector.dart';
import 'screens/character_customization.dart';
import 'screens/rankings.dart';
import 'screens/settings.dart';
import 'screens/game_screen.dart';

// Providers
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializar servicios
    ref.watch(audioServiceProvider);

    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuthenticated = ref.read(isAuthenticatedProvider);
        final isLoggingIn = state.matchedLocation == '/login';

        // Si no está autenticado y no está en login, redirigir a login
        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }

        // Si está autenticado y está en login, redirigir a niveles
        if (isAuthenticated && isLoggingIn) {
          return '/levels';
        }

        return null; // No redirigir
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
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
          builder: (context, state) => const Settings(),
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