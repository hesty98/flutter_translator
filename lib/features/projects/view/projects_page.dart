import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../app/di/service_locator.dart';
import '../../../app/router/app_router.dart';
import '../../../core/models/project_record.dart';
import '../../../core/services/project_repository.dart';
import '../../../core/widgets/page_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import 'project_editor_dialog.dart';
import '../cubit/projects_cubit.dart';

@RoutePage()
class ProjectsPage extends HookWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProjectsCubit(getIt<ProjectRepository>())..load(),
      child: const _ProjectsView(),
    );
  }
}

class _ProjectsView extends HookWidget {
  const _ProjectsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ProjectsCubit>();

    Future<void> openEditor([ProjectRecord? project]) async {
      final result = await showDialog<ProjectRecord>(
        context: context,
        builder: (context) => ProjectEditorDialog(project: project),
      );
      if (result != null && context.mounted) {
        await cubit.saveProject(result);
      }
    }

    return BlocBuilder<ProjectsCubit, ProjectsState>(
      builder: (context, state) {
        return PageScaffold(
          title: l10n.projectsTitle,
          actions: [
            IconButton(
              tooltip: l10n.addProject,
              onPressed: () => openEditor(),
              icon: const Icon(Icons.add),
            ),
          ],
          body: state.isLoading && state.projects.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.projects.isEmpty
              ? _EmptyProjects(onCreate: () => openEditor())
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: state.projects.length,
                  itemBuilder: (context, index) {
                    final project = state.projects[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 12,
                          children: [
                            Text(
                              project.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              project.directoryPath,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton(
                                  onPressed: () => context.router.push(
                                    ProjectDetailRoute(projectId: project.id),
                                  ),
                                  child: Text(l10n.projectDetails),
                                ),
                                OutlinedButton(
                                  onPressed: () => openEditor(project),
                                  child: Text(l10n.editProject),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await cubit.removeProject(project.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.projectRemoved),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(l10n.delete),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const Icon(Icons.folder_copy_outlined, size: 42),
              Text(
                l10n.noProjects,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(l10n.noProjectsHint, textAlign: TextAlign.center),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: Text(l10n.addProject),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
