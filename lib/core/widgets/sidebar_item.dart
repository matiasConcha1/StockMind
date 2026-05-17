import 'package:flutter/material.dart';

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isDestructive = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;
    final idleColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return _SidebarHover(
      builder: (context, hovered) {
        final foreground = selected
            ? activeColor
            : hovered
                ? theme.colorScheme.onSurface
                : idleColor;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [
                      activeColor.withValues(alpha: 0.18),
                      activeColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: selected
                ? null
                : hovered
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? activeColor.withValues(alpha: 0.18)
                  : hovered
                      ? theme.colorScheme.outlineVariant.withValues(alpha: 0.95)
                      : Colors.transparent,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 4,
                      height: selected ? 26 : hovered ? 18 : 10,
                      decoration: BoxDecoration(
                        color: selected ? activeColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected
                            ? activeColor.withValues(alpha: 0.14)
                            : hovered
                                ? theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.38)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: foreground,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: selected || hovered ? 1 : 0,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: selected ? activeColor : foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SidebarHover extends StatefulWidget {
  const _SidebarHover({required this.builder});

  final Widget Function(BuildContext context, bool hovered) builder;

  @override
  State<_SidebarHover> createState() => _SidebarHoverState();
}

class _SidebarHoverState extends State<_SidebarHover> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered),
    );
  }
}
