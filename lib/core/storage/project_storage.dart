import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/project_record.dart';
import '../models/whiteboard/whiteboard_models.dart';

class ProjectStorage {
  static const _projectsKey = 'projects';
  static const _themeModeKey = 'theme_mode';
  static const _whiteboardDocumentKey = 'whiteboard_document';

  late final SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  List<ProjectRecord> readProjects() {
    final rawProjects = _preferences.getStringList(_projectsKey) ?? <String>[];
    return rawProjects.map(ProjectRecord.fromJson).toList(growable: false);
  }

  Future<void> writeProjects(List<ProjectRecord> projects) {
    return _preferences.setStringList(
      _projectsKey,
      projects.map((project) => project.toJson()).toList(),
    );
  }

  ThemeMode readThemeMode() {
    final rawMode = _preferences.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == rawMode,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> writeThemeMode(ThemeMode mode) {
    return _preferences.setString(_themeModeKey, mode.name);
  }

  WhiteboardDocument? readWhiteboardDocument() {
    final rawValue = _preferences.getString(_whiteboardDocumentKey);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    return WhiteboardDocument.fromJson(rawValue);
  }

  Future<void> writeWhiteboardDocument(WhiteboardDocument document) {
    return _preferences.setString(_whiteboardDocumentKey, document.toJson());
  }
}
