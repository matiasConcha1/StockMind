import 'package:flutter/material.dart';

class RemoteImageFrame extends StatelessWidget {
  const RemoteImageFrame({
    required this.size,
    required this.icon,
    this.imageUrl,
    this.borderRadius,
    this.placeholderAssetPath,
    super.key,
  });

  final double size;
  final String? imageUrl;
  final IconData icon;
  final BorderRadius? borderRadius;
  final String? placeholderAssetPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(size * 0.24);
    final normalizedUrl = imageUrl?.trim();
    final hasImage = normalizedUrl != null && normalizedUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: radius,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              normalizedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _ImageFallback(
                icon: icon,
                placeholderAssetPath: placeholderAssetPath,
              ),
            )
          : _ImageFallback(
              icon: icon,
              placeholderAssetPath: placeholderAssetPath,
            ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({
    required this.icon,
    this.placeholderAssetPath,
  });

  final IconData icon;
  final String? placeholderAssetPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.14),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: placeholderAssetPath != null
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  placeholderAssetPath!,
                  fit: BoxFit.contain,
                ),
              )
            : Icon(
                icon,
                color: colorScheme.primary,
                size: 24,
              ),
      ),
    );
  }
}
