import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/features/auth/presentation/widgets/auth_shell.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AuthShell(
      title: 'Recupera tu acceso',
      subtitle: 'Enviaremos un enlace de recuperación al correo registrado.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu correo.';
                }
                return null;
              },
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 14),
              Text(
                auth.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_sent) ...[
              const SizedBox(height: 14),
              Text(
                'Correo enviado. Revisa tu bandeja de entrada.',
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: auth.isLoading ? null : _handleReset,
                child: Text(auth.isLoading ? 'Enviando...' : 'Enviar enlace'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(AppRoutePaths.login),
              child: const Text('Volver al login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context
        .read<AuthProvider>()
        .sendResetEmail(_emailController.text.trim());
    if (success && mounted) {
      setState(() => _sent = true);
    }
  }
}
