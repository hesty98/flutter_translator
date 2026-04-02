import 'package:flutter/material.dart';

import '../storage/project_storage.dart';

class AppSettingsService {
  AppSettingsService(this._storage);

  final ProjectStorage _storage;
  final ValueNotifier<ThemeMode> themeModeListenable = ValueNotifier(
    ThemeMode.system,
  );

  Future<void> init() async {
    themeModeListenable.value = _storage.readThemeMode();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    themeModeListenable.value = mode;
    await _storage.writeThemeMode(mode);
  }
}
