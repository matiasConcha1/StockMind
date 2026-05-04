import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/controllers/auth_controller.dart';
import 'package:stockmind/controllers/theme_controller.dart';
import 'package:stockmind/widgets/common/section_card.dart';
import 'package:stockmind/widgets/layout/dashboard_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final authController = context.watch<AuthController>();

    return SafeArea(
      child: Builder(
        builder: (context) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              DashboardHeader(
                title: 'Ajustes',
                subtitle: 'Preferencias de tema y resumen del perfil activo.',
                onMenuPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(height: 24),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tema', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Claro'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Oscuro'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest_rounded),
                          label: Text('Sistema'),
                        ),
                      ],
                      selected: {themeController.themeMode},
                      onSelectionChanged: (selection) {
                        themeController.setThemeMode(selection.first);
                      },
                    ),
                    const SizedBox(height: 28),
                    Text('Perfil activo',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const CircleAvatar(child: Icon(Icons.person_rounded)),
                      title:
                          Text(authController.currentUser?.name ?? 'Usuario'),
                      subtitle: Text(authController.currentUser?.email ?? ''),
                      trailing:
                          Text(authController.currentUser?.userTypeLabel ?? ''),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
