import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stronger/infrastructure/services/firebase/auth_service.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Email o contraseña incorrectos';
        case 'invalid-email':
          return 'El formato del email no es válido';
        case 'user-disabled':
          return 'Esta cuenta ha sido desactivada';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Espera un momento';
        case 'network-request-failed':
          return 'Sin conexión. Comprueba tu internet';
      }
    }
    return 'Ha ocurrido un error. Inténtalo de nuevo';
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Completa todos los campos');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.logIn(email, password);
      if (user != null && mounted) context.go('/');
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / icono
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 40,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Stronger',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Inicia sesión para continuar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(height: 36),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),

                // Error inline
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  child: _errorMessage == null
                      ? const SizedBox.shrink()
                      : Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 18,
                                color: scheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: scheme.onErrorContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Botón
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton(
                          onPressed: _login,
                          child: const Text('Entrar'),
                        ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
