import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/services/app_config_service.dart';
import 'package:stockmind/core/services/notification_service.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/models/company_profile.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/locations/models/inventory_location.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';
import 'package:stockmind/features/users/providers/user_provider.dart';

class InitialOnboardingDialog extends StatefulWidget {
  const InitialOnboardingDialog({super.key});

  @override
  State<InitialOnboardingDialog> createState() => _InitialOnboardingDialogState();
}

class _InitialOnboardingDialogState extends State<InitialOnboardingDialog> {
  int _step = 0;
  final _companyNameController = TextEditingController();
  final _industryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationNameController = TextEditingController();
  String _locationType = 'Refrigerador';
  final _defaultMinStockController = TextEditingController(text: '5');
  bool _enableNotifications = true;
  bool _saving = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _industryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationNameController.dispose();
    _defaultMinStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<CompanyProfileProvider>().profile;
    _seedCompany(company);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 720;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenida a StockMind',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Completa la configuración inicial para dejar tu inventario listo para operar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Stepper(
                        currentStep: _step,
                        controlsBuilder: (context, details) => const SizedBox.shrink(),
                        onStepTapped: (value) => setState(() => _step = value),
                        steps: [
                          Step(
                            isActive: _step >= 0,
                            title: const Text('Bienvenida'),
                            content: const Text(
                              'StockMind te ayudará a controlar productos, ubicaciones, alertas y reposición desde una sola app.',
                            ),
                          ),
                          Step(
                            isActive: _step >= 1,
                            title: const Text('Datos de empresa'),
                            content: Column(
                              children: [
                                TextField(
                                  controller: _companyNameController,
                                  decoration: const InputDecoration(labelText: 'Nombre del negocio'),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _industryController,
                                  decoration: const InputDecoration(labelText: 'Rubro'),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _phoneController,
                                  decoration: const InputDecoration(labelText: 'Teléfono'),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(labelText: 'Correo empresa'),
                                ),
                              ],
                            ),
                          ),
                          Step(
                            isActive: _step >= 2,
                            title: const Text('Primera ubicación'),
                            content: Column(
                              children: [
                                TextField(
                                  controller: _locationNameController,
                                  decoration: const InputDecoration(labelText: 'Nombre ubicación'),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _locationType,
                                  items: LocationsProvider.baseLocationTypes
                                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _locationType = value);
                                  },
                                  decoration: const InputDecoration(labelText: 'Tipo ubicación'),
                                ),
                              ],
                            ),
                          ),
                          Step(
                            isActive: _step >= 3,
                            title: const Text('Stock mínimo por defecto'),
                            content: TextField(
                              controller: _defaultMinStockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stock mínimo por defecto',
                              ),
                            ),
                          ),
                          Step(
                            isActive: _step >= 4,
                            title: const Text('Notificaciones'),
                            content: SwitchListTile.adaptive(
                              value: _enableNotifications,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (value) => setState(() => _enableNotifications = value),
                              title: const Text('Activar notificaciones'),
                              subtitle: const Text(
                                'Recibe alertas de stock bajo, productos por vencer y reposiciones.',
                              ),
                            ),
                          ),
                          Step(
                            isActive: _step >= 5,
                            title: const Text('Finalizar'),
                            content: const Text(
                              'Cuando finalices, StockMind guardará tu empresa, la ubicación inicial y tu configuración base.',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_step > 0)
                    OutlinedButton(
                      onPressed: _saving ? null : () => setState(() => _step -= 1),
                      child: const Text('Atrás'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : (_step == 5 ? _finish : () => setState(() => _step += 1)),
                    child: Text(_saving ? 'Guardando...' : (_step == 5 ? 'Finalizar' : 'Continuar')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _seedCompany(CompanyProfile? profile) {
    if (profile == null) return;
    if (_companyNameController.text.isEmpty) _companyNameController.text = profile.name;
    if (_industryController.text.isEmpty) _industryController.text = profile.industry;
    if (_phoneController.text.isEmpty) _phoneController.text = profile.phone;
    if (_emailController.text.isEmpty) _emailController.text = profile.email;
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      final companyProvider = context.read<CompanyProfileProvider>();
      final locationsProvider = context.read<LocationsProvider>();
      final notificationService = context.read<NotificationService>();
      final appConfigService = AppConfigService();
      final userId = auth.user?.id;
      if (userId == null) return;

      if (auth.canManageSettings &&
          _companyNameController.text.trim().isNotEmpty) {
        await companyProvider.saveProfile(
          (companyProvider.profile ?? const CompanyProfile.empty()).copyWith(
            name: _companyNameController.text.trim(),
            industry: _industryController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            createdBy: userId,
          ),
        );
      }

      if (_locationNameController.text.trim().isNotEmpty &&
          !locationsProvider.locations.any(
            (item) => item.name.trim().toLowerCase() ==
                _locationNameController.text.trim().toLowerCase(),
          )) {
        await locationsProvider.createLocation(
          InventoryLocation(
            id: '',
            name: _locationNameController.text.trim(),
            description: 'Ubicación inicial creada desde onboarding.',
            type: _locationType,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      if (auth.canManageSettings) {
        final defaultMinStock =
            int.tryParse(_defaultMinStockController.text.trim()) ?? 5;
        await appConfigService.updateDefaultMinStock(defaultMinStock);
      }

      if (_enableNotifications &&
          notificationService.canPromptForNotifications &&
          !notificationService.notificationsEnabled) {
        await notificationService.setNotificationsEnabled(true);
      }

      await userProvider.setOnboardingCompleted(true);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
