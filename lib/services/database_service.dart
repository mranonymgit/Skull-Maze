import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import '../models/user_model.dart';
import '../models/score_model.dart';
import '../models/level_model.dart';
import '../models/game_state_model.dart';

/// Servicio de Base de Datos (Firestore)
/// Maneja todas las operaciones CRUD con Firestore
class DatabaseService {
  // Instancia singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  // ==================== USUARIOS ====================

  /// Crea un nuevo usuario en Firestore
  Future<void> createUser(UserModel user) async {
    try {
      print('📝 Creando usuario en Firestore: ${user.id}');
      await _firebaseService.getUserDocument(user.id).set(user.toMap());
      print('✅ Usuario creado en Firestore: ${user.id}');
    } catch (e) {
      print('❌ Error al crear usuario en Firestore: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Obtiene los datos de un usuario
  Future<UserModel?> getUser(String userId) async {
    try {
      print('🔍 Obteniendo usuario de Firestore: $userId');
      final doc = await _firebaseService.getUserDocument(userId).get();
      if (!doc.exists) {
        print('⚠️ Usuario no encontrado en Firestore: $userId');
        return null;
      }
      print('✅ Usuario obtenido de Firestore: $userId');
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, userId);
    } catch (e) {
      print('❌ Error al obtener usuario de Firestore: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Actualiza los datos de un usuario
  Future<void> updateUser(UserModel user) async {
    try {
      print('📝 Actualizando usuario en Firestore: ${user.id}');
      await _firebaseService.getUserDocument(user.id).set(
        user.toMap(),
        SetOptions(merge: true), // ⭐ Usar merge
      );
      print('✅ Usuario actualizado: ${user.id}');
    } catch (e) {
      print('❌ Error al actualizar usuario: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Actualiza el último login del usuario
  Future<void> updateLastLogin(String userId) async {
    try {
      print('📝 Actualizando último login para: $userId');
      await _firebaseService.getUserDocument(userId).set({
        'lastLogin': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true)); // ⭐ Usar merge en lugar de update
      print('✅ Último login actualizado: $userId');
    } catch (e) {
      print('❌ Error al actualizar último login: $e');
      // No lanzar error, solo log
    }
  }

  /// Elimina un usuario de Firestore
  Future<void> deleteUser(String userId) async {
    try {
      await _firebaseService.getUserDocument(userId).delete();
      print('✅ Usuario eliminado de Firestore: $userId');
    } catch (e) {
      print('❌ Error al eliminar usuario: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Stream de cambios del usuario en tiempo real
  Stream<UserModel?> userStream(String userId) {
    return _firebaseService.getUserDocument(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, userId);
    });
  }

  // ==================== PUNTUACIONES ====================

  /// Crea una nueva puntuación en el ranking
  Future<void> createScore(ScoreModel score) async {
    try {
      await _firebaseService.scoresCollection.add(score.toMap());
      print('✅ Puntuación guardada: ${score.score} pts');
    } catch (e) {
      print('❌ Error al crear puntuación: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Obtiene las mejores puntuaciones (ranking global)
  Future<List<ScoreModel>> getTopScores({int limit = 100}) async {
    try {
      final query = await _firebaseService.scoresCollection
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      List<ScoreModel> scores = [];
      int rank = 1;
      for (var doc in query.docs) {
        final score = ScoreModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        ).copyWith(rank: rank++);
        scores.add(score);
      }

      print('✅ Top $limit puntuaciones obtenidas');
      return scores;
    } catch (e) {
      print('❌ Error al obtener ranking: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Obtiene las puntuaciones de un usuario específico
  Future<List<ScoreModel>> getUserScores(String userId) async {
    try {
      final query = await _firebaseService.scoresCollection
          .where('userId', isEqualTo: userId)
          .orderBy('score', descending: true)
          .get();

      return query.docs.map((doc) {
        return ScoreModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error al obtener puntuaciones del usuario: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Stream del ranking en tiempo real
  Stream<List<ScoreModel>> topScoresStream({int limit = 100}) {
    return _firebaseService.scoresCollection
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      int rank = 1;
      return snapshot.docs.map((doc) {
        return ScoreModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        ).copyWith(rank: rank++);
      }).toList();
    });
  }

  // ==================== NIVELES ====================

  /// Obtiene la información de un nivel específico del usuario
  Future<LevelModel?> getUserLevel(String userId, int levelNumber) async {
    try {
      final doc = await _firebaseService.usersCollection
          .doc(userId)
          .collection('levels')
          .doc(levelNumber.toString())
          .get();

      if (!doc.exists) return null;

      return LevelModel.fromMap(
        doc.data() as Map<String, dynamic>,
        levelNumber,
      );
    } catch (e) {
      print('❌ Error al obtener nivel: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Actualiza la información de un nivel del usuario
  Future<void> updateUserLevel(String userId, LevelModel level) async {
    try {
      await _firebaseService.usersCollection
          .doc(userId)
          .collection('levels')
          .doc(level.levelNumber.toString())
          .set(level.toMap(), SetOptions(merge: true));

      print('✅ Nivel ${level.levelNumber} actualizado');
    } catch (e) {
      print('❌ Error al actualizar nivel: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Obtiene todos los niveles del usuario
  Future<List<LevelModel>> getUserLevels(String userId, {int maxLevels = 50}) async {
    try {
      final query = await _firebaseService.usersCollection
          .doc(userId)
          .collection('levels')
          .get();

      return query.docs.map((doc) {
        return LevelModel.fromMap(
          doc.data(),
          int.parse(doc.id),
        );
      }).toList();
    } catch (e) {
      print('❌ Error al obtener niveles: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  // ==================== ESTADO DEL JUEGO ====================

  /// Guarda el estado actual del juego
  Future<void> saveGameState(GameStateModel gameState) async {
    try {
      await _firebaseService.getGameStateDocument(gameState.userId)
          .set(gameState.toMap());
      print('✅ Estado del juego guardado');
    } catch (e) {
      print('❌ Error al guardar estado del juego: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Obtiene el estado guardado del juego
  Future<GameStateModel?> getGameState(String userId) async {
    try {
      final doc = await _firebaseService.getGameStateDocument(userId).get();

      if (!doc.exists) {
        print('⚠️ No hay estado guardado para el usuario: $userId');
        return null;
      }

      return GameStateModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error al obtener estado del juego: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Elimina el estado guardado del juego
  Future<void> deleteGameState(String userId) async {
    try {
      await _firebaseService.getGameStateDocument(userId).delete();
      print('✅ Estado del juego eliminado');
    } catch (e) {
      print('❌ Error al eliminar estado del juego: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  // ==================== CONFIGURACIONES ====================

  /// Actualiza las configuraciones del usuario
  Future<void> updateUserSettings(String userId, {
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    bool? gyroscopeEnabled,
    double? volumeLevel,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (soundEnabled != null) updates['soundEnabled'] = soundEnabled;
      if (musicEnabled != null) updates['musicEnabled'] = musicEnabled;
      if (vibrationEnabled != null) updates['vibrationEnabled'] = vibrationEnabled;
      if (notificationsEnabled != null) updates['notificationsEnabled'] = notificationsEnabled;
      if (gyroscopeEnabled != null) updates['gyroscopeEnabled'] = gyroscopeEnabled;
      if (volumeLevel != null) updates['volumeLevel'] = volumeLevel;

      if (updates.isNotEmpty) {
        await _firebaseService.getUserDocument(userId).update(updates);
        print('✅ Configuraciones actualizadas');
      }
    } catch (e) {
      print('❌ Error al actualizar configuraciones: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Actualiza el personaje seleccionado
  Future<void> updateSelectedCharacter(String userId, int character) async {
    try {
      await _firebaseService.getUserDocument(userId).update({
        'selectedCharacter': character,
      });
      print('✅ Personaje actualizado: $character');
    } catch (e) {
      print('❌ Error al actualizar personaje: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }
}