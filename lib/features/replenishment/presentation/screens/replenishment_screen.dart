import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/services/report_export_service.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/export_feedback.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';
import 'package:stockmind/features/replenishment/models/stock_request.dart';
import 'package:stockmind/features/replenishment/presentation/widgets/stock_request_dialog.dart';
import 'package:stockmind/features/replenishment/providers/stock_requests_provider.dart';

class ReplenishmentScreen extends StatefulWidget {
  const ReplenishmentScreen({super.key});

  @override
  State<ReplenishmentScreen> createState() => _ReplenishmentScreenState();
}

class _ReplenishmentScreenState extends State<ReplenishmentScreen> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockRequestsProvider>();
    final auth = context.watch<AuthProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;
    final visibleRequests = provider.visibleRequests.where((request) {
      if (_selectedDate == null) return true;
      final requestDay = DateTime(
        request.createdAt.year,
        request.createdAt.month,
        request.createdAt.day,
      );
      return requestDay == _selectedDate;
    }).toList();

    return DashboardFrame(
      title: 'Reposición',
      subtitle:
          'Gestiona solicitudes de reposición, completa ingresos de stock y mantiene historial operativo por ubicación.',
      actions: [
        FilledButton.tonalIcon(
          onPressed: () => _exportRequests(context, visibleRequests, auth),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Exportar'),
        ),
        FilledButton.icon(
          onPressed: () => showStockRequestDialog(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nueva solicitud'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RequestMetricCard(
                  title: 'Pendientes',
                  value: provider.pendingCount.toString(),
                  helper: 'Solicitudes por atender',
                  icon: Icons.hourglass_top_rounded,
                ),
                const SizedBox(height: 12),
                _RequestMetricCard(
                  title: 'Completadas semana',
                  value: provider.completedThisWeekCount.toString(),
                  helper: 'Reposiciones cerradas esta semana',
                  icon: Icons.task_alt_rounded,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _RequestMetricCard(
                    title: 'Pendientes',
                    value: provider.pendingCount.toString(),
                    helper: 'Solicitudes por atender',
                    icon: Icons.hourglass_top_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RequestMetricCard(
                    title: 'Completadas semana',
                    value: provider.completedThisWeekCount.toString(),
                    helper: 'Reposiciones cerradas esta semana',
                    icon: Icons.task_alt_rounded,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    onChanged: provider.updateSearchQuery,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por producto, ubicación o código',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: StockRequestFilter.values
                        .map(
                          (filter) => ChoiceChip(
                            label: Text(_filterLabel(filter)),
                            selected: provider.filter == filter,
                            onSelected: (_) => provider.updateFilter(filter),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _selectedDate == null
                            ? 'Todas las fechas'
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (visibleRequests.isEmpty)
            const Card(
              child: SizedBox(
                height: 280,
                child: EmptyState(
                  title: 'Sin solicitudes',
                  subtitle:
                      'Crea una solicitud de reposición desde esta pantalla, un producto, una alerta o el scanner.',
                  icon: Icons.inventory_rounded,
                ),
              ),
            )
          else
            Column(
              children: visibleRequests
                  .map((request) => _RequestCard(request: request))
                  .toList(),
            ),
        ],
      ),
    );
  }

  String _filterLabel(StockRequestFilter filter) {
    return switch (filter) {
      StockRequestFilter.all => 'Todas',
      StockRequestFilter.pending => 'Pendientes',
      StockRequestFilter.approved => 'Aprobadas',
      StockRequestFilter.completed => 'Completadas',
      StockRequestFilter.cancelled => 'Canceladas',
    };
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (!mounted) return;
    setState(() {
      _selectedDate = picked == null
          ? null
          : DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _exportRequests(
    BuildContext context,
    List<StockRequest> requests,
    AuthProvider auth,
  ) async {
    await runExportTask(
      context: context,
      hasData: requests.isNotEmpty,
      noDataTitle: 'No hay solicitudes para exportar',
      noDataMessage:
          'Crea o filtra solicitudes de reposiciÃ³n antes de generar un reporte.',
      successMessage:
          'Las solicitudes de reposiciÃ³n fueron descargadas correctamente.',
      task: () => ReportExportService().exportRequestsCsv(
        requests: requests,
        userName: auth.user?.displayName ?? auth.user?.email,
      ),
    );
  }
}

class _RequestMetricCard extends StatelessWidget {
  const _RequestMetricCard({
    required this.title,
    required this.value,
    required this.helper,
    required this.icon,
  });

  final String title;
  final String value;
  final String helper;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(helper, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final StockRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM · HH:mm');
    final provider = context.read<StockRequestsProvider>();
    final color = _statusColor(context, request.status);

    return SectionCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.productName, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${request.locationName} · ${request.requestedQuantity} unid.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(request.status),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill(context, Icons.inventory_2_outlined, 'Actual ${request.currentStock}'),
              _pill(context, Icons.add_box_outlined, 'Solicitadas ${request.requestedQuantity}'),
              if ((request.barcode ?? '').isNotEmpty)
                _pill(context, Icons.qr_code_rounded, request.barcode!),
              _pill(context, Icons.schedule_rounded, formatter.format(request.createdAt)),
              _pill(context, Icons.person_outline_rounded, request.userName),
            ],
          ),
          const SizedBox(height: 12),
          Text(request.reason, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (request.isPending)
                FilledButton.tonal(
                  onPressed: () => provider.approveRequest(request),
                  child: const Text('Aprobar'),
                ),
              if (request.isPending || request.isApproved)
                FilledButton(
                  onPressed: () => provider.completeRequest(request),
                  child: const Text('Completar'),
                ),
              if (!request.isCompleted && !request.isCancelled)
                OutlinedButton(
                  onPressed: () => provider.cancelRequest(request),
                  child: const Text('Cancelar'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
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

  Color _statusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'pending':
        return Colors.amber.shade700;
      case 'approved':
        return colorScheme.primary;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobada';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status;
    }
  }
}
