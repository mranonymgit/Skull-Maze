/// Modelo de Usuario
/// Representa los datos del jugador en el sistema
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLogin;

  // Progreso del juego
  final int currentLevel;
  final int maxLevelUnlocked;
  final int totalScore;
  final int gamesPlayed;
  final int gamesCompleted;

  // Personalización
  final int selectedCharacter; // 1-4
  final Map<String, dynamic> uiCustomization;

  // Configuraciones
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final bool accelerometerEnabled;
  final double volumeLevel;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLogin,
    this.currentLevel = 1,
    this.maxLevelUnlocked = 1,
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.gamesCompleted = 0,
    this.selectedCharacter = 1,
    this.uiCustomization = const {},
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.notificationsEnabled = false,
    this.accelerometerEnabled = false,
    this.volumeLevel = 0.5,
  });

  /// Crea un UserModel desde un Map (Firebase)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin: DateTime.parse(map['lastLogin'] ?? DateTime.now().toIso8601String()),
      currentLevel: map['currentLevel'] ?? 1,
      maxLevelUnlocked: map['maxLevelUnlocked'] ?? 1,
      totalScore: map['totalScore'] ?? 0,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      gamesCompleted: map['gamesCompleted'] ?? 0,
      selectedCharacter: map['selectedCharacter'] ?? 1,
      uiCustomization: Map<String, dynamic>.from(map['uiCustomization'] ?? {}),
      soundEnabled: map['soundEnabled'] ?? true,
      musicEnabled: map['musicEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      notificationsEnabled: map['notificationsEnabled'] ?? false,
      accelerometerEnabled: map['accelerometerEnabled'] ?? false,
      volumeLevel: (map['volumeLevel'] ?? 0.5).toDouble(),
    );
  }

  /// Convierte el UserModel a Map para Firebase
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'currentLevel': currentLevel,
      'maxLevelUnlocked': maxLevelUnlocked,
      'totalScore': totalScore,
      'gamesPlayed': gamesPlayed,
      'gamesCompleted': gamesCompleted,
      'selectedCharacter': selectedCharacter,
      'uiCustomization': uiCustomization,
      'soundEnabled': soundEnabled,
      'musicEnabled': musicEnabled,
      'vibrationEnabled': vibrationEnabled,
      'notificationsEnabled': notificationsEnabled,
      'accelerometerEnabled': accelerometerEnabled,
      'volumeLevel': volumeLevel,
    };
  }

  /// Copia el modelo con cambios específicos
  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    int? currentLevel,
    int? maxLevelUnlocked,
    int? totalScore,
    int? gamesPlayed,
    int? gamesCompleted,
    int? selectedCharacter,
    Map<String, dynamic>? uiCustomization,
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    bool? accelerometerEnabled,
    double? volumeLevel,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      currentLevel: currentLevel ?? this.currentLevel,
      maxLevelUnlocked: maxLevelUnlocked ?? this.maxLevelUnlocked,
      totalScore: totalScore ?? this.totalScore,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesCompleted: gamesCompleted ?? this.gamesCompleted,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      uiCustomization: uiCustomization ?? this.uiCustomization,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      accelerometerEnabled: accelerometerEnabled ?? this.accelerometerEnabled,
      volumeLevel: volumeLevel ?? this.volumeLevel,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, level: $currentLevel)';
  }
}