import 'package:flutter/material.dart';

import '../../../core/models/translation_models.dart';
import '../../../core/widgets/locale_badge.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../l10n/app_localizations.dart';
import 'editable_translation_field.dart';

class TranslationTableRow extends StatelessWidget {
  const TranslationTableRow({
    required this.entry,
    required this.baseLocaleTag,
    required this.visibleLocaleTags,
    required this.onSaveTranslation,
    required this.onChangeStatus,
    super.key,
  });

  final TranslationEntry entry;
  final String baseLocaleTag;
  final List<String> visibleLocaleTags;
  final void Function(String localeTagValue, String value) onSaveTranslation;
  final void Function(String localeTagValue, TranslationStatus status)
  onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translatedCount = visibleLocaleTags.where((localeTagValue) {
      return entry.translationFor(localeTagValue).status ==
          TranslationStatus.translated;
    }).length;
    final completion = visibleLocaleTags.isEmpty
        ? 1.0
        : translatedCount / visibleLocaleTags.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SelectableText(
                  entry.key,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(completion * 100).round()}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: completion),
                    const SizedBox(height: 8),
                    Text(
                      '$translatedCount / ${visibleLocaleTags.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LanguageEditor(
                    localeTagValue: baseLocaleTag,
                    label: '${l10n.baseLanguage} • $baseLocaleTag',
                    value: entry.translationFor(baseLocaleTag).value.isEmpty
                        ? entry.baseValue
                        : entry.translationFor(baseLocaleTag).value,
                    status: entry.translationFor(baseLocaleTag).status,
                    onSaveTranslation: onSaveTranslation,
                    onChangeStatus: onChangeStatus,
                    isBaseLanguage: true,
                  ),
                  const SizedBox(height: 12),
                  ...visibleLocaleTags.map(
                    (localeTagValue) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LanguageEditor(
                        localeTagValue: localeTagValue,
                        label: localeTagValue,
                        value: entry.translationFor(localeTagValue).value,
                        status: entry.translationFor(localeTagValue).status,
                        onSaveTranslation: onSaveTranslation,
                        onChangeStatus: onChangeStatus,
                        isBaseLanguage: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageEditor extends StatelessWidget {
  const _LanguageEditor({
    required this.localeTagValue,
    required this.label,
    required this.value,
    required this.status,
    required this.onSaveTranslation,
    required this.onChangeStatus,
    required this.isBaseLanguage,
  });

  final String localeTagValue;
  final String label;
  final String value;
  final TranslationStatus status;
  final void Function(String localeTagValue, String value) onSaveTranslation;
  final void Function(String localeTagValue, TranslationStatus status)
  onChangeStatus;
  final bool isBaseLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LocaleBadge(localeTagValue: localeTagValue),
                const SizedBox(width: 8),
                StatusChip(status: status),
                const Spacer(),
                if (!isBaseLanguage)
                  PopupMenuButton<TranslationStatus>(
                    onSelected: (nextStatus) =>
                        onChangeStatus(localeTagValue, nextStatus),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: TranslationStatus.translated,
                        child: Text(l10n.translated),
                      ),
                      PopupMenuItem(
                        value: TranslationStatus.notTranslated,
                        child: Text(l10n.notTranslated),
                      ),
                      PopupMenuItem(
                        value: TranslationStatus.needsReview,
                        child: Text(l10n.needsReview),
                      ),
                    ],
                    icon: const Icon(Icons.more_horiz),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            EditableTranslationField(
              value: value,
              label: label,
              onSave: (nextValue) =>
                  onSaveTranslation(localeTagValue, nextValue),
            ),
          ],
        ),
      ),
    );
  }
}
