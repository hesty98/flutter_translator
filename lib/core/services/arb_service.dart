import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/project_record.dart';
import '../models/translation_models.dart';
import 'directory_access_service.dart';

class ArbService {
  ArbService(this._directoryAccessService);

  final DirectoryAccessService _directoryAccessService;

  Future<ProjectBundle> loadProject(ProjectRecord project) {
    return _directoryAccessService.withProjectDirectoryAccess(project, (
      directory,
    ) async {
      if (!await directory.exists()) {
        return ProjectBundle(
          project: project,
          languages: <Locale>[],
          entries: <TranslationEntry>[],
        );
      }

      final entities = await directory.list().toList();
      final localeFiles = <String, File>{};
      var prefix = project.arbFilePrefix;

      for (final entity in entities) {
        if (entity is! File || !entity.path.endsWith('.arb')) {
          continue;
        }

        final basename = p.basenameWithoutExtension(entity.path);
        final separatorIndex = basename.lastIndexOf('_');
        if (separatorIndex <= 0 || separatorIndex == basename.length - 1) {
          continue;
        }

        prefix = basename.substring(0, separatorIndex);
        final localeTag = basename.substring(separatorIndex + 1);
        localeFiles[localeTag] = entity;
      }

      final normalizedProject = project.copyWith(arbFilePrefix: prefix);
      final localeTags = SplayTreeSet<String>.from(localeFiles.keys)
        ..add(normalizedProject.defaultLocaleTag);
      final localeJson = <String, Map<String, dynamic>>{};

      for (final localeTag in localeTags) {
        final file = localeFiles[localeTag];
        localeJson[localeTag] = file == null
            ? <String, dynamic>{}
            : await _readArbFile(file);
      }

      final baseJson =
          localeJson[normalizedProject.defaultLocaleTag] ?? <String, dynamic>{};
      final sortedKeys = SplayTreeSet<String>.from(
        baseJson.keys.where((key) => !key.startsWith('@')),
      );

      for (final json in localeJson.values) {
        sortedKeys.addAll(json.keys.where((key) => !key.startsWith('@')));
      }

      final entries = sortedKeys
          .map((key) {
            final translations = <String, LocalizedTranslation>{};
            for (final localeTag in localeTags) {
              final json = localeJson[localeTag] ?? <String, dynamic>{};
              final value = json[key] as String? ?? '';
              final metadata =
                  (json['@$key'] as Map?)?.cast<String, dynamic>() ??
                  <String, dynamic>{};
              final status = value.trim().isEmpty
                  ? TranslationStatus.notTranslated
                  : metadata['x_status'] == 'needsReview'
                  ? TranslationStatus.needsReview
                  : TranslationStatus.translated;

              translations[localeTag] = LocalizedTranslation(
                value: value,
                status: status,
                metadata: metadata,
              );
            }

            return TranslationEntry(
              key: key,
              baseValue: baseJson[key] as String? ?? '',
              translations: translations,
            );
          })
          .toList(growable: false);

      return ProjectBundle(
        project: normalizedProject,
        languages: localeTags.map(_localeFromTag).toList(growable: false),
        entries: entries,
      );
    });
  }

