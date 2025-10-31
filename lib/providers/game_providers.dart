/*import 'package:flutter/material.dart'; // Añadido para Color y Colors
import 'package:riverpod/riverpod.dart';

final userProvider = StateNotifierProvider<UserNotifier, GameUser?>((ref) => UserNotifier());
final configProvider = StateNotifierProvider<ConfigNotifier, Config>((ref) => ConfigNotifier());

class GameUser {
  String? id;
  String? name;

  // Constructor opcional para inicialización
  GameUser({this.id, this.name});
}

class Config {
  bool sound = true;
  Color primary = Colors.green;

  // Constructor opcional para inicialización
  Config({this.sound = true, this.primary = Colors.green});
}

class UserNotifier extends StateNotifier<GameUser?> {
  UserNotifier() : super(null);
  void setUser(GameUser user) => state = user;
}

class ConfigNotifier extends StateNotifier<Config> {
  ConfigNotifier() : super(Config());
  void toggleSound() => state = Config(sound: !state.sound);
  void setPrimaryColor(Color color) => state = Config(primary: color);
}
*/