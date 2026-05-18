import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/i18n/app_strings.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/stockmind_brand.dart';
import 'package:stockmind/features/auth/presentation/widgets/auth_shell.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';
import 'package:stockmind/features/demo/services/demo_seed_service.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberSession = true;
  bool _demoLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final strings = context.strings;
    final theme = Theme.of(context);
    final isEnabled = !auth.isLoading && !_demoLoading;
    final redirectTarget =
        GoRouterState.of(context).uri.queryParameters['redirect'];

    return AuthShell(
      title: strings.loginTitle,
      subtitle: strings.loginSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StockMindLogo(width: 164, centered: true),
            const SizedBox(height: 22),
            Text(
              strings.email,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'admin@stockmind.app',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.enterEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            Text(
              strings.password,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: strings.enterPassword,
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
            const SizedBox(height: 14),
            _RememberSessionCard(
              value: _rememberSession,
              enabled: isEnabled,
              onChanged: (value) {
                setState(() {
                  _rememberSession = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(AppRoutePaths.forgotPassword),
                child: Text(strings.forgotPassword),
              ),
            ),
            const SizedBox(height: 18),
            _GradientActionButton(
              label: auth.isLoading || _demoLoading
                  ? strings.signingIn
                  : strings.enterStockMind,
              onPressed: isEnabled ? _handleLogin : null,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isEnabled ? _handleGoogleLogin : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
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
                            theme.colorScheme.primary,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
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
            const SizedBox(height: 14),
            Tooltip(
              message:
                  strings.demoTooltip,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: isEnabled ? _handleDemoLogin : null,
                  icon: _demoLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _demoLoading ? strings.preparingDemo : strings.enterDemo,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  strings.noAccount,
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => context.go(
                    redirectTarget == null || redirectTarget.isEmpty
                        ? AppRoutePaths.register
                        : '${AppRoutePaths.register}?redirect=${Uri.encodeComponent(redirectTarget)}',
                  ),
                  child: Text(strings.createAccount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final strings = context.strings;
    if (!_formKey.currentState!.validate()) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: strings.missingAccessDataTitle,
        message: strings.missingAccessDataMessage,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      rememberSession: _rememberSession,
    );

    if (!mounted) return;
    if (success) {
      await context.read<UserProvider>().loadCurrentUser();
      return;
    }
    await showAppAlertDialog(
      context,
      type: AppAlertType.error,
      title: strings.loginFailedTitle,
      message: auth.error ?? strings.verifyCredentials,
    );
  }

  Future<void> _handleGoogleLogin() async {
    final strings = context.strings;
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle(
      rememberSession: _rememberSession,
    );

    if (!mounted) return;
    if (success) {
      await context.read<UserProvider>().loadCurrentUser();
      return;
    }
    await showAppAlertDialog(
      context,
      type: AppAlertType.error,
      title: strings.loginFailedTitle,
      message: auth.error ?? strings.verifyCredentials,
    );
  }

  Future<void> _handleDemoLogin() async {
    final strings = context.strings;
    setState(() => _demoLoading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle(
      rememberSession: true,
    );
    if (!mounted) return;
    if (!success) {
      setState(() => _demoLoading = false);
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: strings.demoOpenFailedTitle,
        message: auth.error ?? strings.demoAuthFailed,
      );
      return;
    }

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.loadCurrentUser();
      final authUser = auth.user;
      if (authUser == null) {
        throw StateError(strings.activeSessionMissing);
      }
      await DemoSeedService().ensurePersonalDemoWorkspace(
        uid: authUser.id,
        displayName: authUser.displayName,
        email: authUser.email,
        accountType: authUser.accountType,
      );
      if (!mounted) return;
      await context.read<CurrentCompanyProvider>().refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.demoReadyMessage,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: strings.demoPrepareFailedTitle,
        message: error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _demoLoading = false);
      }
    }
  }
}

class _RememberSessionCard extends StatelessWidget {
  const _RememberSessionCard({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = context.strings;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: value
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHighest.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.22 : 0.40,
              ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value
              ? AppTheme.brand.withValues(alpha: 0.42)
              : colorScheme.outlineVariant.withValues(alpha: 0.80),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? () => onChanged(!value) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Transform.scale(
                  scale: 0.94,
                  child: Switch.adaptive(
                    value: value,
                    onChanged: enabled ? onChanged : null,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppTheme.brandViolet,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: theme.brightness == Brightness.dark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.rememberSession,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color:
                              value ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.keepSessionActive,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
