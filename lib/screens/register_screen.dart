// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../providers/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada! Ya puedes iniciar sesión'), backgroundColor: Colors.green),
        );
        context.go('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    const SizedBox(height: 40),
                    CircleAvatar(radius: 70, child: Image.asset('assets/images/skull_logo.png')),
                    const SizedBox(height: 20),
                    Text('Crear cuenta', style: GoogleFonts.pressStart2p(color: const Color(0xFF7CFC00), fontSize: 22)),
                    const SizedBox(height: 40),

                    _buildField(_emailController, 'Correo', Icons.email),
                    const SizedBox(height: 20),
                    _buildField(_passwordController, 'Contraseña', Icons.lock, obscure: true),
                    const SizedBox(height: 20),
                    _buildField(_confirmController, 'Confirmar contraseña', Icons.lock_outline, obscure: true,
                        validator: (v) => v == _passwordController.text ? null : 'No coinciden'),

                    const SizedBox(height: 40),

                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF7CFC00))
                        : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE87C),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text('Registrarme', textAlign: TextAlign.center, style: GoogleFonts.pressStart2p(fontSize: 14)),
                      ),
                    ),

                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text('← Ya tengo cuenta', style: GoogleFonts.openSans(color: const Color(0xFF00FFFF))),
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

  Widget _buildField(TextEditingController c, String label, IconData icon, {bool obscure = false, String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF007F)),
      ),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF00FFFF)),
          labelText: label,
          labelStyle: GoogleFonts.openSans(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
        validator: validator ?? (v) => v!.isEmpty ? 'Requerido' : null,
      ),
    );
  }
}