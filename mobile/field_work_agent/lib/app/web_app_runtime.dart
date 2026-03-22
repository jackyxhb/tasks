import 'package:flutter/foundation.dart';

import '../data/database/database_executor.dart';
import '../data/database/app_database.dart';
import '../data/database/web_database_executor.dart';
import '../core/storage/web_storage_service.dart';
import 'app_runtime.dart';

class WebAppShellController extends LocalAppShellController {
  WebAppShellController._({
    required AppDatabase database,
    required WebStorageService storageService,
  })  : _database = database,
        _storageService = storageService;

  final AppDatabase _database;
  final WebStorageService _storageService;

  @override
  Future<AppShellData> load() async {
    return AppShellData(
      projects: await _database.projects.listAll(),
      tasks: await _database.tasks.listAll(),
      meetings: await _database.meetings.listAll(),
      rawCaptures: await _database.rawCaptures.listAll(),
      reportRuns: await _database.reportRuns.listAll(),
      importRuns: const [],
      exportRuns: const [],
    );
  }
}

Future<WebAppShellController> createWebAppShellController() async {
  final storageService = WebStorageService();
  await storageService.initialize();

  final database = await AppDatabase.initialize(
    opener: WebDatabaseOpener(),
    migrationsDirectoryPath: '',
  );

  return WebAppShellController._(
    database: database,
    storageService: storageService,
  );
}
