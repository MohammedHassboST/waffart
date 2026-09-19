import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/locale/locale_provider.dart';
import '../../../../l10n/app_localizations.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      trailing: DropdownButton<String>(
        value: locale.languageCode,
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem(value: 'ar', child: Text(l10n.arabic)),
          DropdownMenuItem(value: 'en', child: Text(l10n.english)),
        ],
        onChanged: (v) {
          if (v != null) {
            ref.read(localeProvider.notifier).setLocale(Locale(v));
          }
        },
      ),
    );
  }
}