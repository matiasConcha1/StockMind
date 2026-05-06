import 'package:flutter/material.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';

Future<void> runExportTask({
  required BuildContext context,
  required bool hasData,
  required String noDataTitle,
  required String noDataMessage,
  required Future<void> Function() task,
  required String successMessage,
}) async {
  if (!hasData) {
    await showAppAlertDialog(
      context,
      type: AppAlertType.info,
      title: noDataTitle,
      message: noDataMessage,
    );
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: SizedBox(
          width: 260,
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Generando reporte...')),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    await task();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(successMessage)));
  } catch (error) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await showAppAlertDialog(
      context,
      type: AppAlertType.error,
      title: 'Error al exportar',
      message: error.toString().trim().isNotEmpty
          ? error.toString().trim()
          : 'No pudimos generar el reporte.',
    );
  }
}
