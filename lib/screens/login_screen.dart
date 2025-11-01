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

          // Reproducir música de fondo DESPUÉS del login
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
          // Reproducir música de fondo
          final audioService = ref.read(audioServiceProvider);
          await audioService.playBackgroundMusic();

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
    final isSmallScreen = size.height < 700; // Detectar pantallas pequeñas

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
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
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Espaciador superior flexible
                      Flexible(
                        flex: isSmallScreen ? 1 : 2,
                        child: const SizedBox(height: 20),
                      ),

                      // Logo y título
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7CFC00).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: isSmallScreen ? 60 : 80,
                                backgroundImage: const AssetImage('assets/images/skull_logo.png'),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 15 : 20),
                            Text(
                              'Skull Maze',
                              style: GoogleFonts.pressStart2p(
                                textStyle: TextStyle(
                                  color: const Color(0xFF7CFC00),
                                  fontSize: isSmallScreen ? 20 : (size.width > 800 ? 24.0 : size.width * 0.06),
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

                      // Espaciador medio flexible
                      Flexible(
                        flex: isSmallScreen ? 1 : 2,
                        child: SizedBox(height: isSmallScreen ? 20 : 40),
                      ),

                      // Formulario
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Column(
                          children: [
                            // Email field
                            _buildTextField(
                              controller: _emailController,
                              label: 'Correo electrónico',
                              icon: Icons.email,
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
                            SizedBox(height: isSmallScreen ? 15 : 20),

                            // Password field
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              icon: Icons.lock,
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
                            SizedBox(height: isSmallScreen ? 20 : 25),

                            // Botón de login
                            _isLoading
                                ? const CircularProgressIndicator(color: Color(0xFF7CFC00))
                                : Column(
                              children: [
                                // Botón de login
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _signInWithEmail,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFE87C),
                                      foregroundColor: const Color(0xFF000000),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(color: Color(0xFFFF007F)),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 12 : 14,
                                        horizontal: 30,
                                      ),
                                      elevation: 5,
                                    ),
                                    child: Text(
                                      'Iniciar sesión',
                                      style: GoogleFonts.pressStart2p(
                                        textStyle: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 10 : 15),

                                // Link ¿Olvidaste tu contraseña?
                                TextButton(
                                  onPressed: () {
                                    final audioService = ref.read(audioServiceProvider);
                                    audioService.playClickSound();
                                    context.go('/forgot-password');
                                  },
                                  child: Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: GoogleFonts.openSans(
                                      color: const Color(0xFF00FFFF),
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 10 : 15),

                                // Divisor "O"
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: Color(0xFFB0BEC5))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        'O',
                                        style: GoogleFonts.openSans(
                                          color: const Color(0xFFB0BEC5),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Color(0xFFB0BEC5))),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 10 : 15),

                                // Botón de Google
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _signInWithGoogle,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(color: Color(0xFFFF007F)),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 12 : 14,
                                        horizontal: 30,
                                      ),
                                      elevation: 5,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset('assets/images/google_image.png', height: 20),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            'Iniciar con Google',
                                            style: GoogleFonts.pressStart2p(
                                              textStyle: TextStyle(
                                                fontSize: isSmallScreen ? 10 : 12,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 15 : 20),

                                // Link ¿No tienes cuenta? Regístrate
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '¿No tienes cuenta? ',
                                      style: GoogleFonts.openSans(
                                        color: const Color(0xFFB0BEC5),
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        final audioService = ref.read(audioServiceProvider);
                                        audioService.playClickSound();
                                        context.go('/register');
                                      },
                                      child: Text(
                                        'Regístrate',
                                        style: GoogleFonts.openSans(
                                          color: const Color(0xFF7CFC00),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Espaciador inferior flexible
                      Flexible(
                        flex: 1,
                        child: SizedBox(height: isSmallScreen ? 20 : 40),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper para los campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
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
        controller: controller,
        style: const TextStyle(color: Color(0xFFFFFFFF)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF00FFFF)),
          labelText: label,
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
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}