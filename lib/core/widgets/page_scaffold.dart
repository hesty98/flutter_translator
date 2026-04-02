import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../l10n/app_localizations.dart';
import '../../app/di/service_locator.dart';
import '../services/app_settings_service.dart';

class PageScaffold extends HookWidget {
  const PageScaffold({
    required this.title,
    required this.body,
    super.key,
    this.actions = const <Widget>[],
    this.onBack,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsService = getIt<AppSettingsService>();

    return Scaffold(
      appBar: AppBar(
        leading: onBack == null
            ? null
            : IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        title: Text(title),
        actions: [
          PopupMenuButton<ThemeMode>(
            initialValue: settingsService.themeModeListenable.value,
            tooltip: l10n.themeMode,
            onSelected: settingsService.updateThemeMode,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text(l10n.systemTheme),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: Text(l10n.lightTheme),
              ),
              PopupMenuItem(value: ThemeMode.dark, child: Text(l10n.darkTheme)),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.palette_outlined),
            ),
          ),
          ...actions,
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(padding: const EdgeInsets.all(20), child: body),
          ),
        ),
      ),
    );
  }
}
