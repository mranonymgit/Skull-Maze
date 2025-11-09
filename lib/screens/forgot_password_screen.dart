import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';
import '../providers/app_providers.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final audioService = ref.read(audioServiceProvider);
    await audioService.playClickSound();

    final code = (100000 + Random().nextInt(900000)).toString(); // Genera código 6 dígitos

    try {
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': 'service_qogjp9f',
          'template_id': 'template_fyi75lw',
          'user_id': 'r1C5ReyW8-d5TEcEC',
          'template_params': {
            'email': _emailController.text,
            'code': code,
            // Puedes agregar más parámetros si tu plantilla lo requiere
          }
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _codeSent = true);
        // Aquí guarda el código temporalmente si lo necesitas (SharedPreferences, Firestore)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código enviado a ${_emailController.text}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('No se pudo enviar el correo');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('recovery_code');
      final savedEmail = prefs.getString('recovery_email');
      final savedTime = prefs.getInt('recovery_time') ?? 0;
      final email = _emailController.text.trim();

      final now = DateTime.now().millisecondsSinceEpoch;
      final isExpired = now - savedTime > 10 * 60 * 1000; // 10 minutos

      if (email == savedEmail &&
          _codeController.text == savedCode &&
          !isExpired) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código verificado!'), backgroundColor: Colors.green),
        );
        context.go('/reset-password'); // Aquí irás a cambiar contraseña
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isExpired ? 'Código expirado' : 'Código inválido'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
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

                    // Logo
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.transparent,
                      child: Image.asset('assets/images/skull_logo.png'),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Recuperar contraseña',
                      style: GoogleFonts.pressStart2p(
                        color: const Color(0xFF7CFC00),
                        fontSize: 20,
                        shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      icon: Icons.email,
                      enabled: !_codeSent,
                      validator: (v) => v?.contains('@') == true ? null : 'Correo inválido',
                    ),
                    const SizedBox(height: 20),

                    // Código
                    if (_codeSent) ...[
                      _buildTextField(
                        controller: _codeController,
                        label: 'Código de 6 dígitos',
                        icon: Icons.lock_outline,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 30),
                    ],

                    // Botón
                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF7CFC00))
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _codeSent ? _verifyCode : _sendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE87C),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFFF007F), width: 2),
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          _codeSent ? 'Verificar código' : 'Obtener código',
                          style: GoogleFonts.pressStart2p(fontSize: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Volver
                    TextButton(
                      onPressed: () {
                        ref.read(audioServiceProvider).playClickSound();
                        context.go('/login');
                      },
                      child: Text(
                        '← Volver al login',
                        style: GoogleFonts.openSans(color: const Color(0xFF00FFFF)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: enabled ? const Color(0xFFFF007F) : Colors.grey),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF00FFFF)),
          labelText: label,
          labelStyle: GoogleFonts.openSans(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }
}