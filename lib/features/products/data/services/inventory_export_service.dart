import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stockmind/core/utils/web_file_downloader.dart';
import 'package:stockmind/features/products/models/product.dart';

class InventoryExportService {
  Future<void> exportProductsToCsv(List<Product> products) async {
    final buffer = StringBuffer();
    buffer.writeln(_csvRow(const [
      'Producto',
      'Categoría',
      'Precio',
      'Stock total',
      'Stock mínimo',
      'Estado de stock',
      'Ubicaciones',
      'Fecha de vencimiento',
      'Fecha de creación',
      'Última actualización',
    ]));

    for (final product in products) {
      buffer.writeln(
        _csvRow([
          product.name,
          product.category,
          product.price.toStringAsFixed(2),
          product.totalStock.toString(),
          product.minStock.toString(),
          product.operationalStatusLabel,
          _locationsSummary(product),
          _formatDate(product.expiryDate),
          _formatDate(product.createdAt),
          _formatDate(product.updatedAt),
        ]),
      );
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    WebFileDownloader.downloadBytes(
      bytes: bytes,
      fileName: _csvFileName(),
      mimeType: 'text/csv;charset=utf-8',
    );
  }

  Future<void> exportProductsToExcel(List<Product> products) async {
    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet();
    final sheet = excel['Inventario'];

    if (defaultSheetName != null && defaultSheetName != 'Inventario') {
      excel.delete(defaultSheetName);
    }

    sheet.appendRow(_headerRow());
    for (final product in products) {
      sheet.appendRow(_buildExcelRow(product));
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('No fue posible generar el archivo Excel.');
    }

    WebFileDownloader.downloadBytes(
      bytes: Uint8List.fromList(bytes),
      fileName: _fileName(prefix: 'inventario', extension: 'xlsx'),
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<void> exportProductsToPdf(List<Product> products) async {
    final document = pw.Document();
    final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'Reporte de Inventario',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Fecha: $date'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Producto',
              'Categoría',
              'Precio',
              'Stock total',
              'Ubicaciones',
            ],
            data: products
                .map(
                  (product) => [
                    product.name,
                    product.category,
                    _currency(product.price),
                    product.totalStock.toString(),
                    _locationsSummary(product),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.indigo700,
            ),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blueGrey100, width: 0.5),
              ),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    final bytes = await document.save();
    WebFileDownloader.downloadBytes(
      bytes: Uint8List.fromList(bytes),
      fileName: _fileName(prefix: 'reporte_inventario', extension: 'pdf'),
      mimeType: 'application/pdf',
    );
  }

  List<CellValue> _headerRow() {
    return [
      TextCellValue('Nombre producto'),
      TextCellValue('Categoría'),
      TextCellValue('Precio'),
      TextCellValue('Stock total'),
      TextCellValue('Stock por ubicación'),
    ];
  }

  List<CellValue> _buildExcelRow(Product product) {
    return [
      TextCellValue(product.name),
      TextCellValue(product.category),
      TextCellValue(_currency(product.price)),
      TextCellValue(product.totalStock.toString()),
      TextCellValue(_locationsSummary(product)),
    ];
  }

  String _locationsSummary(Product product) {
    if (product.locationQuantities.isEmpty) {
      return '';
    }

    final items = product.locationQuantities.values.toList()
      ..sort(
        (a, b) => a.locationName.toLowerCase().compareTo(
              b.locationName.toLowerCase(),
            ),
      );
    return items
        .map((item) => '${item.locationName}: ${item.quantity}')
        .join(' | ');
  }

  String _currency(double value) {
    return NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }
    return DateFormat('yyyy-MM-dd HH:mm').format(value);
  }

  String _csvRow(List<String> values) {
    return values
        .map((value) => '"${value.replaceAll('"', '""')}"')
        .join(',');
  }

  String _csvFileName() {
    final stamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'stockmind_inventario_$stamp.csv';
  }

  String _fileName({
    required String prefix,
    required String extension,
  }) {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefix}_$stamp.$extension';
  }
}
