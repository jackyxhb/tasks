import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../bootstrap/local_database_bootstrap.dart';
import '../bootstrap/local_file_storage_bootstrap.dart';
import '../data/database/database_executor.dart';
import '../domain/entities/export_run_entity.dart';
import '../domain/entities/import_run_entity.dart';
import '../domain/entities/meeting_entity.dart';
import '../domain/entities/project_entity.dart';
import '../domain/entities/raw_capture_entity.dart';
import '../domain/entities/report_run_entity.dart';
import '../domain/entities/task_entity.dart';

abstract class AppShellController {
  Future<AppShellData> load();
}

class StaticAppShellController implements AppShellController {
  const StaticAppShellController(this.data);

  final AppShellData data;

  @override
  Future<AppShellData> load() async => data;
}

class LocalAppShellController implements AppShellController {
  const LocalAppShellController();

  static const List<String> _migrationAssets = <String>[
    'lib/data/database/migrations/0001_initial.sql',
    'lib/data/database/migrations/0002_meeting_task_candidates.sql',
    'lib/data/database/migrations/0003_search_fts_and_triggers.sql',
  ];

  @override
  Future<AppShellData> load() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final migrationsDirectory = await _materializeMigrations(supportDirectory);
    final storageDirectory = Directory(_join(supportDirectory.path, 'storage'));

    final database = await LocalDatabaseBootstrap.initialize(
      opener: _SqfliteDatabaseOpener(
        databasePath: _join(supportDirectory.path, 'field_work_agent.sqlite'),
      ),
      migrationsDirectoryPath: migrationsDirectory.path,
    );

    await LocalFileStorageBootstrap.initialize(rootDirectory: storageDirectory);

    return AppShellData(
      projects: await database.projects.listAll(),
      tasks: await database.tasks.listAll(),
      meetings: await database.meetings.listAll(),
      rawCaptures: await database.rawCaptures.listAll(),
      reportRuns: await database.reportRuns.listAll(),
      importRuns: await _loadImportRuns(database.executor),
      exportRuns: await _loadExportRuns(database.executor),
    );
  }

  Future<Directory> _materializeMigrations(Directory supportDirectory) async {
    final migrationsDirectory = Directory(_join(supportDirectory.path, 'migrations'));
    await migrationsDirectory.create(recursive: true);

    for (final assetPath in _migrationAssets) {
      final fileName = assetPath.split('/').last;
      final file = File(_join(migrationsDirectory.path, fileName));
      final contents = await rootBundle.loadString(assetPath);
      await file.writeAsString(contents);
    }

    return migrationsDirectory;
  }

  Future<List<ImportRunEntity>> _loadImportRuns(DatabaseExecutor executor) async {
    final rows = await executor.query(
      'SELECT * FROM imports ORDER BY import_time DESC LIMIT 5',
    );
    return rows
        .map(
          (row) => ImportRunEntity(
            id: row['id']! as String,
            bundleName: row['bundle_name']! as String,
            bundlePath: row['bundle_path']! as String,
            bundleChecksum: row['bundle_checksum'] as String?,
            importTime: DateTime.parse(row['import_time']! as String),
            previewSummaryJson: row['preview_summary_json'] as String?,
            decisionSummaryJson: row['decision_summary_json'] as String?,
            status: row['status']! as String,
          ),
        )
        .toList(growable: false);
  }

  Future<List<ExportRunEntity>> _loadExportRuns(DatabaseExecutor executor) async {
    final rows = await executor.query(
      'SELECT * FROM exports ORDER BY created_at DESC LIMIT 5',
    );
    return rows
        .map(
          (row) => ExportRunEntity(
            id: row['id']! as String,
            bundleName: row['bundle_name']! as String,
            bundlePath: row['bundle_path']! as String,
            bundleChecksum: row['bundle_checksum'] as String?,
            exportScopeType: row['export_scope_type']! as String,
            exportScopeValue: row['export_scope_value'] as String?,
            createdAt: DateTime.parse(row['created_at']! as String),
          ),
        )
        .toList(growable: false);
  }

  String _join(String left, String right) {
    final normalizedLeft = left.replaceAll('\\', '/').replaceFirst(RegExp(r'/$'), '');
    final normalizedRight = right.replaceAll('\\', '/').replaceFirst(RegExp('^/'), '');
    return '$normalizedLeft/$normalizedRight';
  }
}

class AppShellData {
  const AppShellData({
    required this.projects,
    required this.tasks,
    required this.meetings,
    required this.rawCaptures,
    required this.reportRuns,
    required this.importRuns,
    required this.exportRuns,
  });

  const AppShellData.empty()
      : projects = const <ProjectEntity>[],
        tasks = const <TaskEntity>[],
        meetings = const <MeetingEntity>[],
        rawCaptures = const <RawCaptureEntity>[],
        reportRuns = const <ReportRunEntity>[],
        importRuns = const <ImportRunEntity>[],
        exportRuns = const <ExportRunEntity>[];

  final List<ProjectEntity> projects;
  final List<TaskEntity> tasks;
  final List<MeetingEntity> meetings;
  final List<RawCaptureEntity> rawCaptures;
  final List<ReportRunEntity> reportRuns;
  final List<ImportRunEntity> importRuns;
  final List<ExportRunEntity> exportRuns;
}

class _SqfliteDatabaseOpener implements DatabaseOpener {
  const _SqfliteDatabaseOpener({required this.databasePath});

  final String databasePath;

  @override
  Future<DatabaseExecutor> open() async {
    final database = await sqflite.openDatabase(databasePath);
    return _SqfliteDatabaseExecutor.database(database);
  }
}

class _SqfliteDatabaseExecutor implements DatabaseExecutor {
  const _SqfliteDatabaseExecutor._({this.database, required sqflite.DatabaseExecutor executor}) : _executor = executor;

  factory _SqfliteDatabaseExecutor.database(sqflite.Database database) {
    return _SqfliteDatabaseExecutor._(database: database, executor: database);
  }

  factory _SqfliteDatabaseExecutor.transaction(sqflite.Transaction transaction) {
    return _SqfliteDatabaseExecutor._(executor: transaction);
  }

  final sqflite.Database? database;
  final sqflite.DatabaseExecutor _executor;

  @override
  Future<void> execute(String sql, [List<Object?> parameters = const <Object?>[]]) {
    return _executor.execute(sql, parameters);
  }

  @override
  Future<List<DatabaseRow>> query(String sql, [List<Object?> parameters = const <Object?>[]]) async {
    final rows = await _executor.rawQuery(sql, parameters);
    return rows.cast<DatabaseRow>();
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action) async {
    final currentDatabase = database;
    if (currentDatabase == null) {
      return action(this);
    }

    return currentDatabase.transaction<T>((sqflite.Transaction transaction) async {
      return action(_SqfliteDatabaseExecutor.transaction(transaction));
    });
  }

  @override
  Future<void> close() async {
    final currentDatabase = database;
    if (currentDatabase != null && currentDatabase.isOpen) {
      await currentDatabase.close();
    }
  }
}