import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.gradient,
    this.borderRadius = 28,
    this.interactive = false,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final double borderRadius;
  final bool interactive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = interactive || onTap != null;
    return _HoverSurface(
      interactive: enabled,
      builder: (context, hovered) {
        final shadowAlpha = theme.brightness == Brightness.dark ? 0.24 : 0.08;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, hovered ? -4.0 : 0.0, 0),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? theme.colorScheme.surface.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.92 : 0.98,
                  )
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: hovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.20)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.96),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: shadowAlpha),
                blurRadius: hovered ? 46 : 34,
                spreadRadius: -18,
                offset: Offset(0, hovered ? 24 : 20),
              ),
              BoxShadow(
                color: theme.colorScheme.primary.withValues(
                  alpha: hovered ? 0.10 : 0.04,
                ),
                blurRadius: hovered ? 30 : 18,
                spreadRadius: -18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              hoverColor: Colors.transparent,
              splashColor: onTap == null
                  ? Colors.transparent
                  : theme.colorScheme.primary.withValues(alpha: 0.08),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HoverSurface extends StatefulWidget {
  const _HoverSurface({
    required this.builder,
    required this.interactive,
  });

  final Widget Function(BuildContext context, bool hovered) builder;
  final bool interactive;

  @override
  State<_HoverSurface> createState() => _HoverSurfaceState();
}

class _HoverSurfaceState extends State<_HoverSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.interactive) {
      return widget.builder(context, false);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: widget.builder(context, _hovered),
    );
  }
}
