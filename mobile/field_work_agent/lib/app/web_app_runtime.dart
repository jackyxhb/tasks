import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../data/database/database_executor.dart';
import '../data/database/repositories/project_repository.dart';
import '../data/database/repositories/task_repository.dart';
import '../data/database/repositories/meeting_repository.dart';
import '../data/database/repositories/raw_capture_repository.dart';
import '../data/database/repositories/report_run_repository.dart';
import '../features/projects/application/project_draft.dart';
import '../features/tasks/application/task_models.dart';
import '../features/meetings/application/meeting_review_models.dart';
import '../features/meetings/application/meeting_task_candidate_resolution_service.dart';
import '../features/search/application/search_models.dart';
import '../features/reports/application/report_models.dart';
import '../features/exchange/application/exchange_models.dart';
import '../domain/entities/import_export_bundle_entity.dart';
import 'app_shell_controller.dart';

class WebAppShellController implements AppShellController {
  WebAppShellController._({
    required sqflite.Database db,
  })  : _projects = ProjectRepository(_WebExecutor(db)),
        _tasks = TaskRepository(_WebExecutor(db)),
        _meetings = MeetingRepository(_WebExecutor(db)),
        _rawCaptures = RawCaptureRepository(_WebExecutor(db)),
        _reportRuns = ReportRunRepository(_WebExecutor(db));

  final ProjectRepository _projects;
  final TaskRepository _tasks;
  final MeetingRepository _meetings;
  final RawCaptureRepository _rawCaptures;
  final ReportRunRepository _reportRuns;

  @override
  Future<AppShellData> load() async {
    return AppShellData(
      projects: await _projects.listAll(),
      tasks: await _tasks.listAll(),
      meetings: await _meetings.listAll(),
      rawCaptures: await _rawCaptures.listAll(),
      reportRuns: await _reportRuns.listAll(),
      importRuns: const [],
      exportRuns: const [],
    );
  }

  @override
  Future<AppShellData> createProject({
    required ProjectDraft draft,
    String? actorName,
  }) async {
    throw UnimplementedError('Project CRUD not yet implemented for web');
  }

  @override
  Future<AppShellData> updateProject({
    required String projectId,
    required ProjectDraft draft,
    String? actorName,
  }) async {
    throw UnimplementedError('Project CRUD not yet implemented for web');
  }

  @override
  Future<AppShellData> archiveProject({
    required String projectId,
    String? actorName,
  }) async {
    throw UnimplementedError('Project CRUD not yet implemented for web');
  }

  @override
  Future<AppShellData> createTask({
    required TaskDraft draft,
    String? actorName,
  }) async {
    throw UnimplementedError('Task CRUD not yet implemented for web');
  }

  @override
  Future<AppShellData> updateTask({
    required String taskId,
    required TaskDraft draft,
    String? actorName,
  }) async {
    throw UnimplementedError('Task CRUD not yet implemented for web');
  }

  @override
  Future<AppShellData> archiveTask({
    required String taskId,
    String? actorName,
  }) async {
    throw UnimplementedError('Task CRUD not yet implemented for web');
  }

  @override
  Future<AppShellData> markCaptureReviewed({
    required String captureId,
    String? actorName,
  }) async {
    throw UnimplementedError('Capture review not yet implemented for web');
  }

  @override
  Future<AppShellData> createRawTextCapture({
    required String textContent,
    String? actorName,
  }) async {
    throw UnimplementedError('Capture not yet implemented for web');
  }

  @override
  Future<AppShellData> createTaskFromCapture({
    required CaptureTaskReviewDraft draft,
    String? actorName,
  }) async {
    throw UnimplementedError('Task from capture not yet implemented for web');
  }

  @override
  Future<AppShellData> beginMeetingReview({
    required String meetingId,
    String? actorName,
  }) async {
    throw UnimplementedError('Meeting review not yet implemented for web');
  }

  @override
  Future<AppShellData> moveMeetingToManualReview({
    required String meetingId,
    required String reason,
    MeetingReviewDraft? draft,
    String? actorName,
  }) async {
    throw UnimplementedError('Meeting review not yet implemented for web');
  }

  @override
  Future<AppShellData> updateMeetingDraft({
    required String meetingId,
    required MeetingReviewDraft draft,
    String? actorName,
  }) async {
    throw UnimplementedError('Meeting review not yet implemented for web');
  }

  @override
  Future<AppShellData> beginMeetingTaskCandidateResolution({
    required String meetingId,
    String? actorName,
  }) async {
    throw UnimplementedError('Meeting review not yet implemented for web');
  }

  @override
  Future<AppShellData> finalizeMeeting({
    required String meetingId,
    String? actorName,
  }) async {
    throw UnimplementedError('Meeting review not yet implemented for web');
  }

