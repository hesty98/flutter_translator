// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [IconPickerPage]
class IconPickerRoute extends PageRouteInfo<void> {
  const IconPickerRoute({List<PageRouteInfo>? children})
    : super(IconPickerRoute.name, initialChildren: children);

  static const String name = 'IconPickerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const IconPickerPage();
    },
  );
}

/// generated route for
/// [ProjectDetailPage]
class ProjectDetailRoute extends PageRouteInfo<ProjectDetailRouteArgs> {
  ProjectDetailRoute({
    required String projectId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         ProjectDetailRoute.name,
         args: ProjectDetailRouteArgs(projectId: projectId, key: key),
         rawPathParams: {'projectId': projectId},
         initialChildren: children,
       );

  static const String name = 'ProjectDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ProjectDetailRouteArgs>(
        orElse: () => ProjectDetailRouteArgs(
          projectId: pathParams.getString('projectId'),
        ),
      );
      return ProjectDetailPage(projectId: args.projectId, key: args.key);
    },
  );
}

class ProjectDetailRouteArgs {
  const ProjectDetailRouteArgs({required this.projectId, this.key});

  final String projectId;

  final Key? key;

  @override
  String toString() {
    return 'ProjectDetailRouteArgs{projectId: $projectId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProjectDetailRouteArgs) return false;
    return projectId == other.projectId && key == other.key;
  }

  @override
  int get hashCode => projectId.hashCode ^ key.hashCode;
}

/// generated route for
/// [ProjectsPage]
class ProjectsRoute extends PageRouteInfo<void> {
  const ProjectsRoute({List<PageRouteInfo>? children})
    : super(ProjectsRoute.name, initialChildren: children);

  static const String name = 'ProjectsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProjectsPage();
    },
  );
}

/// generated route for
/// [TranslationPage]
class TranslationRoute extends PageRouteInfo<TranslationRouteArgs> {
  TranslationRoute({
    required String projectId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         TranslationRoute.name,
         args: TranslationRouteArgs(projectId: projectId, key: key),
         rawPathParams: {'projectId': projectId},
         initialChildren: children,
       );

  static const String name = 'TranslationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TranslationRouteArgs>(
        orElse: () =>
            TranslationRouteArgs(projectId: pathParams.getString('projectId')),
      );
      return TranslationPage(projectId: args.projectId, key: args.key);
    },
  );
}

class TranslationRouteArgs {
  const TranslationRouteArgs({required this.projectId, this.key});

  final String projectId;

  final Key? key;

  @override
  String toString() {
    return 'TranslationRouteArgs{projectId: $projectId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TranslationRouteArgs) return false;
    return projectId == other.projectId && key == other.key;
  }

  @override
  int get hashCode => projectId.hashCode ^ key.hashCode;
}

/// generated route for
/// [WhiteboardPage]
class WhiteboardRoute extends PageRouteInfo<void> {
  const WhiteboardRoute({List<PageRouteInfo>? children})
    : super(WhiteboardRoute.name, initialChildren: children);

  static const String name = 'WhiteboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const WhiteboardPage();
    },
  );
}
