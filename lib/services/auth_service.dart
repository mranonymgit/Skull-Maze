import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_service.dart';
import '../models/user_model.dart';
import 'database_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Servicio de Autenticación
/// Maneja login, registro y autenticación con Google
class AuthService {
  // Instancia singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseService _databaseService = DatabaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '69778184117-gguo82sde2jbnnfcndqsdavsq5pof83k.apps.googleusercontent.com'
        : null,
    // ESTO ES LO QUE ARREGLA EL POPUP_CLOSED
    scopes: ['email', 'profile'],
    // Y ESTO ES EL TRUCO FINAL:
    signInOption: SignInOption.standard,
  );

  /// Obtiene el usuario actual de Firebase Auth
  User? get currentUser => _firebaseService.currentUser;

  /// Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _firebaseService.authStateChanges;

  /// Verifica si hay usuario autenticado
  bool get isAuthenticated => _firebaseService.isAuthenticated;

  /// Registra un nuevo usuario con email y password
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      print('📝 Registrando nuevo usuario: $email');

      // Crear usuario en Firebase Auth
      final UserCredential credential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Error al crear usuario');
      }

      print('✅ Usuario creado en Firebase Auth: ${credential.user!.uid}');

      // Actualizar el displayName si se proporcionó
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Crear perfil de usuario en Firestore
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        displayName: displayName ?? email.split('@')[0],
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await _databaseService.createUser(userModel);

      print('✅ Usuario registrado exitosamente: ${userModel.email}');
      return userModel;
    } catch (e) {
      print('❌ Error al registrar: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Inicia sesión con email y password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Iniciando sesión con email: $email');

      final UserCredential credential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Error al iniciar sesión');
      }

      print('✅ Usuario autenticado en Firebase Auth: ${credential.user!.uid}');

      // Intentar obtener datos del usuario desde Firestore
      UserModel? userModel = await _databaseService.getUser(credential.user!.uid);

      // Si no existe el documento, crearlo
      if (userModel == null) {
        print('⚠️ Usuario no existe en Firestore, creando documento...');

        userModel = UserModel(
          id: credential.user!.uid,
          email: email,
          displayName: credential.user!.displayName ?? email.split('@')[0],
          photoUrl: credential.user!.photoURL,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await _databaseService.createUser(userModel);
        print('✅ Documento de usuario creado en Firestore');
      } else {
        // Si existe, actualizar último login
        print('✅ Usuario encontrado en Firestore, actualizando último login');
        userModel = userModel.copyWith(lastLogin: DateTime.now());
        await _databaseService.updateUser(userModel);
      }

      print('✅ Login completado exitosamente');
      return userModel;
    } catch (e) {
      print('❌ Error al iniciar sesión: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Inicia sesión con Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // LIMPIAR SESIÓN ANTERIOR (esto arregla 90% de popup_closed)
      await _googleSignIn.disconnect().catchError((_) => null);
      await _googleSignIn.signOut().catchError((_) => null);

      print('Iniciando Google Sign-In...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Usuario canceló el login');
        return null;
      }

      print('Google user: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('No se obtuvieron tokens de Google');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseService.auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Error al iniciar sesión con Google');
      }

      // Verificar si es un usuario nuevo
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      UserModel? userModel;

      if (isNewUser) {
        // Crear perfil de usuario nuevo
        userModel = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await _databaseService.createUser(userModel);
        print('✅ Nuevo usuario con Google: ${userModel.email}');
      } else {
        // Usuario existente, actualizar último login
        await _databaseService.updateLastLogin(userCredential.user!.uid);
        userModel = await _databaseService.getUser(userCredential.user!.uid);
        print('✅ Sesión iniciada con Google: ${userModel?.email}');
      }

      return userModel;
    } catch (e) {
      print('❌ Error al iniciar sesión con Google: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Cierra sesión
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseService.auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      print('✅ Sesión cerrada');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Envía correo de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
      print('✅ Correo de recuperación enviado a: $email');
    } catch (e) {
      print('❌ Error al enviar correo de recuperación: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Elimina la cuenta del usuario
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Eliminar datos de Firestore
      await _databaseService.deleteUser(user.uid);

      // Eliminar cuenta de Firebase Auth
      await user.delete();

      print('✅ Cuenta eliminada');
    } catch (e) {
      print('❌ Error al eliminar cuenta: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Actualiza el email del usuario
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      await user.updateEmail(newEmail);
      print('✅ Email actualizado a: $newEmail');
    } catch (e) {
      print('❌ Error al actualizar email: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }

  /// Actualiza la contraseña del usuario
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      await user.updatePassword(newPassword);
      print('✅ Contraseña actualizada');
    } catch (e) {
      print('❌ Error al actualizar contraseña: $e');
      throw _firebaseService.handleFirebaseError(e);
    }
  }
}