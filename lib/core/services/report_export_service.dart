import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:stockmind/core/utils/web_file_downloader.dart';
import 'package:stockmind/features/alerts/data/models/stock_alert.dart';
import 'package:stockmind/features/company/models/company_profile.dart';
import 'package:stockmind/features/dashboard/data/models/stock_movement.dart';
import 'package:stockmind/features/products/models/product.dart';
import 'package:stockmind/features/replenishment/models/stock_request.dart';

class ReportExportService {
  Future<void> exportProductsCsv({
    required List<Product> products,
    String? userName,
    CompanyProfile? companyProfile,
  }) async {
    final rows = <List<String>>[
      ..._metaRows('Productos', userName, companyProfile),
      const [
        'Nombre',
        'Código',
        'Categoría',
        'Stock total',
        'Stock por ubicación',
        'Stock mínimo',
        'Fecha vencimiento',
        'Estado',
      ],
      ...products.map(
        (product) => [
          product.name,
          product.barcode ?? '',
          product.category,
          product.totalStock.toString(),
          _locationsSummary(product),
          product.minStock.toString(),
          _formatDate(product.expiryDate),
          product.operationalStatusLabel,
        ],
      ),
    ];
    await _downloadCsv(rows: rows, fileName: _fileName('stockmind_productos'));
  }

  Future<void> exportLocationStockCsv({
    required List<Product> products,
    String? userName,
    CompanyProfile? companyProfile,
  }) async {
    final rows = <List<String>>[
      ..._metaRows('Stock por ubicación', userName, companyProfile),
      const [
        'Producto',
        'Código',
        'Ubicación',
        'Cantidad',
        'Stock total',
        'Estado',
      ],
    ];

    for (final product in products) {
      if (product.locationsStock.isEmpty) {
        rows.add([
          product.name,
          product.barcode ?? '',
          'Sin asignar',
          '0',
          product.totalStock.toString(),
          product.operationalStatusLabel,
        ]);
        continue;
      }
      for (final item in product.locationsStock) {
        rows.add([
          product.name,
          product.barcode ?? '',
          item.locationName,
          item.quantity.toString(),
          product.totalStock.toString(),
          product.operationalStatusLabel,
        ]);
      }
    }

    await _downloadCsv(
      rows: rows,
      fileName: _fileName('stockmind_stock_por_ubicacion'),
    );
  }

  Future<void> exportMovementsCsv({
    required List<StockMovement> movements,
    String? userName,
    CompanyProfile? companyProfile,
  }) async {
    final rows = <List<String>>[
      ..._metaRows('Movimientos de stock', userName, companyProfile),
      const [
        'Fecha',
        'Producto',
        'Código',
        'Tipo',
        'Cantidad',
        'Ubicación origen',
        'Ubicación destino',
        'Stock actualizado',
        'Usuario',
      ],
      ...movements.map(
        (movement) => [
          _formatDateTime(movement.createdAt),
          movement.productName,
          movement.barcode ?? '',
          _movementTypeLabel(movement.normalizedType),
          movement.quantity.toString(),
          movement.sourceLocationName ?? movement.locationName,
          movement.targetLocationName ?? '',
          movement.updatedStock.toString(),
          movement.userName ?? '',
        ],
      ),
    ];
    await _downloadCsv(
      rows: rows,
      fileName: _fileName('stockmind_movimientos'),
    );
  }

  Future<void> exportRequestsCsv({
    required List<StockRequest> requests,
    String? userName,
    CompanyProfile? companyProfile,
  }) async {
    final rows = <List<String>>[
      ..._metaRows('Solicitudes de reposición', userName, companyProfile),
      const [
        'Fecha',
        'Producto',
        'Código',
        'Ubicación',
        'Stock actual',
        'Cantidad solicitada',
        'Estado',
        'Motivo',
        'Usuario',
      ],
      ...requests.map(
        (request) => [
          _formatDateTime(request.createdAt),
          request.productName,
          request.barcode ?? '',
          request.locationName,
          request.currentStock.toString(),
          request.requestedQuantity.toString(),
          _requestStatusLabel(request.status),
          request.reason,
          request.userName,
        ],
      ),
    ];
    await _downloadCsv(
      rows: rows,
      fileName: _fileName('stockmind_reposicion'),
    );
  }

  Future<void> exportAlertsCsv({
    required List<StockAlert> alerts,
    String? userName,
    CompanyProfile? companyProfile,
  }) async {
    final rows = <List<String>>[
      ..._metaRows('Alertas', userName, companyProfile),
      const [
        'Tipo alerta',
        'Producto',
        'Código',
        'Ubicación',
        'Stock actual',
        'Stock mínimo',
        'Vencimiento',
        'Prioridad',
      ],
      ...alerts.map(
        (alert) => [
          _alertTypeLabel(alert.type),
          alert.productName,
          '',
          '',
          alert.currentStock.toString(),
          alert.minStock.toString(),
          _formatDate(alert.expiryDate),
          alert.severity,
        ],
      ),
    ];
    await _downloadCsv(rows: rows, fileName: _fileName('stockmind_alertas'));
  }

  List<List<String>> _metaRows(
    String report,
    String? userName,
    CompanyProfile? companyProfile,
  ) {
    return [
      _metaRow('Reporte', report),
      _metaRow(
        'Empresa',
        companyProfile?.name.trim().isNotEmpty == true
            ? companyProfile!.name
            : 'StockMind',
      ),
      _metaRow('Rubro', companyProfile?.industry ?? ''),
      _metaRow('Correo empresa', companyProfile?.email ?? ''),
      _metaRow('Fecha exportación', _formatDateTime(DateTime.now())),
      _metaRow('Usuario', userName ?? ''),
      _metaRow('Fuente', 'Exportado desde StockMind'),
      const [],
    ];
  }

  Future<void> _downloadCsv({
    required List<List<String>> rows,
    required String fileName,
  }) async {
    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(_csvRow(row));
    }
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    WebFileDownloader.downloadBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'text/csv;charset=utf-8',
    );
  }

  List<String> _metaRow(String key, String value) => [key, value];

  String _csvRow(List<String> values) {
    return values.map((value) => '"${value.replaceAll('"', '""')}"').join(',');
  }

  String _fileName(String prefix) {
    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return '${prefix}_$stamp.csv';
  }

  String _locationsSummary(Product product) {
    if (product.locationsStock.isEmpty) return '';
    return product.locationsStock
        .map((item) => '${item.locationName}: ${item.quantity}')
        .join(' | ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  String _movementTypeLabel(String type) {
    switch (type) {
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
        return type;
    }
  }

  String _requestStatusLabel(String status) {
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

  String _alertTypeLabel(String type) {
    switch (type) {
      case 'low_stock':
        return 'Stock bajo';
      case 'expiring_soon':
        return 'Vencimiento cercano';
      case 'expired':
        return 'Vencido';
      default:
        return type;
    }
  }
}
