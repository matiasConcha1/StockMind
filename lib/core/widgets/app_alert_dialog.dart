import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stockmind/core/theme/app_theme.dart';

enum AppAlertType {
  success,
  error,
  warning,
  info,
  confirm,
}

class AppAlertDialog extends StatelessWidget {
  const AppAlertDialog({
    required this.type,
    required this.title,
    required this.message,
    this.confirmLabel = 'Aceptar',
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    super.key,
  });

  final AppAlertType type;
  final String title;
  final String message;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  bool get _isConfirm => cancelLabel != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _accentColor(colorScheme);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 40,
                    spreadRadius: -10,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.22),
                          accent.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      _icon,
                      size: 38,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_isConfirm) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancel ??
                                () => Navigator.of(context).pop(false),
                            child: Text(cancelLabel!),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _buttonGradient(accent),
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: FilledButton(
                            onPressed: onConfirm ??
                                () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(confirmLabel),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 180.ms)
        .scale(begin: const Offset(0.94, 0.94), end: const Offset(1, 1));
  }

  IconData get _icon {
    switch (type) {
      case AppAlertType.success:
        return Icons.check_rounded;
      case AppAlertType.error:
        return Icons.close_rounded;
      case AppAlertType.warning:
        return Icons.warning_amber_rounded;
      case AppAlertType.info:
        return Icons.info_outline_rounded;
      case AppAlertType.confirm:
        return Icons.help_outline_rounded;
    }
  }

  Color _accentColor(ColorScheme colorScheme) {
    switch (type) {
      case AppAlertType.success:
        return AppTheme.success;
      case AppAlertType.error:
        return colorScheme.error;
      case AppAlertType.warning:
        return AppTheme.warning;
      case AppAlertType.info:
        return AppTheme.brand;
      case AppAlertType.confirm:
        return AppTheme.brandViolet;
    }
  }

  List<Color> _buttonGradient(Color accent) {
    if (type == AppAlertType.error) {
      return [accent, accent.withValues(alpha: 0.82)];
    }
    if (type == AppAlertType.success) {
      return [accent, accent.withValues(alpha: 0.82)];
    }
    return [AppTheme.brand, AppTheme.brandViolet];
  }
}

Future<bool?> showAppAlertDialog(
  BuildContext context, {
  required AppAlertType type,
  required String title,
  required String message,
  String confirmLabel = 'Aceptar',
  String? cancelLabel,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    pageBuilder: (context, _, __) {
      return AppAlertDialog(
        type: type,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
        child: child,
      );
    },
  );
}

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
}) async {
  final result = await showAppAlertDialog(
    context,
    type: AppAlertType.confirm,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    barrierDismissible: false,
  );
  return result == true;
}
