import 'package:flutter/material.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/stockmind_brand.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.onBackPressed,
    this.backLabel,
    this.onMenuPressed,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onBackPressed;
  final String? backLabel;
  final VoidCallback? onMenuPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final company = context.watch<CurrentCompanyProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 1000;
    final isSmallPhone = width < 480;
    final titleStyle = (isSmallPhone
            ? theme.textTheme.headlineSmall
            : theme.textTheme.headlineMedium)
        ?.copyWith(
          fontSize: isSmallPhone ? 28 : null,
          letterSpacing: -0.8,
        );
    final subtitleStyle = (isSmallPhone
            ? theme.textTheme.bodyMedium
            : theme.textTheme.bodyLarge)
        ?.copyWith(fontSize: isSmallPhone ? 15 : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompact) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallPhone ? 14 : 16,
              vertical: isSmallPhone ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.24,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: const StockMindBrandRow(
              iconSize: 24,
              subtitle: 'Smart inventory platform',
            ),
          ),
          SizedBox(height: isSmallPhone ? 14 : 18),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.brand.withValues(alpha: 0.14),
                AppTheme.brandViolet.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.95),
            ),
          ),
          child: Text(
            company.hasCompany
                ? '${company.companyName} · ${company.role}'
                : 'StockMind Workspace',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBackPressed != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.tonalIcon(
                  onPressed: onBackPressed,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(backLabel ?? 'Volver'),
                ),
              ),
            if (isCompact && onMenuPressed != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton.filledTonal(
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: isSmallPhone ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
        if (actions.isNotEmpty) ...[
          SizedBox(height: isSmallPhone ? 14 : 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: isSmallPhone ? 10 : 12,
              runSpacing: isSmallPhone ? 10 : 12,
              children: actions,
            ),
          ),
        ],
      ],
    );
  }
}
