import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

Future<(String, String)?> showAddStringDialog({
  required BuildContext context,
  required AppLocalizations l10n,
  required Set<String> existingKeys,
}) async {
  final keyController = TextEditingController();
  final baseValueController = TextEditingController();
  String? validationMessage;

  return showDialog<(String, String)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.addString),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              TextField(
                controller: keyController,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.stringKeyLabel),
              ),
              TextField(
                controller: baseValueController,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(labelText: l10n.baseValueLabel),
              ),
              if (validationMessage != null)
                Text(
                  validationMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final key = keyController.text.trim();
              if (key.isEmpty) {
                setState(() => validationMessage = l10n.stringKeyRequired);
                return;
              }

              if (existingKeys.contains(key)) {
                setState(() => validationMessage = l10n.stringExists);
                return;
              }

              Navigator.of(context).pop((key, baseValueController.text.trim()));
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
}
