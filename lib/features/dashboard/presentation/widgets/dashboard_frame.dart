import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/app_header.dart';

class DashboardFrame extends StatelessWidget {
  const DashboardFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    this.onBackPressed,
    this.backLabel,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBackPressed;
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isMobile = width < 768;
    final horizontalPadding = isMobile ? 14.0 : 24.0;
    final verticalPadding = isMobile ? 10.0 : 24.0;
    final bottomPadding = width < 768
        ? (mediaQuery.padding.bottom + 92)
        : verticalPadding;

    return SafeArea(
      child: Builder(
        builder: (context) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 16 : 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.82 : 0.96,
                      ),
                      theme.colorScheme.surface.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.72 : 0.90,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.95),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.20 : 0.08,
                      ),
                      blurRadius: 34,
                      spreadRadius: -18,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: AppTheme.brand.withValues(alpha: 0.06),
                      blurRadius: 26,
                      spreadRadius: -18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: AppHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                  onBackPressed: onBackPressed,
                  backLabel: backLabel,
                ),
              ),
              SizedBox(height: isMobile ? 18 : 24),
              SizedBox(
                width: double.infinity,
                child: child
                    .animate()
                    .fadeIn(duration: 320.ms)
                    .slideY(begin: 0.015, end: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
