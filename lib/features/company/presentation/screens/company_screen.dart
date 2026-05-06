import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/services/storage_service.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/permission_guard.dart';
import 'package:stockmind/core/widgets/remote_image_frame.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/models/company_profile.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _industryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  PickedImageFile? _logoFile;
  bool _removeLogo = false;

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<CompanyProfileProvider>();
    final profile = provider.profile ?? const CompanyProfile.empty();
    _syncControllers(profile);

    return DashboardFrame(
      title: 'Empresa',
      subtitle: 'Configura la identidad de tu negocio dentro de StockMind.',
      onBackPressed: () => context.go(AppRoutePaths.settings),
      backLabel: 'Volver a ajustes',
      child: PermissionGuard(
        allowed: auth.canManageSettings,
        actionLabel: 'Volver al dashboard',
        onAction: () => context.go(AppRoutePaths.dashboard),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 760;
                      final form = _buildForm(context, profile);
                      final preview = _buildLogoPreview(context, profile);
                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            preview,
                            const SizedBox(height: 18),
                            form,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 240, child: preview),
                          const SizedBox(width: 18),
                          Expanded(child: form),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: provider.isLoading ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  provider.isLoading ? 'Guardando...' : 'Guardar empresa',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoPreview(BuildContext context, CompanyProfile profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = _removeLogo ? null : profile.logoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
              child: imageUrl != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: RemoteImageFrame(
                          imageUrl: imageUrl,
                          size: 160,
                          icon: Icons.storefront_outlined,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    )
                  : Center(
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 52,
                    color: colorScheme.primary,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final file = await context.read<StorageService>().pickImage();
            if (!mounted) return;
            setState(() {
              _logoFile = file;
              _removeLogo = false;
            });
          },
          icon: const Icon(Icons.image_outlined),
          label: const Text('Cambiar logo'),
        ),
        if (imageUrl != null || _logoFile != null)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _logoFile = null;
                _removeLogo = true;
              });
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Quitar logo'),
          ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, CompanyProfile profile) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre del negocio',
            prefixIcon: Icon(Icons.business_outlined),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Ingresa el nombre del negocio.' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _industryController,
          decoration: const InputDecoration(
            labelText: 'Rubro',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Ingresa el rubro.' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Ingresa el teléfono.' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Correo empresa',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Ingresa el correo de la empresa.' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Dirección',
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _websiteController,
          decoration: const InputDecoration(
            labelText: 'Sitio web',
            prefixIcon: Icon(Icons.language_outlined),
          ),
        ),
      ],
    );
  }

  void _syncControllers(CompanyProfile profile) {
    if (_nameController.text.isEmpty) _nameController.text = profile.name;
    if (_industryController.text.isEmpty) _industryController.text = profile.industry;
    if (_phoneController.text.isEmpty) _phoneController.text = profile.phone;
    if (_emailController.text.isEmpty) _emailController.text = profile.email;
    if (_addressController.text.isEmpty) _addressController.text = profile.address;
    if (_websiteController.text.isEmpty) _websiteController.text = profile.website;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      await showAppAlertDialog(
        context,
        type: AppAlertType.warning,
        title: 'Faltan datos de empresa',
        message: 'Completa nombre, rubro, teléfono y correo antes de guardar.',
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final provider = context.read<CompanyProfileProvider>();
    final current = provider.profile ?? const CompanyProfile.empty();
    await provider.saveProfile(
      current.copyWith(
        name: _nameController.text.trim(),
        industry: _industryController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        website: _websiteController.text.trim(),
        createdBy: current.createdBy.isEmpty ? (auth.user?.id ?? '') : current.createdBy,
      ),
      logoFile: _logoFile,
      removeLogo: _removeLogo,
    );
    if (!mounted) return;
    await showAppAlertDialog(
      context,
      type: provider.error == null ? AppAlertType.success : AppAlertType.error,
      title: provider.error == null ? 'Empresa actualizada' : 'No se pudo guardar',
      message: provider.error == null
          ? 'Los datos de empresa fueron guardados correctamente.'
          : provider.error!,
    );
  }
}
