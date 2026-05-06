import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/services/storage_service.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/features/auth/presentation/widgets/auth_shell.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/models/company_profile.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

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
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _industryController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PickedImageFile? _logoFile;
  _RegisterAccountType? _selectedType;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _industryController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isBusiness = _selectedType == _RegisterAccountType.business;

    return AuthShell(
      title: _selectedType == null ? '¿Cómo usarás StockMind?' : 'Crea tu espacio',
      subtitle: _selectedType == null
          ? 'Elige el tipo de cuenta para mostrar un registro más claro y rápido.'
          : isBusiness
              ? 'Configura tu usuario y deja listo el perfil base de tu negocio.'
              : 'Crea tu cuenta personal y completa la empresa más adelante si la necesitas.',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _selectedType == null
            ? _buildAccountTypeSelector(context, auth)
            : _buildRegisterForm(context, auth, isBusiness),
      ),
    );
  }

  Widget _buildAccountTypeSelector(BuildContext context, AuthProvider auth) {
    return Column(
      key: const ValueKey('register-selector'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AccountTypeCard(
          icon: Icons.business_center_outlined,
          title: 'Empresa / Negocio',
          description:
              'Para equipos, bodegas o negocios con inventario compartido.',
          onTap: () => setState(() => _selectedType = _RegisterAccountType.business),
        ),
        const SizedBox(height: 16),
        _AccountTypeCard(
          icon: Icons.person_outline_rounded,
          title: 'Persona',
          description:
              'Para controlar tu inventario personal o proyectos pequeños.',
          onTap: () => setState(() => _selectedType = _RegisterAccountType.person),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: auth.isLoading ? null : _handleGoogleLogin,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (auth.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.brand,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  auth.isLoading
                      ? 'Conectando con Google...'
                      : 'Continuar con Google',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿Ya tienes cuenta?'),
            TextButton(
              onPressed: () => context.go(AppRoutePaths.login),
              child: const Text('Ingresar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterForm(
    BuildContext context,
    AuthProvider auth,
    bool isBusiness,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        key: ValueKey('register-form-$isBusiness'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: auth.isLoading
                ? null
                : () => setState(() => _selectedType = null),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Volver'),
          ),
          const SizedBox(height: 8),
          Text(
            'Datos personales',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 3) {
                return 'Ingresa un nombre válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa tu correo.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.verified_user_outlined),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirma tu contraseña.';
              }
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden.';
              }
              return null;
            },
          ),
          if (isBusiness) ...[
            const SizedBox(height: 24),
            Text(
              'Datos de empresa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del negocio / empresa',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (value) {
                if (!isBusiness) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre del negocio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _industryController,
              decoration: const InputDecoration(
                labelText: 'Rubro',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyPhoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo empresa',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección opcional',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Sitio web opcional',
                prefixIcon: Icon(Icons.language_outlined),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      final file = await context.read<StorageService>().pickImage();
                      if (!mounted || file == null) return;
                      setState(() => _logoFile = file);
                    },
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _logoFile == null ? 'Logo opcional' : 'Logo seleccionado',
              ),
            ),
          ],
          const SizedBox(height: 20),
          _GradientActionButton(
            label: auth.isLoading ? 'Creando cuenta...' : 'Crear cuenta',
            onPressed: auth.isLoading ? null : _handleRegister,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: auth.isLoading ? null : _handleGoogleLogin,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (auth.isLoading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'G',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brand,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Text(
                    auth.isLoading
                        ? 'Conectando con Google...'
                        : 'Registrarme con Google',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿Ya tienes cuenta?'),
              TextButton(
                onPressed: () => context.go(AppRoutePaths.login),
                child: const Text('Ingresar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_selectedType == null) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.info,
        title: 'Elige un tipo de cuenta',
        message: 'Selecciona si usarás StockMind como persona o como empresa.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Registro incompleto',
        message:
            'Debes ingresar nombre, correo y una contraseña válida antes de crear la cuenta.',
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      await context.read<UserProvider>().loadCurrentUser();
      final companyProvider = context.read<CompanyProfileProvider>();
      final currentUser = context.read<AuthProvider>().user;
      if (_selectedType == _RegisterAccountType.business &&
          _companyNameController.text.trim().isNotEmpty &&
          currentUser != null) {
        await companyProvider.saveProfile(
          CompanyProfile.empty().copyWith(
            name: _companyNameController.text.trim(),
            industry: _industryController.text.trim(),
            phone: _companyPhoneController.text.trim(),
            email: _companyEmailController.text.trim(),
            address: _addressController.text.trim(),
            website: _websiteController.text.trim(),
            createdBy: currentUser.id,
          ),
          logoFile: _logoFile,
        );
      }
      await showAppAlertDialog(
        context,
        type: AppAlertType.success,
        title: 'Cuenta creada',
        message: 'Tu cuenta fue creada correctamente.',
      );
      return;
    }
    await showAppAlertDialog(
      context,
      type: AppAlertType.error,
      title: 'No se pudo crear la cuenta',
      message:
          auth.error ?? 'No pudimos completar la operación. Inténtalo nuevamente.',
    );
  }

  Future<void> _handleGoogleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle(
      rememberSession: true,
    );
    if (!mounted) return;
    if (success) {
      await context.read<UserProvider>().loadCurrentUser();
      return;
    }
    await showAppAlertDialog(
      context,
      type: AppAlertType.error,
      title: 'No se pudo crear la cuenta',
      message:
          auth.error ?? 'No pudimos completar la operación. Inténtalo nuevamente.',
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: onPressed == null
              ? [
                  Colors.grey.withValues(alpha: 0.55),
                  Colors.grey.withValues(alpha: 0.35),
                ]
              : const [
                  AppTheme.brand,
                  AppTheme.brandViolet,
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: onPressed == null
            ? const []
            : [
                BoxShadow(
                  color: AppTheme.brand.withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: -14,
                  offset: const Offset(0, 18),
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

enum _RegisterAccountType {
  business,
  person,
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            color: colorScheme.surface.withValues(alpha: 0.54),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 26,
                spreadRadius: -18,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
