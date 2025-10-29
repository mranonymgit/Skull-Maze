import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Servicio principal de Firebase
/// Proporciona acceso centralizado a todos los servicios de Firebase
class FirebaseService {
  // Instancias singleton
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Servicios de Firebase
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // Referencias a colecciones principales
  CollectionReference get usersCollection => firestore.collection('users');
  CollectionReference get scoresCollection => firestore.collection('scores');
  CollectionReference get levelsCollection => firestore.collection('levels');
  CollectionReference get gameStatesCollection => firestore.collection('gameStates');

  /// Obtiene el usuario actual autenticado
  User? get currentUser => auth.currentUser;

  /// Obtiene el ID del usuario actual
  String? get currentUserId => auth.currentUser?.uid;

  /// Verifica si hay un usuario autenticado
  bool get isAuthenticated => auth.currentUser != null;

  /// Stream de cambios de autenticación
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Inicializa Firebase (llamar en main.dart)
  static Future<void> initialize() async {
    // Firebase ya se inicializa en main.dart con Firebase.initializeApp()
    // Este método puede usarse para configuraciones adicionales
    print('✅ Firebase Service inicializado');
  }

  /// Obtiene una referencia a un documento de usuario
  DocumentReference getUserDocument(String userId) {
    return usersCollection.doc(userId);
  }

  /// Obtiene una referencia a un documento de estado de juego
  DocumentReference getGameStateDocument(String userId) {
    return gameStatesCollection.doc(userId);
  }

  /// Maneja errores de Firebase de forma centralizada
  String handleFirebaseError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Usuario no encontrado';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'email-already-in-use':
          return 'El correo ya está registrado';
        case 'weak-password':
          return 'La contraseña es muy débil';
        case 'invalid-email':
          return 'Correo electrónico inválido';
        case 'user-disabled':
          return 'Usuario deshabilitado';
        case 'operation-not-allowed':
          return 'Operación no permitida';
        default:
          return 'Error de autenticación: ${error.message}';
      }
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'No tienes permisos para realizar esta acción';
        case 'unavailable':
          return 'Servicio no disponible. Verifica tu conexión';
        case 'not-found':
          return 'Datos no encontrados';
        default:
          return 'Error de Firebase: ${error.message}';
      }
    }
    return 'Error desconocido: ${error.toString()}';
  }

  /// Cierra todas las conexiones (opcional, para limpieza)
  Future<void> dispose() async {
    // Aquí puedes agregar limpieza si es necesario
    print('🔥 Firebase Service cerrado');
  }
}