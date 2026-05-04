import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/controllers/auth_controller.dart';
import 'package:stockmind/models/app_user.dart';
import 'package:stockmind/widgets/auth/auth_shell.dart';
import 'package:stockmind/widgets/auth/auth_text_field.dart';
import 'package:stockmind/widgets/auth/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  UserType _selectedUserType = UserType.negocio;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return AuthShell(
      title: 'Crea tu espacio operativo',
      subtitle:
          'Configura tu cuenta, define tu tipo de uso y empieza a centralizar el inventario desde un solo lugar.',
      cardChild: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTextField(
              controller: _nameController,
              label: 'Nombre completo',
              hint: 'Tu nombre o el de tu negocio',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _emailController,
              label: 'Correo electrónico',
              hint: 'nombre@empresa.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El correo es obligatorio';
                }
                if (!value.contains('@')) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Contraseña',
              hint: 'Crea una contraseña segura',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La contraseña es obligatoria';
                }
                if (value.trim().length < 6) {
                  return 'Usa al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Tipo de usuario',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<UserType>(
              showSelectedIcon: false,
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                side: const WidgetStatePropertyAll(
                  BorderSide(color: Color(0x263B82F6)),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF1D4ED8);
                  }
                  return const Color(0x140F172A);
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return const Color(0xFFE2E8F0);
                }),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              segments: const [
                ButtonSegment<UserType>(
                  value: UserType.hogar,
                  icon: Icon(Icons.home_rounded),
                  label: Text('Hogar'),
                ),
                ButtonSegment<UserType>(
                  value: UserType.negocio,
                  icon: Icon(Icons.storefront_rounded),
                  label: Text('Negocio'),
                ),
              ],
              selected: {_selectedUserType},
              onSelectionChanged: (selection) {
                setState(() => _selectedUserType = selection.first);
              },
            ),
            const SizedBox(height: 14),
            CheckboxListTile(
              value: _rememberMe,
              onChanged: (value) {
                setState(() => _rememberMe = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Recordarme en este dispositivo'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Crear cuenta',
              isLoading: authController.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('¿Ya tienes cuenta?'),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Iniciar sesión'),
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
      _showSnackBar('Completa todos los datos requeridos.');
      return;
    }

    final success = await context.read<AuthController>().register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          userType: _selectedUserType,
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
