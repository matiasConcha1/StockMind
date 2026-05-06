import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.onMenuPressed,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onMenuPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 1000;
    final isSmallPhone = width < 480;
    final titleStyle = (isSmallPhone
            ? theme.textTheme.headlineSmall
            : theme.textTheme.headlineMedium)
        ?.copyWith(fontSize: isSmallPhone ? 28 : null);
    final subtitleStyle = (isSmallPhone
            ? theme.textTheme.bodyMedium
            : theme.textTheme.bodyLarge)
        ?.copyWith(fontSize: isSmallPhone ? 15 : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
