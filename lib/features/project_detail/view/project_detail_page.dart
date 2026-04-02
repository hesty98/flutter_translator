import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/router/app_router.dart';
import '../../../core/services/project_repository.dart';
import '../../../core/utils/locale_utils.dart';
import '../../../core/widgets/locale_badge.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/view/add_string_dialog.dart';
import '../cubit/project_detail_cubit.dart';

@RoutePage()
class ProjectDetailPage extends HookWidget {
  const ProjectDetailPage({
    @PathParam('projectId') required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProjectDetailCubit(getIt<ProjectRepository>(), projectId)..load(),
      child: const _ProjectDetailView(),
    );
  }
}

class _ProjectDetailView extends HookWidget {
  const _ProjectDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ProjectDetailCubit>();

    Future<void> addLanguage() async {
      final controller = TextEditingController();
      final localeTagValue = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.addLanguage),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l10n.languageCode),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        ),
      );
      if (localeTagValue != null &&
          localeTagValue.isNotEmpty &&
          context.mounted) {
        await cubit.addLanguage(localeTagValue);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.languageAdded)));
        }
      }
    }

    Future<void> addString() async {
      final result = await showAddStringDialog(
        context: context,
        l10n: l10n,
        existingKeys:
            cubit.state.bundle?.entries.map((entry) => entry.key).toSet() ??
            const <String>{},
      );

      if (result != null && context.mounted) {
        await cubit.addString(key: result.$1, baseValue: result.$2);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.stringAdded)));
        }
      }
    }

    return BlocBuilder<ProjectDetailCubit, ProjectDetailState>(
      builder: (context, state) {
        final bundle = state.bundle;

        return PageScaffold(
          title: bundle?.project.title ?? l10n.projectDetails,
          onBack: () => context.router.maybePop(),
          actions: [
            IconButton(
              tooltip: l10n.addLanguage,
              onPressed: addLanguage,
              icon: const Icon(Icons.language_outlined),
            ),
          ],
          body: state.isLoading && bundle == null
              ? const Center(child: CircularProgressIndicator())
              : bundle == null
              ? Center(
                  child: Text(state.errorMessage ?? l10n.projectPathMissing),
                )
              : ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Wrap(
                          runSpacing: 16,
                          spacing: 24,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 280,
                              child: DropdownButtonFormField<String>(
                                initialValue: bundle.project.defaultLocaleTag,
                                items: bundle.languages
                                    .map(
                                      (locale) => DropdownMenuItem(
                                        value: localeTag(locale),
                                        child: Text(localeTag(locale)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    cubit.setDefaultLocale(value);
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: l10n.defaultLanguage,
                                ),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => context.router.push(
                                TranslationRoute(projectId: bundle.project.id),
                              ),
                              icon: const Icon(Icons.edit_note_outlined),
                              label: Text(l10n.openTranslations),
                            ),
                            FilledButton.icon(
                              onPressed: addString,
                              icon: const Icon(Icons.add),
                              label: Text(l10n.addString),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (bundle.languages.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(l10n.noLanguages),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: bundle.languages.map((locale) {
                          final localeTagValue = localeTag(locale);
                          final completion =
                              bundle.completionByLocale[localeTagValue] ?? 0;
                          return SizedBox(
                            width: 280,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 12,
                                  children: [
                                    LocaleBadge(localeTagValue: localeTagValue),
                                    Text(
                                      '${(completion * 100).round()}%',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                    ),
                                    LinearProgressIndicator(value: completion),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
