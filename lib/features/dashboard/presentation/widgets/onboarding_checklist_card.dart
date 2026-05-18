import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';
import 'package:stockmind/features/dashboard/analytics/models/dashboard_analytics_snapshot.dart';
import 'package:stockmind/features/locations/providers/locations_provider.dart';
import 'package:stockmind/features/products/providers/products_provider.dart';

class OnboardingChecklistCard extends StatelessWidget {
  const OnboardingChecklistCard({
    required this.snapshot,
    super.key,
  });

  final DashboardAnalyticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final companyProvider = context.watch<CompanyProfileProvider>();
    final currentCompany = context.watch<CurrentCompanyProvider>();
    final locationsProvider = context.watch<LocationsProvider>();
    final productsProvider = context.watch<ProductsProvider>();
    final tasks = [
      _ChecklistTask(
        title: 'Configurar workspace',
        subtitle: 'Define nombre, contexto y contacto del espacio activo.',
        complete: currentCompany.hasCompany && companyProvider.hasProfile,
        route: AppRoutePaths.company,
      ),
      _ChecklistTask(
        title: 'Agregar ubicación',
        subtitle: 'Crea al menos una ubicación operativa.',
        complete: locationsProvider.hasLocations,
        route: AppRoutePaths.locations,
      ),
      _ChecklistTask(
        title: 'Agregar producto',
        subtitle: 'Carga el primer SKU para activar alertas y analytics.',
        complete: productsProvider.hasProducts,
        route: AppRoutePaths.products,
      ),
      _ChecklistTask(
        title: 'Invitar miembro',
        subtitle: 'Suma a tu equipo o comparte un link de acceso.',
        complete: snapshot.activeUsers > 1,
        route: AppRoutePaths.users,
      ),
      _ChecklistTask(
        title: 'Revisar analytics',
        subtitle: 'Explora KPIs y tendencia del inventario.',
        complete: snapshot.hasData && snapshot.movementsInRange > 0,
        route: AppRoutePaths.dashboard,
      ),
    ];
    final completed = tasks.where((item) => item.complete).length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
    if (completed == tasks.length) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checklist de lanzamiento',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Recorre los pasos clave para que tu espacio se vea listo para una demo pública o uso real.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
            ),
          ),
          const SizedBox(height: 10),
          Text('$completed de ${tasks.length} pasos completos'),
          const SizedBox(height: 18),
          Column(
            children: tasks
                .map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ChecklistTile(task: task),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTask {
  const _ChecklistTask({
    required this.title,
    required this.subtitle,
    required this.complete,
    required this.route,
  });

  final String title;
  final String subtitle;
  final bool complete;
  final String route;
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({required this.task});

  final _ChecklistTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            task.complete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: task.complete ? Colors.green : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(task.subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (!task.complete)
            TextButton(
              onPressed: () => context.go(task.route),
              child: const Text('Abrir'),
            ),
        ],
      ),
    );
  }
}
