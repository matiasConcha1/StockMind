import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/services/report_export_service.dart';
import 'package:stockmind/core/widgets/empty_state.dart';
import 'package:stockmind/core/widgets/export_feedback.dart';
import 'package:stockmind/core/widgets/section_card.dart';
import 'package:stockmind/features/auth/providers/auth_provider.dart';
import 'package:stockmind/features/company/providers/company_profile_provider.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/dashboard/data/services/stock_movement_service.dart';
import 'package:stockmind/features/dashboard/presentation/widgets/dashboard_frame.dart';

enum _MovementFilter { all, entry, exit, adjustment, transfer, expired, damaged }

class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  _MovementFilter _typeFilter = _MovementFilter.all;
  DateTime? _selectedDate;
  List<StockMovement> _lastFilteredMovements = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id;

    return DashboardFrame(
      title: 'Movimientos',
      onBackPressed: () => context.go(AppRoutePaths.dashboard),
      backLabel: 'Volver',
      subtitle:
          'Revisa entradas, salidas, ajustes y eventos especiales del inventario en tiempo real.',
      actions: [
        FilledButton.tonalIcon(
          onPressed: userId == null || !auth.canExport
              ? null
              : () => _exportMovements(context),
          icon: const Icon(Icons.download_rounded),
          label: const Text('Exportar'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(context),
          const SizedBox(height: 16),
          if (userId == null)
            const Card(
              child: SizedBox(
                height: 260,
                child: EmptyState(
                  title: 'Sin sesión activa',
                  subtitle: 'Inicia sesión para ver los movimientos de stock.',
                  icon: Icons.lock_outline_rounded,
                ),
              ),
            )
          else
            StreamBuilder<List<StockMovement>>(
              stream: StockMovementService().watchMovements(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'No fue posible cargar los movimientos de stock.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Card(
                    child: SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final filtered = _applyFilters(snapshot.data!);
                _lastFilteredMovements = filtered;
                if (filtered.isEmpty) {
                  return const Card(
                    child: SizedBox(
                      height: 280,
                      child: EmptyState(
                        title: 'No hay movimientos registrados',
                        subtitle:
                            'Ajusta la búsqueda, el tipo o la fecha para encontrar registros.',
                        icon: Icons.history_toggle_off_rounded,
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered
                      .map((movement) => _MovementCard(movement: movement))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Buscar producto o código',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTypeFilter(context),
                  const SizedBox(height: 12),
                  _buildDateButton(context),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Buscar producto o código',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _buildTypeFilter(context)),
                  const SizedBox(width: 14),
                  SizedBox(width: 220, child: _buildDateButton(context)),
                ],
              ),
      ),
    );
  }

  Widget _buildTypeFilter(BuildContext context) {
    return DropdownButtonFormField<_MovementFilter>(
      initialValue: _typeFilter,
      decoration: const InputDecoration(
        labelText: 'Tipo de movimiento',
        prefixIcon: Icon(Icons.tune_rounded),
      ),
      items: _MovementFilter.values
          .map(
            (filter) => DropdownMenuItem(
              value: filter,
              child: Text(_typeLabel(filter)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _typeFilter = value);
      },
    );
  }

  Widget _buildDateButton(BuildContext context) {
    final label = _selectedDate == null
        ? 'Todas las fechas'
        : DateFormat('dd/MM/yyyy').format(_selectedDate!);
    return OutlinedButton.icon(
      onPressed: () => _pickDate(context),
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text(label),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
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

  List<StockMovement> _applyFilters(List<StockMovement> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((movement) {
      final matchesQuery = query.isEmpty ||
          movement.productName.toLowerCase().contains(query) ||
          (movement.barcode?.toLowerCase().contains(query) ?? false);
      final matchesType = switch (_typeFilter) {
        _MovementFilter.all => true,
        _MovementFilter.entry => movement.normalizedType == 'entry',
        _MovementFilter.exit => movement.normalizedType == 'exit',
        _MovementFilter.adjustment => movement.normalizedType == 'adjustment',
        _MovementFilter.transfer => movement.normalizedType == 'transfer',
        _MovementFilter.expired => movement.normalizedType == 'expired',
        _MovementFilter.damaged => movement.normalizedType == 'damaged',
      };
      final matchesDate = _selectedDate == null
          ? true
          : DateTime(
                  movement.createdAt.year,
                  movement.createdAt.month,
                  movement.createdAt.day,
                ) ==
                _selectedDate;
      return matchesQuery && matchesType && matchesDate;
    }).toList();
  }

  String _typeLabel(_MovementFilter filter) {
    switch (filter) {
      case _MovementFilter.all:
        return 'Todos';
      case _MovementFilter.entry:
        return 'Entradas';
      case _MovementFilter.exit:
        return 'Salidas';
      case _MovementFilter.adjustment:
        return 'Ajustes';
      case _MovementFilter.transfer:
        return 'Transferencias';
      case _MovementFilter.expired:
        return 'Vencidos';
      case _MovementFilter.damaged:
        return 'Dañados';
    }
  }

  Future<void> _exportMovements(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final company = context.read<CompanyProfileProvider>().profile;
    await runExportTask(
      context: context,
      hasData: _lastFilteredMovements.isNotEmpty,
      noDataTitle: 'No hay movimientos para exportar',
      noDataMessage:
          'Ajusta la bÃºsqueda o espera nuevos movimientos para generar el reporte.',
      successMessage: 'Los movimientos fueron descargados correctamente.',
      task: () => ReportExportService().exportMovementsCsv(
        movements: _lastFilteredMovements,
        userName: auth.user?.displayName ?? auth.user?.email,
        companyProfile: company,
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  const _MovementCard({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM · HH:mm');
    final accent = _typeColor(movement);

    return SectionCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _typeTitle(movement),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatter.format(movement.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(movement.productName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(movement.reason, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill(context, Icons.qr_code_rounded,
                  movement.barcode ?? 'Sin código'),
              _pill(context, Icons.swap_horiz_rounded,
                  '${movement.previousTotalStock} → ${movement.newTotalStock}'),
              _pill(context, Icons.inventory_2_outlined,
                  '${movement.quantity} unid.'),
              if (movement.hasLocationContext)
                _pill(context, Icons.location_on_outlined, movement.locationName),
              if ((movement.userName ?? '').isNotEmpty)
                _pill(context, Icons.person_outline_rounded, movement.userName!),
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
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

  Color _typeColor(StockMovement movement) {
    if (movement.isEntry) return Colors.green;
    if (movement.isExit) return Colors.red;
    if (movement.isAdjustment) return Colors.amber.shade700;
    if (movement.isTransfer) return Colors.cyan;
    if (movement.isExpired) return Colors.deepOrange;
    if (movement.isDamaged) return Colors.orange;
    return Colors.blue;
  }

  String _typeTitle(StockMovement movement) {
    switch (movement.normalizedType) {
      case 'entry':
        return 'Entrada';
      case 'exit':
        return 'Salida';
      case 'adjustment':
        return 'Ajuste';
      case 'transfer':
        return 'Transferencia';
      case 'expired':
        return 'Vencido';
      case 'damaged':
        return 'Dañado';
      default:
        return movement.normalizedType;
    }
  }
}
