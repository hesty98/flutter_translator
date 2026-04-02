import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../core/services/app_settings_service.dart';
import '../l10n/app_localizations.dart';
import 'di/service_locator.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class FlutterTranslatorApp extends HookWidget {
  const FlutterTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = getIt<AppRouter>();
    final settingsService = getIt<AppSettingsService>();
    final themeMode = useValueListenable(settingsService.themeModeListenable);

    return MaterialApp.router(
      title: 'Flutter Translator',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router.config(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
