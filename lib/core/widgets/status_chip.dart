import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/translation_models.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final TranslationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      TranslationStatus.translated => (l10n.translated, colorScheme.primary),
      TranslationStatus.notTranslated => (
        l10n.notTranslated,
        colorScheme.outline,
      ),
      TranslationStatus.needsReview => (l10n.needsReview, colorScheme.tertiary),
    };

    return Chip(
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      backgroundColor: color.withValues(alpha: 0.12),
      visualDensity: VisualDensity.compact,
    );
  }
}