  @override
  Future<AppShellData> acceptMeetingCandidateAsNewTask({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) async {
    throw UnimplementedError('Meeting review not yet implemented for web');
  }

  @override
  Future<AppShellData> saveMeetingCandidateAsProvisional({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) async {
    throw UnimplementedError('Meeting review not yet implemented for web');
  }

  @override
  Future<AppShellData> mergeMeetingCandidateIntoTask({
    required String meetingId,
    required String candidateId,
    required String taskId,
    String? actorName,
  }) async {
    throw UnimplementedError('Meeting review not yet implemented for web');
  }

  @override
  Future<AppShellData> updateMeetingCandidate({
    required String meetingId,
    required String candidateId,
    required MeetingTaskCandidateDraft draft,
    String? actorName,
  }) async {
    throw UnimplementedError('Meeting review not yet implemented for web');
  }

  @override
  Future<AppShellData> rejectMeetingCandidate({
    required String meetingId,
    required String candidateId,
    String? actorName,
  }) async {
    throw UnimplementedError('Meeting review not yet implemented for web');
  }

  @override
  Future<GroupedSearchResults> searchRecords({
    required SearchRequest request,
  }) async {
    throw UnimplementedError('Search not yet implemented for web');
  }

  @override
  Future<GeneratedReport> generateDailyTaskListReport({
    required DateTime date,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    throw UnimplementedError('Reports not yet implemented for web');
  }

  @override
  Future<GeneratedReport> generateProjectSummaryReport({
    required String projectId,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    throw UnimplementedError('Reports not yet implemented for web');
  }

  @override
  Future<GeneratedReport> generateMeetingMinutesPackReport({
    required ReportFilter filter,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    throw UnimplementedError('Reports not yet implemented for web');
  }

  @override
  Future<ImportExportBundleEntity> createExportBundle({
    required ExportScopeRequest scope,
    String? actorName,
  }) async {
    throw UnimplementedError('Export not yet implemented for web');
  }

  @override
  Future<ImportPreviewResult> previewImportBundle({
    required String relativeImportPath,
    String? actorName,
  }) async {
    throw UnimplementedError('Import not yet implemented for web');
  }

  @override
  Future<AppShellData> applyImportBundle({
    required String relativeImportPath,
    String? actorName,
  }) async {
    throw UnimplementedError('Import not yet implemented for web');
  }
}

Future<WebAppShellController> createWebAppShellController() async {
  sqflite.databaseFactory = databaseFactoryFfiWeb;

  final db = await sqflite.openDatabase('field_work_agent_web.db');

  await _runMigrations(db);

  return WebAppShellController._(db: db);
}

Future<WebAppShellController> createWebController() async {
  return createWebAppShellController();
}

Future<void> _runMigrations(sqflite.Database db) async {
  const migrationAssets = [
    'lib/data/database/migrations/0001_initial.sql',
    'lib/data/database/migrations/0002_meeting_task_candidates.sql',
    'lib/data/database/migrations/0003_search_fts_and_triggers.sql',
  ];

  for (final assetPath in migrationAssets) {
    final sql = await rootBundle.loadString(assetPath);
    final statements = _splitStatements(sql);
    for (final statement in statements) {
      await db.execute(statement);
    }
  }
}

List<String> _splitStatements(String sql) {
  final statements = <String>[];
  final buffer = StringBuffer();
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var inLineComment = false;
  var inBlockComment = false;
  var inTriggerBody = false;

  for (var index = 0; index < sql.length; index += 1) {
    final current = sql[index];
    final next = index + 1 < sql.length ? sql[index + 1] : '';

    if (inLineComment) {
      if (current == '\n') {
        inLineComment = false;
        buffer.write(current);
      }
      continue;
    }

    if (inBlockComment) {
      if (current == '*' && next == '/') {
        inBlockComment = false;
        index += 1;
      }
      continue;
    }

    if (!inSingleQuote && !inDoubleQuote) {
      if (current == '-' && next == '-') {
        inLineComment = true;
        index += 1;
        continue;
      }
      if (current == '/' && next == '*') {
        inBlockComment = true;
        index += 1;
        continue;
      }
    }

    if (current == "'" && !inDoubleQuote) {
      final escaped = next == "'";
      buffer.write(current);
      if (escaped) {
        buffer.write(next);
        index += 1;
      } else {
        inSingleQuote = !inSingleQuote;
      }
      continue;
    }

    if (current == '"' && !inSingleQuote) {
      inDoubleQuote = !inDoubleQuote;
      buffer.write(current);
      continue;
    }

    buffer.write(current);

    if (inSingleQuote || inDoubleQuote) {
      continue;
    }

    final normalized = buffer.toString().trim().toUpperCase();
    if (!inTriggerBody && normalized.startsWith('CREATE TRIGGER ')) {
      inTriggerBody = true;
    }

    if (current != ';') {
      continue;
    }

    if (inTriggerBody) {
      final trimmedUpper = buffer.toString().trimRight().toUpperCase();
      if (trimmedUpper.endsWith('END;')) {
        inTriggerBody = false;
      } else {
        continue;
      }
    }

    final statement = buffer.toString().trim();
    if (statement.isNotEmpty) {
      statements.add(statement);
    }
    buffer.clear();
  }

  final trailing = buffer.toString().trim();
  if (trailing.isNotEmpty) {
    statements.add(trailing);
  }

  return statements;
}

class _WebExecutor implements DatabaseExecutor {
  _WebExecutor(this._db);

  final sqflite.Database _db;

  @override
  Future<void> execute(String sql, [List<Object?> parameters = const []]) {
    return _db.execute(sql, parameters);
  }

  @override
  Future<List<DatabaseRow>> query(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final rows = await _db.rawQuery(sql, parameters);
    return rows.cast<DatabaseRow>();
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(DatabaseExecutor txn) action,
  ) async {
    return _db.transaction((txn) async {
      return action(_WebTxnExecutor(txn));
    });
  }

  @override
  Future<void> close() async {
    if (_db.isOpen) {
      await _db.close();
    }
  }
}

class _WebTxnExecutor implements DatabaseExecutor {
  _WebTxnExecutor(this._txn);

  final sqflite.Transaction _txn;

  @override
  Future<void> execute(String sql, [List<Object?> parameters = const []]) {
    return _txn.execute(sql, parameters);
  }

  @override
  Future<List<DatabaseRow>> query(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final rows = await _txn.rawQuery(sql, parameters);
    return rows.cast<DatabaseRow>();
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(DatabaseExecutor txn) action,
  ) async {
    return action(this);
  }

  @override
  Future<void> close() async {}
}
