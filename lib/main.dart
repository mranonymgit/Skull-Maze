import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'screens/login_screen.dart';
import 'screens/level_selector.dart';
import 'screens/character_customization.dart';
import 'screens/rankings.dart';
import 'screens/settings.dart';
import 'screens/game_screen.dart';
import 'providers/game_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Proveedor global para el AudioPlayer de ambient.mp3
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final audioPlayer = AudioPlayer();
  audioPlayer.play(AssetSource('audio/ambient.mp3'), volume: 0.5, mode: PlayerMode.mediaPlayer);
  audioPlayer.setReleaseMode(ReleaseMode.loop);
  ref.onDispose(() {
    audioPlayer.stop();
    audioPlayer.dispose();
  });
  return audioPlayer;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  MyApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
      GoRoute(path: '/levels', builder: (context, state) => LevelSelector()),
      GoRoute(path: '/character-customization', builder: (context, state) => CharacterCustomization()),
      GoRoute(path: '/rankings', builder: (context, state) => Rankings()),
      GoRoute(path: '/settings', builder: (context, state) => Settings()),
      GoRoute(
        path: '/game/:level',
        builder: (context, state) => GameScreen(level: state.pathParameters['level']!),
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Maze Game',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.green),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}