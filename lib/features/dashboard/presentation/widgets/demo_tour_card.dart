import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/widgets/section_card.dart';

class DemoTourCard extends StatelessWidget {
  const DemoTourCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recorrido recomendado',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Una guía de 3 minutos para mostrar StockMind en entrevistas, LinkedIn o GitHub.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () => _openTour(context),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Abrir recorrido'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutePaths.users),
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Ir a invitaciones'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openTour(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _DemoTourDialog(),
    );
  }
}

class _DemoTourDialog extends StatelessWidget {
  const _DemoTourDialog();

  @override
  Widget build(BuildContext context) {
    final steps = const [
      _TourStep(
        title: 'Mira los KPIs',
        subtitle: 'Empieza por stock total, usuarios activos y requests pendientes.',
      ),
      _TourStep(
        title: 'Revisa productos críticos',
        subtitle: 'Usa alertas y requests para mostrar riesgo operativo real.',
      ),
      _TourStep(
        title: 'Cambia de workspace',
        subtitle: 'Demuestra multi-membership desde el selector superior.',
      ),
      _TourStep(
        title: 'Invita un miembro',
        subtitle: 'Abre Miembros y genera una invitación por correo o link.',
      ),
      _TourStep(
        title: 'Crea un movimiento',
        subtitle: 'Ajusta stock o muestra el historial para explicar trazabilidad.',
      ),
      _TourStep(
        title: 'Explora analytics',
        subtitle: 'Cierra con tendencias, breakdowns y activity insights.',
      ),
    ];
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guión de demo en 3 minutos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Orden sugerido para contar StockMind como proyecto principal en una entrevista técnica.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ...steps.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            child: Text('${entry.key + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.value.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.value.subtitle,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TourStep {
  const _TourStep({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}
