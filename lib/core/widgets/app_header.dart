import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/app/routes.dart';
import 'package:stockmind/core/constants/app_constants.dart';
import 'package:stockmind/core/i18n/app_strings.dart';
import 'package:stockmind/core/theme/app_theme.dart';
import 'package:stockmind/core/widgets/app_alert_dialog.dart';
import 'package:stockmind/core/widgets/stockmind_brand.dart';
import 'package:stockmind/features/company/providers/current_company_provider.dart';
import 'package:universal_html/html.dart' as html;

class AppHeader extends StatelessWidget {
  static const _createWorkspaceAction = '__create_workspace__';

  const AppHeader({
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.onBackPressed,
    this.backLabel,
    this.onMenuPressed,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;
  final VoidCallback? onBackPressed;
  final String? backLabel;
  final VoidCallback? onMenuPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.strings;
    final company = context.watch<CurrentCompanyProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 1000;
    final isSmallPhone = width < 480;
    final titleStyle = (isSmallPhone
            ? theme.textTheme.headlineSmall
            : theme.textTheme.headlineMedium)
        ?.copyWith(
          fontSize: isSmallPhone ? 28 : null,
          letterSpacing: -0.8,
        );
    final subtitleStyle = (isSmallPhone
            ? theme.textTheme.bodyMedium
            : theme.textTheme.bodyLarge)
        ?.copyWith(fontSize: isSmallPhone ? 15 : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompact) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallPhone ? 14 : 16,
              vertical: isSmallPhone ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.24,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: StockMindBrandRow(
              iconSize: 24,
              subtitle: strings.smartInventoryPlatform,
            ),
          ),
          SizedBox(height: isSmallPhone ? 14 : 18),
        ],
        _buildWorkspaceSelector(context, company, theme),
        if (company.errorMessage != null && !company.isLoading) ...[
          const SizedBox(height: 12),
          _HeaderBanner(
            icon: Icons.error_outline_rounded,
            text: company.errorMessage!,
            actions: [
              TextButton(
                onPressed: company.refresh,
                child: Text(strings.retryAction),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutePaths.workspaceSetup),
                child: Text(strings.createWorkspace),
              ),
            ],
          ),
        ],
        if (company.company?.isDemoMode == true) ...[
          const SizedBox(height: 12),
          _HeaderBanner(
            icon: Icons.auto_awesome_outlined,
            text: strings.workspaceDemoBanner,
            actions: [
              TextButton.icon(
                onPressed: () => context.go(AppRoutePaths.workspaceSetup),
                icon: const Icon(Icons.add_business_outlined),
                label: Text(strings.createMyWorkspace),
              ),
              TextButton.icon(
                onPressed: () => html.window.open(
                  AppConstants.repositoryUrl,
                  '_blank',
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(strings.seeReadmeGithub),
              ),
            ],
          ),
        ],
        if (!company.hasCompany && !company.isLoading) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.go(AppRoutePaths.workspaceSetup),
              icon: const Icon(Icons.apartment_outlined),
              label: Text(strings.goToWorkspace),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBackPressed != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.tonalIcon(
                  onPressed: onBackPressed,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(backLabel ?? strings.back),
                ),
              ),
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

  Widget _buildWorkspaceSelector(
    BuildContext context,
    CurrentCompanyProvider provider,
    ThemeData theme,
  ) {
    final strings = context.strings;
    if (provider.isLoading) {
      return _buildChip(
        theme,
        label: strings.loadingWorkspace,
        badge: null,
        showChevron: false,
      );
    }

    if (provider.companies.isEmpty) {
      return FilledButton.icon(
        onPressed: () => context.go(AppRoutePaths.workspaceSetup),
        icon: const Icon(Icons.add_business_outlined),
        label: Text(strings.createWorkspaceAction),
      );
    }

    return PopupMenuButton<String>(
      tooltip: strings.changeWorkspace,
      onSelected: (value) async {
        if (value == _createWorkspaceAction) {
          await _openCreateWorkspaceDialog(context, provider);
          return;
        }
        await provider.switchCompany(value);
      },
      itemBuilder: (context) {
        return [
          ...provider.companies.map(
            (item) => PopupMenuItem<String>(
              value: item.id,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.companyName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.workspaceBadgeLabel,
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: _createWorkspaceAction,
            child: Row(
              children: [
                const Icon(Icons.add_business_outlined, size: 18),
                const SizedBox(width: 10),
                Text(strings.createWorkspaceAction),
              ],
            ),
          ),
        ];
      },
      child: _buildChip(
        theme,
        label: provider.companyName,
        badge: provider.company?.workspaceBadgeLabel,
        showChevron: true,
      ),
    );
  }

  Widget _buildChip(
    ThemeData theme, {
    required String label,
    required String? badge,
    required bool showChevron,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brand.withValues(alpha: 0.14),
            AppTheme.brandViolet.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.95),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (showChevron) ...[
            const SizedBox(width: 8),
            const Icon(Icons.unfold_more_rounded, size: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _openCreateWorkspaceDialog(
    BuildContext context,
    CurrentCompanyProvider provider,
  ) async {
    final strings = context.strings;
    final payload = await showDialog<_CreateWorkspacePayload>(
      context: context,
      builder: (_) => const _CreateWorkspaceDialog(),
    );
    if (payload == null || !context.mounted) return;
    try {
      await provider.createCompany(
        companyName: payload.workspaceName,
        industry: payload.industry,
        workspaceType: payload.workspaceType,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${payload.workspaceName} ${strings.workspaceCreatedMessage}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      await showAppAlertDialog(
        context,
        type: AppAlertType.error,
        title: strings.createWorkspaceFailedTitle,
        message: error.toString().contains('permission-denied')
            ? strings.createWorkspaceFailedMessage
            : error.toString().replaceFirst('Exception: ', '').trim(),
      );
    }
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({
    required this.icon,
    required this.text,
    required this.actions,
  });

  final IconData icon;
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          Text(text, style: theme.textTheme.titleSmall),
          ...actions,
        ],
      ),
    );
  }
}

class _CreateWorkspacePayload {
  const _CreateWorkspacePayload({
    required this.workspaceName,
    required this.industry,
    required this.workspaceType,
  });

  final String workspaceName;
  final String industry;
  final String workspaceType;
}

class _CreateWorkspaceDialog extends StatefulWidget {
  const _CreateWorkspaceDialog();

  @override
  State<_CreateWorkspaceDialog> createState() => _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends State<_CreateWorkspaceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _industryController = TextEditingController();
  String _workspaceType = 'personal';

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.strings;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 42,
                spreadRadius: -14,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.createWorkspaceTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.createWorkspaceDescription,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _workspaceType,
                  decoration: InputDecoration(
                    labelText: strings.type,
                    prefixIcon: const Icon(Icons.layers_outlined),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'personal',
                      child: Text(strings.personal),
                    ),
                    DropdownMenuItem(
                      value: 'business',
                      child: Text(strings.business),
                    ),
                    DropdownMenuItem(
                      value: 'company',
                      child: Text(strings.company),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _workspaceType = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _workspaceType == 'personal'
                        ? strings.workspaceName
                        : strings.workspaceLabel,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return strings.enterValidWorkspaceName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _industryController,
                  decoration: InputDecoration(
                    labelText: strings.optionalIndustry,
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(strings.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.add_business_outlined),
                        label: Text(strings.createWorkspace),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _CreateWorkspacePayload(
        workspaceName: _nameController.text.trim(),
        industry: _industryController.text.trim(),
        workspaceType: _workspaceType,
      ),
    );
  }
}
