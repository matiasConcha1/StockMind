import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stockmind/core/widgets/stockmind_brand.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 760;
    final isTablet = size.width >= 760 && size.width < 1100;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.brightness == Brightness.dark
                  ? const Color(0xFF07111F)
                  : const Color(0xFFF7FAFF),
              theme.brightness == Brightness.dark
                  ? const Color(0xFF10182C)
                  : const Color(0xFFEFF3FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              right: -40,
              child: _AmbientGlow(
                size: 260,
                color: Color(0xFF7C3AED),
                opacity: 0.14,
              ),
            ),
            const Positioned(
              bottom: -80,
              left: -30,
              child: _AmbientGlow(
                size: 220,
                color: Color(0xFF2563EB),
                opacity: 0.12,
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 18 : 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight = constraints.maxHeight;
                        final formPanel = _FormPanel(
                          title: title,
                          subtitle: subtitle,
                          child: child,
                          availableHeight: availableHeight,
                        );

                        if (isMobile) {
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                const _MobileBranding(),
                                const SizedBox(height: 18),
                                formPanel,
                              ],
                            ),
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: isTablet ? 5 : 6,
                              child: _HeroPanel(
                                availableHeight: availableHeight,
                                isTablet: isTablet,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: formPanel),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 320.ms);
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.availableHeight,
    required this.isTablet,
  });

  final double availableHeight;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isLowHeight = availableHeight < 850;
    final isVeryLowHeight = availableHeight < 720;
    final isUltraLowHeight = availableHeight < 660;

    final horizontalPadding = isUltraLowHeight
        ? 18.0
        : isVeryLowHeight
            ? 22.0
            : (isTablet ? 26.0 : 34.0);
    final verticalPadding = isUltraLowHeight
        ? 18.0
        : isVeryLowHeight
            ? 20.0
            : (isTablet ? 26.0 : 34.0);

    final titleFontSize = isUltraLowHeight
        ? 28.0
        : isVeryLowHeight
            ? 34.0
            : (isTablet ? 38.0 : 48.0);

    final primarySpacing = isUltraLowHeight
        ? 14.0
        : isVeryLowHeight
            ? 18.0
            : 28.0;
    final secondarySpacing = isUltraLowHeight
        ? 10.0
        : isVeryLowHeight
            ? 14.0
            : 18.0;
    final metricSpacing = isVeryLowHeight ? 10.0 : 14.0;

    final showIllustration = availableHeight >= 900;
    final showDescription = !isUltraLowHeight;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            StockMindIconMark(
              size: isVeryLowHeight ? 36 : 44,
              framed: true,
              framePadding: isVeryLowHeight ? 10 : 12,
              frameRadius: 18,
              assetScale: 1.9,
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'StockMind',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Inventory SaaS',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: primarySpacing),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _HeaderTag(label: 'Tiempo real'),
            _HeaderTag(label: 'Firebase Auth'),
            _HeaderTag(label: 'Responsive'),
          ],
        ),
        SizedBox(height: primarySpacing),
        Text(
          'Inventario claro.\nOperación veloz.\nDecisiones reales.',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            height: 1.02,
            fontSize: titleFontSize,
          ),
        ),
        if (showDescription) ...[
          SizedBox(height: secondarySpacing),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isVeryLowHeight ? 460 : 520),
            child: Text(
              'Controla productos, alertas y rendimiento operativo desde un panel visualmente sólido, diseñado para equipos modernos.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: isVeryLowHeight ? 14 : null,
              ),
            ),
          ),
        ],
        SizedBox(height: primarySpacing),
        Wrap(
          spacing: metricSpacing,
          runSpacing: metricSpacing,
          children: [
            _FloatingMetric(
              label: 'Productos',
              value: '+245',
              icon: Icons.inventory_2_rounded,
              compact: isVeryLowHeight,
            ),
            _FloatingMetric(
              label: 'Alertas',
              value: '23',
              icon: Icons.warning_amber_rounded,
              compact: isVeryLowHeight,
            ),
            _FloatingMetric(
              label: 'Inventario',
              value: '\$45.231',
              icon: Icons.attach_money_rounded,
              compact: isVeryLowHeight,
            ),
          ],
        ),
        if (showIllustration) ...[
          const SizedBox(height: 22),
          const _InventoryIllustration(),
        ],
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1D4ED8),
            Color(0xFF7C3AED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 52,
            spreadRadius: -20,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 24,
            child: Container(
              width: isVeryLowHeight ? 72 : 92,
              height: isVeryLowHeight ? 72 : 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (!isLowHeight)
            Positioned(
              bottom: 90,
              left: -24,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: content,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 380.ms)
        .slideX(begin: -0.03, end: 0)
        .scale(begin: const Offset(0.985, 0.985), end: const Offset(1, 1));
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.availableHeight,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double availableHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowHeight = availableHeight < 760;

    return Container(
      padding: EdgeInsets.all(isLowHeight ? 24 : 34),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.85),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 50,
            spreadRadius: -22,
            offset: const Offset(0, 30),
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.34 : 0.10,
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Acceso seguro',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: isLowHeight ? 14 : 18),
                Text(title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(subtitle, style: theme.textTheme.bodyLarge),
                SizedBox(height: isLowHeight ? 22 : 28),
                child,
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 360.ms, delay: 60.ms)
        .slideX(begin: 0.03, end: 0)
        .scale(begin: const Offset(0.99, 0.99), end: const Offset(1, 1));
  }
}

class _MobileBranding extends StatelessWidget {
  const _MobileBranding();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const StockMindLogo(width: 170, centered: true),
        const SizedBox(height: 14),
        Text(
          'Inventario claro. Operación veloz. Decisiones reales.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.04, end: 0);
  }
}

class _FloatingMetric extends StatelessWidget {
  const _FloatingMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.compact,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 128 : 148,
        maxWidth: compact ? 140 : 152,
      ),
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: compact ? 20 : 22),
          SizedBox(height: compact ? 10 : 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 19 : 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTag extends StatelessWidget {
  const _HeaderTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InventoryIllustration extends StatelessWidget {
  const _InventoryIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 14,
            right: 18,
            bottom: 0,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 24,
            child: _MiniPanel(
              width: 160,
              title: 'Stock',
              subtitle: '98% estable',
              bars: const [0.48, 0.72, 0.58, 0.84],
            ),
          ),
          Positioned(
            left: 132,
            top: 0,
            child: _MiniPanel(
              width: 240,
              title: 'Dashboard',
              subtitle: 'Rendimiento semanal',
              bars: const [0.30, 0.44, 0.62, 0.52, 0.78, 0.90],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 16,
            child: Container(
              width: 178,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Alertas críticas',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _AlertRow(label: 'Dock USB-C Studio', value: '5'),
                  const SizedBox(height: 10),
                  const _AlertRow(label: 'Pulse Headset X', value: '9'),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms, delay: 120.ms).slideY(begin: 0.06, end: 0);
  }
}

class _MiniPanel extends StatelessWidget {
  const _MiniPanel({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.bars,
  });

  final double width;
  final String title;
  final String subtitle;
  final List<double> bars;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.74)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars
                  .map(
                    (value) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                          height: 72 * value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.95),
                                Colors.white.withValues(alpha: 0.45),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