  Future<void> addLanguage({
    required ProjectRecord project,
    required String localeTag,
  }) async {
    await _directoryAccessService.withProjectDirectoryAccess(project, (
      directory,
    ) async {
      final file = File(
        p.join(directory.path, '${project.arbFilePrefix}_$localeTag.arb'),
      );
      if (await file.exists()) {
        return;
      }

      await file.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent(
          '  ',
        ).convert(LinkedHashMap<String, dynamic>.from({'@@locale': localeTag})),
      );
    });
  }

  Future<void> saveTranslation({
    required ProjectRecord project,
    required String localeTag,
    required String key,
    required String value,
  }) async {
    await _directoryAccessService.withProjectDirectoryAccess(project, (
      directory,
    ) async {
      final file = File(
        p.join(directory.path, '${project.arbFilePrefix}_$localeTag.arb'),
      );
      final json = await _readArbFile(file);
      json[key] = value;

      final metadata =
          (json['@$key'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      if (value.trim().isEmpty) {
        metadata.remove('x_status');
      } else if (metadata['x_status'] == null) {
        metadata['x_status'] = 'translated';
      }

      if (metadata.isEmpty) {
        json.remove('@$key');
      } else {
        json['@$key'] = metadata;
      }

      await _writeSorted(file: file, localeTag: localeTag, data: json);
    });
  }

  Future<void> saveStatus({
    required ProjectRecord project,
    required String localeTag,
    required String key,
    required TranslationStatus status,
  }) async {
    await _directoryAccessService.withProjectDirectoryAccess(project, (
      directory,
    ) async {
      final file = File(
        p.join(directory.path, '${project.arbFilePrefix}_$localeTag.arb'),
      );
      final json = await _readArbFile(file);
      final metadata =
          (json['@$key'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      if (status == TranslationStatus.notTranslated) {
        metadata.remove('x_status');
      } else {
        metadata['x_status'] = status == TranslationStatus.needsReview
            ? 'needsReview'
            : 'translated';
      }

      if (metadata.isEmpty) {
        json.remove('@$key');
      } else {
        json['@$key'] = metadata;
      }

      await _writeSorted(file: file, localeTag: localeTag, data: json);
    });
  }

  Future<void> addString({
    required ProjectRecord project,
    required String key,
    required String baseValue,
  }) async {
    await _directoryAccessService.withProjectDirectoryAccess(project, (
      directory,
    ) async {
      final bundle = await loadProject(project);
      final localeTags = bundle.languages.map((locale) {
        final countryCode = locale.countryCode;
        return countryCode == null || countryCode.isEmpty
            ? locale.languageCode
            : '${locale.languageCode}_$countryCode';
      }).toSet()..add(project.defaultLocaleTag);

      for (final localeTag in localeTags) {
        final file = File(
          p.join(directory.path, '${project.arbFilePrefix}_$localeTag.arb'),
        );
        final json = await _readArbFile(file);
        json.putIfAbsent(
          key,
          () => localeTag == project.defaultLocaleTag ? baseValue : '',
        );
        await _writeSorted(file: file, localeTag: localeTag, data: json);
      }
    });
  }

  Future<void> deleteString({
    required ProjectRecord project,
    required String key,
  }) async {
    await _directoryAccessService.withProjectDirectoryAccess(project, (
      directory,
    ) async {
      final bundle = await loadProject(project);
      final localeTags = bundle.languages.map((locale) {
        final countryCode = locale.countryCode;
        return countryCode == null || countryCode.isEmpty
            ? locale.languageCode
            : '${locale.languageCode}_$countryCode';
      }).toSet()..add(project.defaultLocaleTag);

      for (final localeTag in localeTags) {
        final file = File(
          p.join(directory.path, '${project.arbFilePrefix}_$localeTag.arb'),
        );
        final json = await _readArbFile(file);
        json.remove(key);
        json.remove('@$key');
        await _writeSorted(file: file, localeTag: localeTag, data: json);
      }
    });
  }

  Future<Map<String, dynamic>> _readArbFile(File file) async {
    if (!await file.exists()) {
      return <String, dynamic>{};
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return <String, dynamic>{};
    }

    return (jsonDecode(content) as Map).cast<String, dynamic>();
  }

  Future<void> _writeSorted({
    required File file,
    required String localeTag,
    required Map<String, dynamic> data,
  }) async {
    final output = <String, dynamic>{'@@locale': localeTag};
    final keys = SplayTreeSet<String>.from(
      data.keys.where((key) => !key.startsWith('@')),
    );

    for (final key in keys) {
      output[key] = data[key] ?? '';
      if (data.containsKey('@$key')) {
        output['@$key'] = data['@$key'];
      }
    }

    await file.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(output),
    );
  }
}

Locale _localeFromTag(String tag) {
  final parts = tag.replaceAll('-', '_').split('_');
  return parts.length == 1
      ? Locale(parts.first)
      : Locale(parts.first, parts[1]);
}
