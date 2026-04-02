import '../models/project_record.dart';
import '../models/translation_models.dart';
import '../storage/project_storage.dart';
import 'arb_service.dart';
import 'directory_access_service.dart';

class ProjectRepository {
  ProjectRepository({
    required ProjectStorage storage,
    required ArbService arbService,
    required DirectoryAccessService directoryAccessService,
  }) : _storage = storage,
       _arbService = arbService,
       _directoryAccessService = directoryAccessService;

  final ProjectStorage _storage;
  final ArbService _arbService;
  final DirectoryAccessService _directoryAccessService;

  List<ProjectRecord> readProjects() => _storage.readProjects().toList();

  Future<List<ProjectRecord>> saveProject(ProjectRecord project) async {
    final projects = readProjects();
    final index = projects.indexWhere((item) => item.id == project.id);
    final current = index == -1 ? null : projects[index];
    final normalizedProject =
        current != null &&
            current.directoryPath == project.directoryPath &&
            current.directoryBookmark != null
        ? project.copyWith(directoryBookmark: current.directoryBookmark)
        : await _directoryAccessService.prepareProject(project);
    if (index == -1) {
      projects.add(normalizedProject);
    } else {
      projects[index] = normalizedProject;
    }
    await _storage.writeProjects(projects);
    return projects;
  }

  Future<List<ProjectRecord>> deleteProject(String projectId) async {
    final projects = readProjects()
      ..removeWhere((item) => item.id == projectId);
    await _storage.writeProjects(projects);
    return projects;
  }

  ProjectRecord? findProject(String projectId) {
    for (final project in readProjects()) {
      if (project.id == projectId) {
        return project;
      }
    }
    return null;
  }

  Future<ProjectBundle> loadBundle(String projectId) async {
    final project = findProject(projectId);
    if (project == null) {
      throw StateError('Project not found');
    }

    final bundle = await _arbService.loadProject(project);
    if (bundle.project.arbFilePrefix != project.arbFilePrefix) {
      await saveProject(bundle.project);
    }
    return bundle;
  }

  Future<ProjectBundle> updateDefaultLocale(
    String projectId,
    String localeTag,
  ) async {
    final project = findProject(projectId);
    if (project == null) {
      throw StateError('Project not found');
    }

    final updated = project.copyWith(defaultLocaleTag: localeTag);
    await saveProject(updated);
    return _arbService.loadProject(updated);
  }

  Future<ProjectBundle> addLanguage(String projectId, String localeTag) async {
    final project = findProject(projectId);
    if (project == null) {
      throw StateError('Project not found');
    }

    await _arbService.addLanguage(project: project, localeTag: localeTag);
    return _arbService.loadProject(project);
  }

  Future<ProjectBundle> saveTranslation({
    required String projectId,
    required String localeTag,
    required String key,
    required String value,
  }) async {
    final project = findProject(projectId);
    if (project == null) {
      throw StateError('Project not found');
    }

    await _arbService.saveTranslation(
      project: project,
      localeTag: localeTag,
      key: key,
      value: value,
    );
    return _arbService.loadProject(project);
  }

  Future<ProjectBundle> saveStatus({
    required String projectId,
    required String localeTag,
    required String key,
    required TranslationStatus status,
  }) async {
    final project = findProject(projectId);
    if (project == null) {
      throw StateError('Project not found');
    }

    await _arbService.saveStatus(
      project: project,
      localeTag: localeTag,
      key: key,
      status: status,
    );
    return _arbService.loadProject(project);
  }

  Future<ProjectBundle> addString({
    required String projectId,
    required String key,
    required String baseValue,
  }) async {
    final project = findProject(projectId);
    if (project == null) {
      throw StateError('Project not found');
    }

    await _arbService.addString(
      project: project,
      key: key,
      baseValue: baseValue,
    );
    return _arbService.loadProject(project);
  }

  Future<ProjectBundle> deleteString({
    required String projectId,
    required String key,
  }) async {
    final project = findProject(projectId);
    if (project == null) {
      throw StateError('Project not found');
    }

    await _arbService.deleteString(project: project, key: key);
    return _arbService.loadProject(project);
  }
}
