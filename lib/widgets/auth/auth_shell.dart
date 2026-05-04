import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:stockmind/core/utils/responsive.dart';
import 'package:stockmind/widgets/common/stockmind_logo.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.cardChild,
    required this.title,
    required this.subtitle,
  });

  final Widget cardChild;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF0B1120), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              left: -80,
              child: _GlowOrb(
                size: 320,
                colors: [Color(0xFF1D4ED8), Color(0x001D4ED8)],
              ),
            ),
            const Positioned(
              bottom: -180,
              right: -80,
              child: _GlowOrb(
                size: 360,
                colors: [Color(0xFF0891B2), Color(0x000891B2)],
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: isMobile
                        ? _MobileAuthLayout(
                            title: title,
                            subtitle: subtitle,
                            cardChild: cardChild,
                          )
                        : _DesktopAuthLayout(
                            title: title,
                            subtitle: subtitle,
                            cardChild: cardChild,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopAuthLayout extends StatelessWidget {
  const _DesktopAuthLayout({
    required this.title,
    required this.subtitle,
    required this.cardChild,
  });

  final String title;
  final String subtitle;
  final Widget cardChild;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          flex: 12,
          child: Padding(
            padding: EdgeInsets.only(right: 36),
            child: _BrandShowcase(),
          ),
        ),
        Expanded(
          flex: 9,
          child: _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const StockMindLogo(showSubtitle: true),
                const SizedBox(height: 28),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF94A3B8),
                      ),
                ),
                const SizedBox(height: 30),
                cardChild,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileAuthLayout extends StatelessWidget {
  const _MobileAuthLayout({
    required this.title,
    required this.subtitle,
    required this.cardChild,
  });

  final String title;
  final String subtitle;
  final Widget cardChild;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: StockMindLogo(compact: true)),
            const SizedBox(height: 28),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
            ),
            const SizedBox(height: 28),
            cardChild,
          ],
        ),
      ),
    );
  }
}

class _BrandShowcase extends StatelessWidget {
  const _BrandShowcase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StockMindLogo(bright: true),
        const SizedBox(height: 28),
        Text(
          'Inventario inteligente para equipos que operan con precisión.',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Centraliza productos, alertas y movimientos en una experiencia SaaS clara, rápida y confiable.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF94A3B8),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        const Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _BenefitChip(
                icon: Icons.flash_on_rounded, label: 'Alertas en tiempo real'),
            _BenefitChip(
                icon: Icons.shield_rounded, label: 'Control operacional'),
            _BenefitChip(icon: Icons.devices_rounded, label: 'Web y mobile'),
          ],
        ),
        const SizedBox(height: 34),
        const _MockupBoard(),
      ],
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x141E40AF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF93C5FD), size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _MockupBoard extends StatelessWidget {
  const _MockupBoard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33020317),
            blurRadius: 40,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _mockStat('98.4%', 'Disponibilidad'),
              const SizedBox(width: 14),
              _mockStat('24', 'Alertas activas'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 220,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xCC0F172A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vista operativa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      _MockBar(height: 72, color: Color(0xFF1D4ED8)),
                      _MockBar(height: 118, color: Color(0xFF38BDF8)),
                      _MockBar(height: 98, color: Color(0xFF2563EB)),
                      _MockBar(height: 142, color: Color(0xFF60A5FA)),
                      _MockBar(height: 110, color: Color(0xFF0EA5E9)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1220),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.76,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xCC0F172A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockBar extends StatelessWidget {
  const _MockBar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.7), color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xC0141B2D),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66020317),
                blurRadius: 48,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
