import 'package:bloc/bloc.dart';

import '../../../core/models/translation_models.dart';
import '../../../core/services/project_repository.dart';

class ProjectDetailState {
  const ProjectDetailState({
    required this.projectId,
    this.bundle,
    required this.isLoading,
    this.errorMessage,
  });

  final String projectId;
  final ProjectBundle? bundle;
  final bool isLoading;
  final String? errorMessage;

  ProjectDetailState copyWith({
    ProjectBundle? bundle,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProjectDetailState(
      projectId: projectId,
      bundle: bundle ?? this.bundle,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ProjectDetailCubit extends Cubit<ProjectDetailState> {
  ProjectDetailCubit(this._repository, String projectId)
    : super(ProjectDetailState(projectId: projectId, isLoading: true));

  final ProjectRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final bundle = await _repository.loadBundle(state.projectId);
      emit(state.copyWith(bundle: bundle, isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: '$error'));
    }
  }

  Future<void> setDefaultLocale(String localeTag) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final bundle = await _repository.updateDefaultLocale(
        state.projectId,
        localeTag,
      );
      emit(state.copyWith(bundle: bundle, isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: '$error'));
    }
  }

  Future<void> addLanguage(String localeTag) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final bundle = await _repository.addLanguage(state.projectId, localeTag);
      emit(state.copyWith(bundle: bundle, isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: '$error'));
    }
  }

  Future<void> addString({
    required String key,
    required String baseValue,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final bundle = await _repository.addString(
        projectId: state.projectId,
        key: key,
        baseValue: baseValue,
      );
      emit(state.copyWith(bundle: bundle, isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: '$error'));
    }
  }

  Future<void> deleteString(String key) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final bundle = await _repository.deleteString(
        projectId: state.projectId,
        key: key,
      );
      emit(state.copyWith(bundle: bundle, isLoading: false));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: '$error'));
    }
  }
}
