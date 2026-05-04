import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/controllers/auth_controller.dart';
import 'package:stockmind/widgets/auth/auth_shell.dart';
import 'package:stockmind/widgets/auth/auth_text_field.dart';
import 'package:stockmind/widgets/auth/primary_button.dart';
import 'package:stockmind/widgets/auth/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'demo@stockmind.app');
  final _passwordController = TextEditingController(text: '123456');
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return AuthShell(
      title: 'Bienvenido de vuelta',
      subtitle:
          'Inicia sesión para acceder a tu centro de control y mantener el inventario bajo seguimiento.',
      cardChild: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTextField(
              controller: _emailController,
              label: 'Correo electrónico',
              hint: 'nombre@empresa.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Contraseña',
              hint: 'Ingresa tu contraseña',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: _validatePassword,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Recordarme'),
                  ),
                ),
                TextButton(
                  onPressed: _showForgotPasswordMessage,
                  child: const Text('Olvidé mi contraseña'),
                ),
              ],
            ),
            if (authController.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                authController.errorMessage!,
                style: const TextStyle(color: Color(0xFFFCA5A5)),
              ),
            ],
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Iniciar sesión',
              isLoading: authController.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 24),
            const _AuthDivider(label: 'o continúa con'),
            const SizedBox(height: 20),
            SocialLoginButton(
              label: 'Continuar con Google',
              leading: const _GoogleBadge(),
              onPressed: _handleGoogleSignIn,
            ),
            const SizedBox(height: 12),
            SocialLoginButton(
              label: 'Continuar con GitHub',
              leading: const Icon(Icons.code_rounded, size: 18),
              onPressed: _handleGithubSignIn,
            ),
            const SizedBox(height: 22),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('¿Primera vez en StockMind?'),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Completa correo y contraseña para continuar.');
      return;
    }

    final success = await context.read<AuthController>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // TODO: Integrate Firebase Auth / Google Sign-In here.
    if (!mounted) return;
    context.go('/dashboard');
  }

  void _handleGithubSignIn() {
    _showSnackBar('Inicio con GitHub disponible próximamente.');
  }

  void _showForgotPasswordMessage() {
    _showSnackBar('Recuperación de contraseña disponible próximamente.');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    if (!value.contains('@')) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La contraseña es obligatoria';
    }
    return null;
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0x1FFFFFFF))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF94A3B8),
                ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0x1FFFFFFF))),
      ],
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFFDB4437),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
