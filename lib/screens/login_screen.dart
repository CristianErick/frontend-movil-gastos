import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _googleLoading = false;

static const _kClientId = '264386873541-l39qpkl2j918u53k3qu5lfpstelnvt77.apps.googleusercontent.com';

  static const _envClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');



  String get _googleClientId => _envClientId.isNotEmpty ? _envClientId : _kClientId;

  bool get _hasGoogle => !kIsWeb || _googleClientId.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      Map<String, dynamic> response;
      if (_isLogin) {
        response = await ApiService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        response = await ApiService.register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      await ApiService.saveToken(response['token']);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);

    try {
      final googleSignIn = GoogleSignIn(
        clientId: _googleClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _googleLoading = false);
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;

      Map<String, dynamic> response;
      if (idToken != null) {
        response = await ApiService.loginWithGoogle(idToken: idToken);
      } else {
        response = await ApiService.loginWithGoogle(
          googleId: account.id,
          email: account.email,
          name: account.displayName ?? 'Usuario',
          avatar: account.photoUrl,
        );
      }

      if (response['requires_registration'] == true) {

        if (!context.mounted) return;

        await _showGooglePasswordDialog(

          googleId: response['google_id'] as String,

          email: response['email'] as String,

          name: response['name'] as String,

          avatar: response['avatar'] as String?,

        );

        return;

      }



      await ApiService.saveToken(response['token']);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error con Google: $e')),
        );
      }
    } finally {
      if (context.mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _showGooglePasswordDialog({
    required String googleId,
    required String email,
    required String name,
    String? avatar,
  }) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Correo: '),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) => v!.length < 8 ? 'Mínimo 8 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                validator: (v) => v != passwordController.text ? 'No coinciden' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, {
                  'password': passwordController.text,
                });
              }
            },
            child: const Text('Crear cuenta'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _googleLoading = true);
    try {
      final response = await ApiService.registerWithGoogle(
        googleId: googleId,
        email: email,
        name: name,
        password: result['password']!,
        avatar: avatar,
      );
      await ApiService.saveToken(response['token']);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ')),
        );
      }
    } finally {
      if (context.mounted) setState(() => _googleLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.white38),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      filled: isDark,
      fillColor: isDark ? Colors.grey.shade800 : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : const Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer<ThemeProvider>(
                        builder: (context, tp, _) => IconButton(
                          icon: Icon(
                            tp.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                            color: Colors.white70,
                          ),
                          onPressed: tp.toggle,
                        ),
                      ),
                    ],
                  ),
                  Image.asset('assets/icono.png', height: 80, width: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'OptiGasto',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  if (!_isLogin)
                    TextField(
                      controller: _nameController,
                      decoration: _inputDecoration('Nombre completo'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: _inputDecoration('Correo electrónico'),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: _inputDecoration('Contraseña'),
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4F46E5),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isLogin ? 'Iniciar sesión' : 'Registrarse',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  if (_isLogin && _hasGoogle) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white38)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('o', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                        ),
                        const Expanded(child: Divider(color: Colors.white38)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _googleLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white38),
                          foregroundColor: Colors.white,
                        ),
                        icon: _googleLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        label: Text(
                          'Continuar con Google',
                          style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : '¿Ya tienes cuenta? Inicia sesión',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



