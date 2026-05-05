import 'package:flutter/material.dart';

final class StockMindBrandAssets {
  static const fullLogo = 'assets/images/logo_Stockmind.png';
  static const iconLogo = 'assets/images/logo_icon.png';

  const StockMindBrandAssets._();
}

class StockMindLogo extends StatelessWidget {
  const StockMindLogo({
    this.width = 160,
    this.centered = false,
    super.key,
  });

  final double width;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isLight
            ? colorScheme.surface
            : colorScheme.surface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight
              ? colorScheme.outlineVariant
              : colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: isLight
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: Image.asset(
        StockMindBrandAssets.fullLogo,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _LogoFallback(width: width);
        },
      ),
    );

    if (!centered) return child;
    return Center(child: child);
  }
}

class StockMindIconMark extends StatelessWidget {
  const StockMindIconMark({
    this.size = 32,
    this.framed = false,
    this.framePadding = 8,
    this.frameRadius = 14,
    this.assetScale = 1.78,
    super.key,
  });

  final double size;
  final bool framed;
  final double framePadding;
  final double frameRadius;
  final double assetScale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = Center(
      child: Transform.scale(
        scale: assetScale,
        child: Image.asset(
          StockMindBrandAssets.iconLogo,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _IconFallback(size: size);
          },
        ),
      ),
    );

    if (!framed) return icon;

    return Container(
      padding: EdgeInsets.all(framePadding),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? colorScheme.surface
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(frameRadius),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(frameRadius - 2),
        child: icon,
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width, minHeight: width * 0.28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconFallback(size: width.clamp(28, 46).toDouble()),
          const SizedBox(width: 12),
          Text(
            'StockMind',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: colorScheme.onPrimary,
        size: size * 0.55,
      ),
    );
  }
}

class StockMindBrandRow extends StatelessWidget {
  const StockMindBrandRow({
    this.iconSize = 30,
    this.framed = false,
    this.subtitle = 'Inventory SaaS',
    super.key,
  });

  final double iconSize;
  final bool framed;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        StockMindIconMark(
          size: iconSize,
          framed: framed,
          framePadding: 8,
          frameRadius: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'StockMind',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
