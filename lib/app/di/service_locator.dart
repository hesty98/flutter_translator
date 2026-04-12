import 'package:get_it/get_it.dart';

import '../../core/services/app_settings_service.dart';
import '../../core/services/arb_service.dart';
import '../../core/services/directory_access_service.dart';
import '../../core/services/directory_picker_service.dart';
import '../../core/services/project_repository.dart';
import '../../core/services/whiteboard_repository.dart';
import '../../core/storage/project_storage.dart';
import '../router/app_router.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final storage = ProjectStorage();
  await storage.init();

  final settingsService = AppSettingsService(storage);
  await settingsService.init();

  getIt
    ..registerSingleton<ProjectStorage>(storage)
    ..registerSingleton<AppSettingsService>(settingsService)
    ..registerLazySingleton<DirectoryPickerService>(DirectoryPickerService.new)
    ..registerLazySingleton<DirectoryAccessService>(DirectoryAccessService.new)
    ..registerLazySingleton<ArbService>(
      () => ArbService(getIt<DirectoryAccessService>()),
    )
    ..registerLazySingleton<ProjectRepository>(
      () => ProjectRepository(
        storage: getIt<ProjectStorage>(),
        arbService: getIt<ArbService>(),
        directoryAccessService: getIt<DirectoryAccessService>(),
      ),
    )
    ..registerLazySingleton<WhiteboardRepository>(
      () => WhiteboardRepository(getIt<ProjectStorage>()),
    )
    ..registerLazySingleton<AppRouter>(AppRouter.new);
}
