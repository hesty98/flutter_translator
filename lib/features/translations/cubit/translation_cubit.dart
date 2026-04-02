import 'package:bloc/bloc.dart';

import '../../../core/models/translation_models.dart';
import '../../../core/services/project_repository.dart';
import '../../../core/utils/locale_utils.dart';

class TranslationState {
  const TranslationState({
    required this.projectId,
    this.bundle,
    required this.visibleLocaleTags,
    required this.statusFilter,
    required this.searchQuery,
    required this.isLoading,
    this.errorMessage,
  });

  final String projectId;
  final ProjectBundle? bundle;
  final Set<String> visibleLocaleTags;
  final TranslationStatusFilter statusFilter;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  List<TranslationEntry> get filteredEntries {
    final bundleValue = bundle;
    if (bundleValue == null) {
      return const <TranslationEntry>[];
    }

    final visibleTargets = visibleLocaleTags.isEmpty
        ? bundleValue.languages
              .map(localeTag)
              .where((tag) => tag != bundleValue.project.defaultLocaleTag)
              .toSet()
        : visibleLocaleTags;

    final query = searchQuery.trim().toLowerCase();

    return bundleValue.entries
        .where((entry) {
          final matchesQuery =
              query.isEmpty ||
              entry.key.toLowerCase().contains(query) ||
              entry.baseValue.toLowerCase().contains(query) ||
              visibleTargets.any(
                (tag) => entry
                    .translationFor(tag)
                    .value
                    .toLowerCase()
                    .contains(query),
              );

          if (!matchesQuery) {
            return false;
          }

          if (statusFilter == TranslationStatusFilter.all) {
            return true;
          }

          return visibleTargets.any((tag) {
            final status = entry.translationFor(tag).status;
            return switch (statusFilter) {
              TranslationStatusFilter.all => true,
              TranslationStatusFilter.translated =>
                status == TranslationStatus.translated,
              TranslationStatusFilter.notTranslated =>
                status == TranslationStatus.notTranslated,
              TranslationStatusFilter.needsReview =>
                status == TranslationStatus.needsReview,
            };
          });
        })
        .toList(growable: false);
  }

  TranslationState copyWith({
    ProjectBundle? bundle,
    Set<String>? visibleLocaleTags,
    TranslationStatusFilter? statusFilter,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TranslationState(
      projectId: projectId,
      bundle: bundle ?? this.bundle,
      visibleLocaleTags: visibleLocaleTags ?? this.visibleLocaleTags,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class TranslationCubit extends Cubit<TranslationState> {
  TranslationCubit(this._repository, String projectId)
    : super(
        TranslationState(
          projectId: projectId,
          visibleLocaleTags: const <String>{},
          statusFilter: TranslationStatusFilter.all,
          searchQuery: '',
          isLoading: true,
        ),
      );

  final ProjectRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final bundle = await _repository.loadBundle(state.projectId);
      final visible = state.visibleLocaleTags.isEmpty
          ? bundle.languages
                .map(localeTag)
                .where((tag) => tag != bundle.project.defaultLocaleTag)
                .toSet()
          : state.visibleLocaleTags;
      emit(
        state.copyWith(
          bundle: bundle,
          visibleLocaleTags: visible,
          isLoading: false,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: '$error'));
    }
  }

  void toggleLocale(String localeTagValue) {
    final updated = Set<String>.from(state.visibleLocaleTags);
    if (!updated.add(localeTagValue)) {
      updated.remove(localeTagValue);
    }
    emit(state.copyWith(visibleLocaleTags: updated));
  }

  void updateStatusFilter(TranslationStatusFilter filter) {
    emit(state.copyWith(statusFilter: filter));
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> saveTranslation({
    required String localeTagValue,
    required String key,
    required String value,
  }) async {
    try {
      final bundle = await _repository.saveTranslation(
        projectId: state.projectId,
        localeTag: localeTagValue,
        key: key,
        value: value,
      );
      emit(state.copyWith(bundle: bundle));
    } catch (error) {
      emit(state.copyWith(errorMessage: '$error'));
    }
  }

  Future<void> saveStatus({
    required String localeTagValue,
    required String key,
    required TranslationStatus status,
  }) async {
    try {
      final bundle = await _repository.saveStatus(
        projectId: state.projectId,
        localeTag: localeTagValue,
        key: key,
        status: status,
      );
      emit(state.copyWith(bundle: bundle));
    } catch (error) {
      emit(state.copyWith(errorMessage: '$error'));
    }
  }

  Future<void> addString({
    required String key,
    required String baseValue,
  }) async {
    try {
      final bundle = await _repository.addString(
        projectId: state.projectId,
        key: key,
        baseValue: baseValue,
      );
      emit(state.copyWith(bundle: bundle));
    } catch (error) {
      emit(state.copyWith(errorMessage: '$error'));
    }
  }
}
