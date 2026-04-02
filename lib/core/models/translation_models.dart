import 'package:flutter/material.dart';

import 'project_record.dart';

enum TranslationStatus { translated, notTranslated, needsReview }

enum TranslationStatusFilter { all, translated, notTranslated, needsReview }

class ProjectBundle {
  const ProjectBundle({
    required this.project,
    required this.languages,
    required this.entries,
  });

  final ProjectRecord project;
  final List<Locale> languages;
  final List<TranslationEntry> entries;

  Map<String, double> get completionByLocale {
    final total = entries.length;
    final result = <String, double>{};

    for (final locale in languages) {
      final localeTag = locale.toLanguageTag().replaceAll('-', '_');
      if (localeTag == project.defaultLocaleTag) {
        result[localeTag] = 1;
        continue;
      }

      if (total == 0) {
        result[localeTag] = 0;
        continue;
      }

      final translatedCount = entries.where((entry) {
        return entry.translationFor(localeTag).status ==
            TranslationStatus.translated;
      }).length;
      result[localeTag] = translatedCount / total;
    }

    return result;
  }
}

class TranslationEntry {
  const TranslationEntry({
    required this.key,
    required this.baseValue,
    required this.translations,
  });

  final String key;
  final String baseValue;
  final Map<String, LocalizedTranslation> translations;

  LocalizedTranslation translationFor(String localeTag) {
    return translations[localeTag] ?? const LocalizedTranslation.empty();
  }
}

class LocalizedTranslation {
  const LocalizedTranslation({
    required this.value,
    required this.status,
    this.metadata = const <String, dynamic>{},
  });

  const LocalizedTranslation.empty()
    : value = '',
      status = TranslationStatus.notTranslated,
      metadata = const <String, dynamic>{};

  final String value;
  final TranslationStatus status;
  final Map<String, dynamic> metadata;
}
