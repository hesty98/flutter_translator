import 'package:bloc/bloc.dart';

import '../../../core/models/project_record.dart';
import '../../../core/services/project_repository.dart';

class ProjectsState {
  const ProjectsState({
    required this.projects,
    required this.isLoading,
    this.errorMessage,
  });

  const ProjectsState.initial()
    : projects = const <ProjectRecord>[],
      isLoading = true,
      errorMessage = null;

  final List<ProjectRecord> projects;
  final bool isLoading;
  final String? errorMessage;

  ProjectsState copyWith({
    List<ProjectRecord>? projects,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ProjectsCubit extends Cubit<ProjectsState> {
  ProjectsCubit(this._repository) : super(const ProjectsState.initial());

  final ProjectRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final projects = _repository.readProjects()
        ..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      emit(state.copyWith(projects: projects, isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: '$error'));
    }
  }

  Future<void> saveProject(ProjectRecord project) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final projects = await _repository.saveProject(project)
        ..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      emit(state.copyWith(projects: projects, isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: '$error'));
    }
  }

  Future<void> removeProject(String projectId) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final projects = await _repository.deleteProject(projectId)
        ..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      emit(state.copyWith(projects: projects, isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: '$error'));
    }
  }
}
