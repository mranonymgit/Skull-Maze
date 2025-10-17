import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/game_providers.dart';
import 'package:google_fonts/google_fonts.dart'; // Añadido para usar fuentes de Google

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(
    clientId: '69778184117-auhnk2p9if722jljrvicfqpji3a2sa88.apps.googleusercontent.com', // Agrega tu Client ID aquí
  );
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _signInWithEmail() async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        final gameUser = GameUser()
          ..id = userCredential.user!.uid
          ..name = userCredential.user!.email;
        ref.read(userProvider.notifier).setUser(gameUser);
        context.go('/levels');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _errorMessage = 'Cancelado por el usuario';
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        final gameUser = GameUser()
          ..id = userCredential.user!.uid
          ..name = userCredential.user!.displayName ??
              userCredential.user!.email;
        ref.read(userProvider.notifier).setUser(gameUser);
        context.go('/levels');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;
    final headerHeight = size.height * 0.2; // 20% para el header
    final maxRadius = (size.width > 800 ? 120.0 : size.width * 0.15);
    final maxFontSize = (size.width > 800 ? 24.0 : size.width * 0.06);

    return Scaffold(
      extendBody: true,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          // Min height, pero permite scroll
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2A1B3D),
                  Color(0xFF1C1C1C),
                  Color(0xFF000000),
                ],
              ),
            ),
            child: Column(
              children: [
                // Sección superior con imagen y texto
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Container(
                    height: headerHeight,
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: CircleAvatar(
                              radius: 100,
                              backgroundImage: AssetImage(
                                  'assets/images/skull_logo.png'),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Skull Maze',
                            style: GoogleFonts.pressStart2p(
                              textStyle: TextStyle(
                                color: Color(0xFF7CFC00),
                                fontSize: maxFontSize,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF0B2E62).withOpacity(0.3),
                                    offset: Offset(0.5, 0.5),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 170),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black12.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF007F).withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _emailController,
                          style: TextStyle(color: Color(0xFFFFFFFF)),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                                Icons.email, color: Color(0xFF00FFFF)),
                            labelText: 'Correo electrónico',
                            labelStyle: GoogleFonts.openSans(
                              textStyle: TextStyle(
                                color: Color(0xFFB0BEC5),
                                fontSize: 16,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF007F)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFFFF4500), width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black12.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF007F).withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _passwordController,
                          style: TextStyle(color: Color(0xFFFFFFFF)), // Color del texto ingresado
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                                Icons.lock, color: Color(0xFF00FFFF)),
                            labelText: 'Contraseña',
                            labelStyle: GoogleFonts.openSans(
                              textStyle: TextStyle(
                                color: Color(0xFFB0BEC5),
                                fontSize: 16,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF007F)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFFFF4500), width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: true,
                        ),
                      ),
                      SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: _signInWithEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFE87C),
                          foregroundColor: Color(0xFF000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Color(0xFFFF007F)),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 30),
                          elevation: 5,
                        ).copyWith(
                          backgroundColor: MaterialStateProperty.resolveWith<
                              Color>(
                                (states) =>
                            states.contains(MaterialState.pressed)
                                ? Color(0xFFD4B44A)
                                : Color(0xFFFFE87C),
                          ),
                        ),
                        child: Text(
                          'Iniciar sesión',
                          style: GoogleFonts.pressStart2p(
                            textStyle: TextStyle(
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Color(0xFFFF007F)),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 30),
                          elevation: 5,
                        ).copyWith(
                          backgroundColor: MaterialStateProperty.resolveWith<
                              Color>(
                                (states) =>
                            states.contains(MaterialState.pressed)
                                ? Color(0xFFD3D3D3)
                                : Colors.white,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                                'assets/images/google_image.png', height: 20),
                            SizedBox(width: 1),
                            Text(
                              'Iniciar con Google',
                              style: GoogleFonts.pressStart2p(
                                textStyle: TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.openSans(
                              textStyle: TextStyle(
                                color: Color(0xFFFF4500),
                                fontSize: 14,
                                shadows: [
                                  Shadow(
                                    color: Colors.black12,
                                    offset: Offset(0.5, 0.5),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom),
                // Espacio dinámico para el teclado
              ],
            ),
          ),
        ),
      ),
    );
  }
}