import 'package:flutter/material.dart';

enum StockStatusLevel {
  sinStock,
  bajoStock,
  stockMedio,
  stockAlto,
}

class StockStatusSummary {
  const StockStatusSummary({
    required this.level,
    required this.code,
    required this.label,
    required this.message,
    required this.alertTitle,
    required this.severity,
    required this.priority,
  });

  final StockStatusLevel level;
  final String code;
  final String label;
  final String message;
  final String alertTitle;
  final String severity;
  final int priority;

  bool get isAlertWorthy => level != StockStatusLevel.stockAlto;
  bool get isOutOfStock => level == StockStatusLevel.sinStock;
  bool get isLowStock => level == StockStatusLevel.bajoStock;
  bool get isMediumStock => level == StockStatusLevel.stockMedio;
  bool get isHighStock => level == StockStatusLevel.stockAlto;

  IconData get icon {
    switch (level) {
      case StockStatusLevel.sinStock:
        return Icons.cancel_rounded;
      case StockStatusLevel.bajoStock:
        return Icons.warning_amber_rounded;
      case StockStatusLevel.stockMedio:
        return Icons.insights_rounded;
      case StockStatusLevel.stockAlto:
        return Icons.check_circle_rounded;
    }
  }

  Color foregroundColor(ColorScheme colorScheme) {
    switch (level) {
      case StockStatusLevel.sinStock:
        return colorScheme.error;
      case StockStatusLevel.bajoStock:
        return const Color(0xFFF97316);
      case StockStatusLevel.stockMedio:
        return const Color(0xFFEAB308);
      case StockStatusLevel.stockAlto:
        return const Color(0xFF16A34A);
    }
  }

  Color backgroundColor(ColorScheme colorScheme) {
    return foregroundColor(colorScheme).withValues(alpha: 0.14);
  }
}

StockStatusSummary resolveStockStatus({
  required int stockActual,
  required int stockMinimo,
}) {
  final safeStock = stockActual < 0 ? 0 : stockActual;

  if (safeStock <= 0) {
    return const StockStatusSummary(
      level: StockStatusLevel.sinStock,
      code: 'sin_stock',
      label: 'Sin stock',
      message: 'Este producto está sin stock.',
      alertTitle: 'Sin stock',
      severity: 'critical',
      priority: 1,
    );
  }

  if (safeStock < 5) {
    return const StockStatusSummary(
      level: StockStatusLevel.bajoStock,
      code: 'bajo_stock',
      label: 'Bajo stock',
      message: 'El stock actual está por debajo del nivel recomendado.',
      alertTitle: 'Bajo stock',
      severity: 'high',
      priority: 2,
    );
  }

  if (safeStock < 15) {
    return const StockStatusSummary(
      level: StockStatusLevel.stockMedio,
      code: 'stock_medio',
      label: 'Stock medio',
      message: 'El stock actual se encuentra en un nivel intermedio.',
      alertTitle: 'Stock medio',
      severity: 'medium',
      priority: 3,
    );
  }

  return const StockStatusSummary(
    level: StockStatusLevel.stockAlto,
    code: 'stock_alto',
    label: 'Stock alto',
    message: 'El stock se encuentra en nivel saludable.',
    alertTitle: 'Stock alto',
    severity: 'low',
    priority: 4,
  );
}
