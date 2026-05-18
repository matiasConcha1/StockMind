import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/i18n/app_strings.dart';
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
    final strings = context.strings;
    final isBusiness = _selectedType == _RegisterAccountType.business;

    return AuthShell(
      title: _selectedType == null ? strings.chooseUsageTitle : strings.createYourWorkspace,
      subtitle: _selectedType == null
          ? strings.chooseUsageSubtitle
          : isBusiness
              ? strings.businessRegisterSubtitle
              : strings.personalRegisterSubtitle,
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
    final strings = context.strings;
    return Column(
      key: const ValueKey('register-selector'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AccountTypeCard(
          icon: Icons.business_center_outlined,
          title: strings.businessAccount,
          description: strings.businessAccountDescription,
          onTap: () => setState(() => _selectedType = _RegisterAccountType.business),
        ),
        const SizedBox(height: 16),
        _AccountTypeCard(
          icon: Icons.person_outline_rounded,
          title: strings.personalAccount,
          description: strings.personalAccountDescription,
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
                      ? strings.connectingGoogle
                      : strings.continueWithGoogle,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(strings.alreadyHaveAccount),
            TextButton(
              onPressed: () => context.go(_loginPath(context)),
              child: Text(strings.signIn),
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
    final strings = context.strings;
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
            label: Text(strings.back),
          ),
          const SizedBox(height: 8),
          Text(
            strings.personalDetails,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: strings.name,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 3) {
                return strings.enterValidName;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: strings.emailLabel,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return strings.enterEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: strings.passwordLabel,
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
                return strings.passwordMinLength;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: strings.confirmPassword,
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
                return strings.confirmYourPassword;
              }
              if (value != _passwordController.text) {
                return strings.passwordsDoNotMatch;
              }
              return null;
            },
          ),
          if (isBusiness) ...[
            const SizedBox(height: 24),
            Text(
              strings.businessDetails,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _companyNameController,
              decoration: InputDecoration(
                labelText: strings.businessName,
                prefixIcon: const Icon(Icons.business_outlined),
              ),
              validator: (value) {
                if (!isBusiness) return null;
                if (value == null || value.trim().isEmpty) {
                  return strings.enterBusinessName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _industryController,
              decoration: InputDecoration(
                labelText: strings.industry,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyPhoneController,
              decoration: InputDecoration(
                labelText: strings.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: strings.companyEmail,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: strings.optionalAddress,
                prefixIcon: const Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: InputDecoration(
                labelText: strings.optionalWebsite,
                prefixIcon: const Icon(Icons.language_outlined),
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
                _logoFile == null ? strings.optionalLogo : strings.logoSelected,
              ),
            ),
          ],
          const SizedBox(height: 20),
          _GradientActionButton(
            label: auth.isLoading
                ? strings.creatingAccount
                : strings.createAccountAction,
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
                        ? strings.connectingGoogle
                        : strings.signUpWithGoogle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(strings.alreadyHaveAccount),
              TextButton(
                onPressed: () => context.go(_loginPath(context)),
                child: Text(strings.signIn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    final strings = context.strings;
    if (_selectedType == null) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.info,
        title: strings.chooseAccountTypeTitle,
        message: strings.chooseAccountTypeMessage,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: strings.incompleteRegisterTitle,
        message: strings.incompleteRegisterMessage,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final isBusiness = _selectedType == _RegisterAccountType.business;
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      accountType: isBusiness ? 'business' : 'person',
    );
    if (!mounted) return;

    if (!success) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: strings.accountCreateFailedTitle,
        message: auth.error ?? strings.genericTryAgain,
      );
      return;
    }

    await context.read<UserProvider>().loadCurrentUser();

    if (_selectedType == _RegisterAccountType.business) {
      final companyProvider = context.read<CompanyProfileProvider>();
      final currentUser = context.read<AuthProvider>().user;
      if (_companyNameController.text.trim().isNotEmpty && currentUser != null) {
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

        if (!mounted) return;
        if (companyProvider.error != null) {
          await showAppAlertDialog(
            context,
            type: AppAlertType.warning,
            title: strings.businessProfileWarningTitle,
            message: strings.businessProfileWarningMessage(
              companyProvider.error!,
            ),
          );
          return;
        }
      }
    }

    await showAppAlertDialog(
      context,
      type: AppAlertType.success,
      title: strings.accountCreatedTitle,
      message: strings.accountCreatedMessage,
    );
  }

  Future<void> _handleGoogleLogin() async {
    final strings = context.strings;
    if (_selectedType == null) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.info,
        title: strings.chooseAccountTypeBeforeGoogleTitle,
        message: strings.chooseAccountTypeBeforeGoogleMessage,
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle(
      rememberSession: true,
    );
    if (!mounted) return;

    if (success) {
      final userProvider = context.read<UserProvider>();
      await userProvider.updateCurrentUserAccountType(
        _selectedType == _RegisterAccountType.business ? 'business' : 'person',
      );
      await userProvider.loadCurrentUser();
      if (_selectedType == _RegisterAccountType.business &&
          _companyNameController.text.trim().isNotEmpty) {
        final companyProvider = context.read<CompanyProfileProvider>();
        final currentUser = context.read<AuthProvider>().user;
        if (currentUser != null) {
          await companyProvider.saveProfile(
            (companyProvider.profile ?? CompanyProfile.empty()).copyWith(
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
      }
      return;
    }

    await showAppAlertDialog(
      context,
      type: AppAlertType.error,
      title: strings.accountCreateFailedTitle,
      message: auth.error ?? strings.genericTryAgain,
    );
  }

  String _loginPath(BuildContext context) {
    final redirectTarget =
        GoRouterState.of(context).uri.queryParameters['redirect'];
    if (redirectTarget == null || redirectTarget.isEmpty) {
      return AppRoutePaths.login;
    }
    return '${AppRoutePaths.login}?redirect=${Uri.encodeComponent(redirectTarget)}';
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
