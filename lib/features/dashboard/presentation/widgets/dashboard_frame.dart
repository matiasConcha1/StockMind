import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:stockmind/core/widgets/app_header.dart';

class DashboardFrame extends StatelessWidget {
  const DashboardFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = width < 768;
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    final verticalPadding = isMobile ? 12.0 : 24.0;
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
              AppHeader(
                title: title,
                subtitle: subtitle,
                actions: actions,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: child.animate().fadeIn(duration: 320.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
