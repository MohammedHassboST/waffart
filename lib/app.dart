import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/locale/locale_provider.dart';
import 'core/offline/widgets/offline_banner.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/connection_banner.dart';
import 'l10n/app_localizations.dart';

class WaffartApp extends ConsumerWidget {
  const WaffartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Waffart',
      theme: AppTheme.light,
      darkTheme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // في builder الخاص بـ MaterialApp.router:
      builder: (context, child) {
        return Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Column(
            children: [
              const OfflineBanner(),       // ← جديد
              const ConnectionBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}