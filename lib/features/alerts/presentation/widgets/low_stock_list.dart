import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/alerts/data/models/stock_alert.dart';
import 'package:stockmind/features/products/helpers/stock_status_helper.dart';

class LowStockList extends StatelessWidget {
  const LowStockList({
    required this.alerts,
    this.onMarkAsRead,
    this.onResolve,
    super.key,
  });

  final List<StockAlert> alerts;
  final ValueChanged<StockAlert>? onMarkAsRead;
  final ValueChanged<StockAlert>? onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alertas inteligentes', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Supervisa riesgos de stock y vencimiento antes de impactar la operación.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (alerts.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyState(
                title: 'Inventario saludable',
                subtitle: 'No hay alertas activas en este momento.',
                icon: Icons.verified_rounded,
              ),
            )
          else
            ...alerts.asMap().entries.map(
              (entry) => _AlertTile(
                alert: entry.value,
                onMarkAsRead: onMarkAsRead,
                onResolve: onResolve,
              ).animate().fadeIn(
                    duration: 260.ms,
                    delay: (entry.key * 40).ms,
                  ),
            ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    this.onMarkAsRead,
    this.onResolve,
  });

  final StockAlert alert;
  final ValueChanged<StockAlert>? onMarkAsRead;
  final ValueChanged<StockAlert>? onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _statusForAlert(alert);
    final accent = alert.isResolved
        ? colorScheme.outline
        : status.foregroundColor(colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 780;
          final actions = _AlertActions(
            alert: alert,
            accent: accent,
            status: status,
            onMarkAsRead: onMarkAsRead,
            onResolve: onResolve,
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AlertBody(alert: alert, accent: accent, status: status),
                const SizedBox(height: 14),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AlertBody(alert: alert, accent: accent, status: status),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 170, child: actions),
            ],
          );
        },
      ),
    );
  }

  StockStatusSummary _statusForAlert(StockAlert alert) {
    switch (alert.type) {
      case 'low_stock':
        return resolveStockStatus(
          stockActual: alert.currentStock,
          stockMinimo: alert.minStock,
        );
      case 'expired':
        return const StockStatusSummary(
          level: StockStatusLevel.sinStock,
          code: 'expired',
          label: 'Vencido',
          message: 'Este producto ya venció.',
          alertTitle: 'Producto vencido',
          severity: 'high',
          priority: 1,
        );
      case 'expiring_soon':
        return const StockStatusSummary(
          level: StockStatusLevel.bajoStock,
          code: 'expiring_soon',
          label: 'Vence pronto',
          message: 'Este producto vence pronto.',
          alertTitle: 'Este producto vence pronto',
          severity: 'medium',
          priority: 2,
        );
      default:
        return resolveStockStatus(stockActual: 20, stockMinimo: 0);
    }
  }
}

class _AlertBody extends StatelessWidget {
  const _AlertBody({
    required this.alert,
    required this.accent,
    required this.status,
  });

  final StockAlert alert;
  final Color accent;
  final StockStatusSummary status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatter = DateFormat('dd/MM · HH:mm');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            alert.isResolved ? Icons.task_alt_rounded : status.icon,
            color: accent,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(alert.productName, style: theme.textTheme.titleMedium),
                  _SeverityBadge(alert: alert, status: status),
                  if (!alert.isRead && alert.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Nueva',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(alert.message, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaPill(
                    icon: Icons.inventory_2_outlined,
                    label: 'Actual ${alert.currentStock}',
                  ),
                  _MetaPill(
                    icon: alert.isExpiryAlert
                        ? Icons.event_available_outlined
                        : Icons.flag_outlined,
                    label: alert.isExpiryAlert && alert.expiryDate != null
                        ? DateFormat('dd/MM/yyyy').format(alert.expiryDate!)
                        : 'Minimo ${alert.minStock}',
                  ),
                  _MetaPill(
                    icon: Icons.schedule_rounded,
                    label: formatter.format(alert.updatedAt),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlertActions extends StatelessWidget {
  const _AlertActions({
    required this.alert,
    required this.accent,
    required this.status,
    this.onMarkAsRead,
    this.onResolve,
  });

  final StockAlert alert;
  final Color accent;
  final StockStatusSummary status;
  final ValueChanged<StockAlert>? onMarkAsRead;
  final ValueChanged<StockAlert>? onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          alert.isResolved ? 'Resuelta' : alert.title,
          textAlign: TextAlign.end,
          style: theme.textTheme.labelLarge?.copyWith(color: accent),
        ),
        const SizedBox(height: 12),
        if (!alert.isRead && onMarkAsRead != null)
          TextButton(
            onPressed: () => onMarkAsRead!(alert),
            child: const Text('Marcar leida'),
          ),
        if (alert.isActive && onResolve != null)
          FilledButton.tonal(
            onPressed: () => onResolve!(alert),
            child: const Text('Resolver'),
          ),
      ],
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({
    required this.alert,
    required this.status,
  });

  final StockAlert alert;
  final StockStatusSummary status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = alert.isResolved
        ? colorScheme.outline
        : status.foregroundColor(colorScheme);
    final label = alert.isResolved ? 'Resuelta' : status.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
