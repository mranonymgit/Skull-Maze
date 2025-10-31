import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../providers/app_providers.dart';
import '../services/audio_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    print('🔐 Intentando login con email...');
    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      print('✅ Login completado, verificando estado...');

      if (mounted) {
        final authState = ref.read(authControllerProvider);
        print('📊 Estado de auth: isAuthenticated=${authState.isAuthenticated}, hasError=${authState.hasError}');

        if (authState.isAuthenticated) {
          print('✅ Usuario autenticado, navegando a /levels');

          // ⭐ Reproducir música de fondo DESPUÉS del login
          final audioService = ref.read(audioServiceProvider);
          await audioService.playBackgroundMusic();

          context.go('/levels');
        } else if (authState.hasError) {
          print('❌ Error en auth: ${authState.errorMessage}');
          _showError(authState.errorMessage!);
        }
      }
    } catch (e) {
      print('❌ Excepción en login: $e');
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();

      if (mounted) {
        final authState = ref.read(authControllerProvider);
        if (authState.isAuthenticated) {
          context.go('/levels');
        } else if (authState.hasError) {
          _showError(authState.errorMessage!);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.2;
    final maxFontSize = (size.width > 800 ? 24.0 : size.width * 0.06);

    // Escuchar cambios en el audio service
    ref.listen(audioServiceProvider, (previous, next) {
      // Audio service inicializado
    });

    return Scaffold(
      extendBody: true,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: Container(
            decoration: const BoxDecoration(
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header con logo
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Container(
                      height: headerHeight,
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const CircleAvatar(
                                radius: 100,
                                backgroundImage: AssetImage('assets/images/skull_logo.png'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Skull Maze',
                              style: GoogleFonts.pressStart2p(
                                textStyle: TextStyle(
                                  color: const Color(0xFF7CFC00),
                                  fontSize: maxFontSize,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFF0B2E62).withOpacity(0.3),
                                      offset: const Offset(0.5, 0.5),
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
                  const SizedBox(height: 170),

                  // Formulario de login
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Email field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black12.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF007F).withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Color(0xFFFFFFFF)),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email, color: Color(0xFF00FFFF)),
                              labelText: 'Correo electrónico',
                              labelStyle: GoogleFonts.openSans(
                                textStyle: const TextStyle(
                                  color: Color(0xFFB0BEC5),
                                  fontSize: 16,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFFFF007F)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFFFF4500), width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.red),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu correo';
                              }
                              if (!value.contains('@')) {
                                return 'Correo inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black12.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF007F).withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Color(0xFFFFFFFF)),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFF00FFFF)),
                              labelText: 'Contraseña',
                              labelStyle: GoogleFonts.openSans(
                                textStyle: const TextStyle(
                                  color: Color(0xFFB0BEC5),
                                  fontSize: 16,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFFFF007F)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFFFF4500), width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.red),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresa tu contraseña';
                              }
                              if (value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Botón de login
                        _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFF7CFC00))
                            : Column(
                          children: [
                            ElevatedButton(
                              onPressed: _signInWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFE87C),
                                foregroundColor: const Color(0xFF000000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFFF007F)),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                                elevation: 5,
                              ),
                              child: Text(
                                'Iniciar sesión',
                                style: GoogleFonts.pressStart2p(
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Botón de Google
                            ElevatedButton(
                              onPressed: _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFFF007F)),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                                elevation: 5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/images/google_image.png', height: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Iniciar con Google',
                                    style: GoogleFonts.pressStart2p(
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}