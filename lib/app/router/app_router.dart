import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import '../../features/icons/view/icon_picker_page.dart';
import '../../features/project_detail/view/project_detail_page.dart';
import '../../features/projects/view/projects_page.dart';
import '../../features/translations/view/translation_page.dart';
import '../../features/whiteboard/view/whiteboard_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: ProjectsRoute.page, path: '/'),
    AutoRoute(page: IconPickerRoute.page, path: '/icons'),
    AutoRoute(page: WhiteboardRoute.page, path: '/whiteboard'),
    AutoRoute(page: ProjectDetailRoute.page, path: '/project/:projectId'),
    AutoRoute(
      page: TranslationRoute.page,
      path: '/project/:projectId/translations',
    ),
  ];
}
