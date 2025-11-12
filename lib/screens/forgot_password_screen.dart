// lib/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audio_service.dart';
import '../providers/app_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await ref.read(audioServiceProvider).playClickSound();

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enlace enviado a ${_emailController.text.trim()}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Regresa al login automáticamente después de 3 segundos
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) context.go('/login');
        });
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error desconocido';
      if (e.code == 'user-not-found') mensaje = 'No existe cuenta con ese correo';
      if (e.code == 'invalid-email') mensaje = 'Correo inválido';
      if (e.code == 'too-many-requests') mensaje = 'Demasiados intentos. Espera un rato';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1B3D), Color(0xFF1C1C1C), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 50),

                    // Logo
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.transparent,
                      child: Image.asset('assets/images/skull_logo.png'),
                    ),
                    const SizedBox(height: 30),

                    // Título
                    Text(
                      'Recuperar contraseña',
                      style: GoogleFonts.pressStart2p(
                        color: const Color(0xFF7CFC00),
                        fontSize: 22,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Subtítulo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Te enviaremos un enlace seguro para cambiar tu contraseña',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.openSans(color: Colors.grey[400], fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Campo email
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF007F)),
                        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email, color: Color(0xFF00FFFF)),
                          labelText: 'Correo electrónico',
                          labelStyle: GoogleFonts.openSans(color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingresa tu correo';
                          if (!value.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Botón
                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF7CFC00))
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE87C),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFFF007F), width: 2),
                          ),
                          elevation: 12,
                        ),
                        child: Text(
                          'Enviar enlace',
                          style: GoogleFonts.pressStart2p(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Volver
                    TextButton(
                      onPressed: () {
                        ref.read(audioServiceProvider).playClickSound();
                        context.go('/login');
                      },
                      child: Text(
                        'Volver al login',
                        style: GoogleFonts.openSans(color: const Color(0xFF00FFFF), fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}