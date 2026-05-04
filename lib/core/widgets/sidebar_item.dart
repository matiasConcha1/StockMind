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

    return Material(
      color: selected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: selected ? activeColor : idleColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: selected ? activeColor : idleColor,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
