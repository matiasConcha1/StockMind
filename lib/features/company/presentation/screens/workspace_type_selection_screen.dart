import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/stockmind_brand.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';

class WorkspaceTypeSelectionScreen extends StatefulWidget {
  const WorkspaceTypeSelectionScreen({super.key});

  @override
  State<WorkspaceTypeSelectionScreen> createState() =>
      _WorkspaceTypeSelectionScreenState();
}

class _WorkspaceTypeSelectionScreenState
    extends State<WorkspaceTypeSelectionScreen> {
  final _businessFormKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _industryController = TextEditingController();
  bool _isCreatingPersonal = false;
  bool _isCreatingBusiness = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 940;
    final provider = context.watch<CurrentCompanyProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.44),
              const Color(0xFF0E1A2F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StockMindBrandRow(
                      iconSize: 28,
                      subtitle: 'Plataforma inteligente de inventario',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '¿Cómo usarás StockMind?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Puedes administrar stock de tu casa, emprendimiento o empresa.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (provider.errorMessage != null) ...[
                      _SetupBanner(
                        message: provider.errorMessage!,
                        onRetry: provider.refresh,
                      ),
                      const SizedBox(height: 18),
                    ],
                    Expanded(
                      child: isCompact
                          ? ListView(
                              children: [
                                _PersonalWorkspaceCard(
                                  loading: _isCreatingPersonal,
                                  onPressed: _isBusy ? null : _createPersonalWorkspace,
                                ),
                                const SizedBox(height: 16),
                                _BusinessWorkspaceCard(
                                  formKey: _businessFormKey,
                                  companyNameController: _companyNameController,
                                  industryController: _industryController,
                                  loading: _isCreatingBusiness,
                                  onPressed: _isBusy ? null : _createBusinessWorkspace,
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _PersonalWorkspaceCard(
                                    loading: _isCreatingPersonal,
                                    onPressed:
                                        _isBusy ? null : _createPersonalWorkspace,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: _BusinessWorkspaceCard(
                                    formKey: _businessFormKey,
                                    companyNameController: _companyNameController,
                                    industryController: _industryController,
                                    loading: _isCreatingBusiness,
                                    onPressed:
                                        _isBusy ? null : _createBusinessWorkspace,
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
        ),
      ),
    );
  }

  bool get _isBusy => _isCreatingPersonal || _isCreatingBusiness;

  Future<void> _createPersonalWorkspace() async {
    setState(() => _isCreatingPersonal = true);
    try {
      await context.read<CurrentCompanyProvider>().createPersonalWorkspace();
      if (!mounted) return;
      context.go(AppRoutePaths.dashboard);
    } catch (error) {
      await _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isCreatingPersonal = false);
      }
    }
  }

  Future<void> _createBusinessWorkspace() async {
    if (!_businessFormKey.currentState!.validate()) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Faltan datos del espacio',
        message: 'Ingresa al menos el nombre del negocio para continuar.',
      );
      return;
    }

    setState(() => _isCreatingBusiness = true);
    try {
      await context.read<CurrentCompanyProvider>().createBusinessWorkspace(
            companyName: _companyNameController.text.trim(),
            industry: _industryController.text.trim(),
          );
      if (!mounted) return;
      context.go(AppRoutePaths.dashboard);
    } catch (error) {
      await _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isCreatingBusiness = false);
      }
    }
  }

  Future<void> _showError(Object error) async {
    if (!mounted) return;
    await showAppAlertDialog(
      context,
      type: AppAlertType.error,
      title: 'No se pudo crear el espacio de trabajo.',
      message: error.toString().trim().isNotEmpty
          ? error.toString().trim()
          : 'Verifica tus permisos o intenta nuevamente.',
    );
  }
}

class _PersonalWorkspaceCard extends StatelessWidget {
  const _PersonalWorkspaceCard({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
      title: 'Uso personal / casa',
      subtitle:
          'Crea un inventario personal con permisos completos para organizar alimentos, insumos, herramientas o colecciones.',
      icon: Icons.home_work_outlined,
      accent: const Color(0xFF14B8A6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FeatureRow('Workspace personal listo para usar'),
          const _FeatureRow('Productos, ubicaciones y movimientos'),
          const _FeatureRow('Analytics y modo demo disponibles'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.1),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(
                loading ? 'Creando espacio...' : 'Comenzar inventario personal',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessWorkspaceCard extends StatelessWidget {
  const _BusinessWorkspaceCard({
    required this.formKey,
    required this.companyNameController,
    required this.industryController,
    required this.loading,
    required this.onPressed,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController companyNameController;
  final TextEditingController industryController;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
      title: 'Empresa o negocio',
      subtitle:
          'Crea un espacio colaborativo para tu operación con identidad de marca, miembros e inventario compartido.',
      icon: Icons.storefront_outlined,
      accent: const Color(0xFF2563EB),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: companyNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del negocio / empresa',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 2) {
                  return 'Ingresa un nombre válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: industryController,
              decoration: const InputDecoration(
                labelText: 'Rubro opcional',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 16),
            const _FeatureRow('Workspace listo para miembros y roles'),
            const _FeatureRow('Invitaciones y analytics multiempresa'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPressed,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.1),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  loading ? 'Creando espacio...' : 'Crear espacio de negocio',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 34,
            spreadRadius: -20,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 30),
          ),
          const SizedBox(height: 18),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _SetupBanner extends StatelessWidget {
  const _SetupBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Text(message),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
