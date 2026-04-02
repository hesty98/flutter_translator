import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../app/di/service_locator.dart';
import '../../../core/models/translation_models.dart';
import '../../../core/services/project_repository.dart';
import '../../../core/utils/locale_utils.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/view/add_string_dialog.dart';
import '../cubit/translation_cubit.dart';
import '../widgets/translation_table_row.dart';

@RoutePage()
class TranslationPage extends HookWidget {
  const TranslationPage({
    @PathParam('projectId') required this.projectId,
    super.key,
  });

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TranslationCubit(getIt<ProjectRepository>(), projectId)..load(),
      child: const _TranslationView(),
    );
  }
}

class _TranslationView extends HookWidget {
  const _TranslationView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<TranslationCubit>();
    final searchController = useTextEditingController();

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

    return BlocBuilder<TranslationCubit, TranslationState>(
      builder: (context, state) {
        final bundle = state.bundle;
        final visibleLocaleTags = state.visibleLocaleTags.toList()..sort();

        return PageScaffold(
          title: bundle?.project.title ?? l10n.translationsTitle,
          onBack: () => context.router.maybePop(),
          body: state.isLoading && bundle == null
              ? const Center(child: CircularProgressIndicator())
              : bundle == null
              ? Center(
                  child: Text(state.errorMessage ?? l10n.projectPathMissing),
                )
              : Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 16,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: searchController,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.search),
                                      hintText: l10n.searchHint,
                                    ),
                                    onChanged: cubit.updateSearchQuery,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: addString,
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.addString),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                DropdownButton<TranslationStatusFilter>(
                                  value: state.statusFilter,
                                  onChanged: (value) {
                                    if (value != null) {
                                      cubit.updateStatusFilter(value);
                                    }
                                  },
                                  items: [
                                    DropdownMenuItem(
                                      value: TranslationStatusFilter.all,
                                      child: Text(l10n.allStatuses),
                                    ),
                                    DropdownMenuItem(
                                      value: TranslationStatusFilter.translated,
                                      child: Text(l10n.translated),
                                    ),
                                    DropdownMenuItem(
                                      value:
                                          TranslationStatusFilter.notTranslated,
                                      child: Text(l10n.notTranslated),
                                    ),
                                    DropdownMenuItem(
                                      value:
                                          TranslationStatusFilter.needsReview,
                                      child: Text(l10n.needsReview),
                                    ),
                                  ],
                                ),
                                ...bundle.languages
                                    .map(localeTag)
                                    .where(
                                      (localeTagValue) =>
                                          localeTagValue !=
                                          bundle.project.defaultLocaleTag,
                                    )
                                    .map(
                                      (localeTagValue) => FilterChip(
                                        selected: state.visibleLocaleTags
                                            .contains(localeTagValue),
                                        label: Text(localeTagValue),
                                        avatar: Text(
                                          flagForLocaleTag(localeTagValue),
                                        ),
                                        onSelected: (_) =>
                                            cubit.toggleLocale(localeTagValue),
                                      ),
                                    ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: state.filteredEntries.isEmpty
                          ? Center(child: Text(l10n.emptyTranslations))
                          : Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  _TableHeader(l10n: l10n),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: state.filteredEntries.length,
                                      itemBuilder: (context, index) {
                                        final entry =
                                            state.filteredEntries[index];
                                        return TranslationTableRow(
                                          entry: entry,
                                          baseLocaleTag:
                                              bundle.project.defaultLocaleTag,
                                          visibleLocaleTags: visibleLocaleTags,
                                          onSaveTranslation:
                                              (localeTagValue, value) async {
                                                await cubit.saveTranslation(
                                                  localeTagValue:
                                                      localeTagValue,
                                                  key: entry.key,
                                                  value: value,
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        l10n.savedTranslation,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                          onChangeStatus:
                                              (localeTagValue, status) async {
                                                await cubit.saveStatus(
                                                  localeTagValue:
                                                      localeTagValue,
                                                  key: entry.key,
                                                  status: status,
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        l10n.savedStatus,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(l10n.keyLabel, style: textStyle)),
            Expanded(
              flex: 2,
              child: Text(l10n.translatedPercent, style: textStyle),
            ),
            Expanded(
              flex: 7,
              child: Text(l10n.languagesColumn, style: textStyle),
            ),
          ],
        ),
      ),
    );
  }
}
