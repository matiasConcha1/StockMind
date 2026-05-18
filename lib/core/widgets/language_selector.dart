import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stockmind/core/i18n/app_strings.dart';
import 'package:stockmind/core/i18n/locale_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    this.compact = false,
    super.key,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final localeProvider = context.watch<LocaleProvider>();
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      tooltip: strings.language,
      onSelected: (value) {
        context.read<LocaleProvider>().setLanguageCode(value);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'es',
          child: Row(
            children: [
              const Text('ES'),
              const SizedBox(width: 10),
              Expanded(child: Text(strings.spanish)),
              if (localeProvider.languageCode == 'es')
                const Icon(Icons.check_rounded, size: 18),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              const Text('EN'),
              const SizedBox(width: 10),
              Expanded(child: Text(strings.english)),
              if (localeProvider.languageCode == 'en')
                const Icon(Icons.check_rounded, size: 18),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 16),
            const SizedBox(width: 8),
            Text(
              localeProvider.languageCode == 'en'
                  ? strings.english
                  : strings.spanish,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
