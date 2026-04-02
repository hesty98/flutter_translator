import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../app/di/service_locator.dart';
import '../../../core/models/project_record.dart';
import '../../../core/services/directory_picker_service.dart';
import '../../../l10n/app_localizations.dart';

class ProjectEditorDialog extends HookWidget {
  const ProjectEditorDialog({super.key, this.project});

  final ProjectRecord? project;

  static String pathForLife = "";

  ///Users/linus/Documents/Projekte/Life/server/life_copilot/lib/l10n";
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = useTextEditingController(
      text: project?.title ?? 'Life',
    );
    final pathController = useTextEditingController(
      text: project?.directoryPath ?? pathForLife,
    );
    final localeController = useTextEditingController(
      text: project?.defaultLocaleTag ?? 'en',
    );
    final bookmark = useState<String?>(project?.directoryBookmark);
    final validationMessage = useState<String?>(null);
    final directoryPicker = getIt<DirectoryPickerService>();

    Future<void> chooseDirectory() async {
      final selected = await directoryPicker.pickProjectDirectory();
      if (selected != null && context.mounted) {
        pathController.text = selected.path;
        bookmark.value = selected.bookmark;
      }
    }

    void submit() {
      if (titleController.text.trim().isEmpty) {
        validationMessage.value = l10n.titleRequired;
        return;
      }
      if (pathController.text.trim().isEmpty) {
        validationMessage.value = l10n.directoryRequired;
        return;
      }
      if (localeController.text.trim().isEmpty) {
        validationMessage.value = l10n.languageRequired;
        return;
      }

      Navigator.of(context).pop(
        ProjectRecord(
          id: project?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          title: titleController.text.trim(),
          directoryPath: pathController.text.trim(),
          defaultLocaleTag: localeController.text.trim(),
          arbFilePrefix: project?.arbFilePrefix ?? 'app',
          directoryBookmark: bookmark.value,
        ),
      );
    }

    return AlertDialog(
      title: Text(project == null ? l10n.addProject : l10n.editProject),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: l10n.projectTitleLabel),
            ),
            TextField(
              controller: pathController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: l10n.projectDirectoryLabel,
                suffixIcon: IconButton(
                  onPressed: () {
                    chooseDirectory();
                  },
                  icon: const Icon(Icons.folder_open_outlined),
                ),
              ),
            ),
            TextField(
              controller: localeController,
              decoration: InputDecoration(labelText: l10n.defaultLanguage),
            ),
            if (validationMessage.value != null)
              Text(
                validationMessage.value!,
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
        FilledButton.icon(
          onPressed: submit,
          icon: const Icon(Icons.save_outlined),
          label: Text(l10n.save),
        ),
      ],
    );
  }
}
