import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../bootstrap/local_database_bootstrap.dart';
import '../bootstrap/local_file_storage_bootstrap.dart';
import '../core/audit/audit_log_service.dart';
import '../data/database/app_database.dart';
import '../data/database/database_executor.dart';
import '../domain/entities/export_run_entity.dart';
import '../domain/entities/import_run_entity.dart';
import '../domain/entities/meeting_entity.dart';
import '../domain/entities/project_entity.dart';
import '../domain/entities/raw_capture_entity.dart';
import '../domain/entities/report_run_entity.dart';
import '../domain/entities/task_entity.dart';
import '../domain/enums/raw_capture_parse_status.dart';
import '../domain/enums/task_priority.dart';
import '../domain/enums/task_status.dart';
import '../domain/enums/task_type.dart';
import '../features/capture/application/capture_classification.dart';
import '../features/capture/application/capture_classification_service.dart';
import '../features/meetings/application/meeting_review_editor_service.dart';
import '../features/meetings/application/meeting_review_models.dart';
import '../features/meetings/application/meeting_review_service.dart';
import '../features/meetings/application/meeting_task_candidate_resolution_service.dart';
import '../features/projects/application/project_crud_service.dart';
import '../features/tasks/application/task_crud_service.dart';
import '../features/tasks/application/task_models.dart';

abstract class AppShellController {
  Future<AppShellData> load();

  Future<AppShellData> markCaptureReviewed({
    required String captureId,
    String? actorName,
  });

  Future<AppShellData> createTaskFromCapture({
    required CaptureTaskReviewDraft draft,
    String? actorName,
  });

  Future<AppShellData> beginMeetingReview({
    required String meetingId,
    String? actorName,
  });

  Future<AppShellData> moveMeetingToManualReview({
    required String meetingId,
    String? actorName,
  });

  Future<AppShellData> updateMeetingDraft({
    required String meetingId,
    required MeetingReviewDraft draft,
    String? actorName,
  });

  Future<AppShellData> beginMeetingTaskCandidateResolution({
    required String meetingId,
    String? actorName,
  });

  Future<AppShellData> finalizeMeeting({
    required String meetingId,
    String? actorName,
  });

  Future<AppShellData> acceptMeetingCandidateAsNewTask({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  });

  Future<AppShellData> saveMeetingCandidateAsProvisional({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  });

  Future<AppShellData> rejectMeetingCandidate({
    required String meetingId,
    required String candidateId,
    String? actorName,
  });
}

class CaptureTaskReviewDraft {
  const CaptureTaskReviewDraft({
    required this.captureId,
    required this.classificationType,
    required this.classificationConfidence,
    required this.taskType,
    required this.taskTitle,
    required this.description,
    required this.scheduledDateText,
    required this.startTimeLocal,
    required this.locationSnapshot,
    required this.workerName,
    required this.workerPhone,
    required this.coordinatorName,
    required this.projectManagerName,
    required this.agenteeName,
    required this.status,
    required this.priority,
    required this.isProvisional,
    required this.needsReview,
    this.projectId,
  });

  final String captureId;
  final String classificationType;
  final double classificationConfidence;
  final String? projectId;
  final TaskType taskType;
  final String? taskTitle;
  final String? description;
  final String? scheduledDateText;
  final String? startTimeLocal;
  final String? locationSnapshot;
  final String? workerName;
  final String? workerPhone;
  final String? coordinatorName;
  final String? projectManagerName;
  final String agenteeName;
  final TaskStatus status;
  final TaskPriority priority;
  final bool isProvisional;
  final bool needsReview;
}

class StaticAppShellController implements AppShellController {
  const StaticAppShellController(this.data);

  final AppShellData data;

  @override
  Future<AppShellData> load() async => data;

  @override
  Future<AppShellData> markCaptureReviewed({required String captureId, String? actorName}) async => data;

  @override
  Future<AppShellData> createTaskFromCapture({required CaptureTaskReviewDraft draft, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> beginMeetingReview({required String meetingId, String? actorName}) async => data;

  @override
  Future<AppShellData> moveMeetingToManualReview({required String meetingId, String? actorName}) async => data;

  @override
  Future<AppShellData> updateMeetingDraft({
    required String meetingId,
    required MeetingReviewDraft draft,
    String? actorName,
  }) async => data;

  @override
  Future<AppShellData> beginMeetingTaskCandidateResolution({required String meetingId, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> finalizeMeeting({required String meetingId, String? actorName}) async => data;

  @override
  Future<AppShellData> acceptMeetingCandidateAsNewTask({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) async => data;

  @override
  Future<AppShellData> saveMeetingCandidateAsProvisional({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) async => data;

  @override
  Future<AppShellData> rejectMeetingCandidate({
    required String meetingId,
    required String candidateId,
    String? actorName,
  }) async => data;
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
    return _withRuntime((runtime) => runtime.loadData());
  }

  @override
  Future<AppShellData> markCaptureReviewed({
    required String captureId,
    String? actorName,
  }) {
    return _withRuntime((runtime) async {
      final capture = await runtime.database.rawCaptures.findById(captureId);
      if (capture == null) {
        throw StateError('Raw capture not found: $captureId');
      }
      await _saveReviewedCapture(
        runtime: runtime,
        capture: capture,
        actorName: actorName,
      );
      return runtime.loadData();
    });
  }

  @override
  Future<AppShellData> createTaskFromCapture({
    required CaptureTaskReviewDraft draft,
    String? actorName,
  }) {
    return _withRuntime((runtime) async {
      final classifiedCapture = await runtime.captureClassificationService.applyClassification(
        captureId: draft.captureId,
        classification: CaptureClassification(
          type: draft.classificationType,
          confidence: draft.classificationConfidence,
          parseVersion: 'ui-review-v1',
        ),
        actorName: actorName,
      );
      final linkedProject = draft.projectId == null
          ? null
          : await runtime.projectCrudService.detail(draft.projectId!);
      await runtime.taskCrudService.create(
        TaskDraft(
          projectId: linkedProject?.id,
          projectName: linkedProject?.projectName,
          taskType: draft.taskType,
          taskTitle: draft.taskTitle,
          description: draft.description,
          scheduledDate: _parseDateInput(draft.scheduledDateText),
          startTimeLocal: draft.startTimeLocal,
          locationSnapshot: draft.locationSnapshot,
          workerName: draft.workerName,
          workerPhone: draft.workerPhone,
          coordinatorName: draft.coordinatorName,
          projectManagerName: draft.projectManagerName,
          agenteeName: draft.agenteeName,
          status: draft.status,
          priority: draft.priority,
          sourceCaptureId: classifiedCapture.id,
          isProvisional: draft.isProvisional,
          needsReview: draft.needsReview,
        ),
        actorName: actorName,
      );
      await _saveReviewedCapture(
        runtime: runtime,
        capture: classifiedCapture,
        actorName: actorName,
      );
      return runtime.loadData();
    });
  }

  @override
  Future<AppShellData> beginMeetingReview({required String meetingId, String? actorName}) {
    return _withRuntime((runtime) async {
      await runtime.meetingReviewService.beginReview(
        meetingId: meetingId,
        actorName: actorName,
      );
      return runtime.loadData();
    });
  }

  @override
  Future<AppShellData> moveMeetingToManualReview({required String meetingId, String? actorName}) {
    return _withRuntime((runtime) async {
      await runtime.meetingReviewService.moveToManualReviewOnly(
        meetingId: meetingId,
        actorName: actorName,
      );
      return runtime.loadData();
    });
  }

  @override
  Future<AppShellData> updateMeetingDraft({
    required String meetingId,
    required MeetingReviewDraft draft,
    String? actorName,
  }) {
    return _withRuntime((runtime) async {
      await runtime.meetingReviewEditorService.updateMeetingDraft(
        meetingId: meetingId,
        draft: draft,
        actorName: actorName,
      );
      return runtime.loadData();
    });
  }

  @override
  Future<AppShellData> beginMeetingTaskCandidateResolution({
    required String meetingId,
    String? actorName,
  }) {
    return _withRuntime((runtime) async {
      await runtime.meetingReviewService.beginTaskCandidateResolution(
        meetingId: meetingId,
        actorName: actorName,
      );
      return runtime.loadData();
    });
  }

  @override
  Future<AppShellData> finalizeMeeting({required String meetingId, String? actorName}) {
    return _withRuntime((runtime) async {
      await runtime.meetingReviewService.finalizeMeeting(
        meetingId: meetingId,
        actorName: actorName,
      );
      return runtime.loadData();
    });
  }

  @override
  Future<AppShellData> acceptMeetingCandidateAsNewTask({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) {
    return _withRuntime((runtime) async {
      await runtime.meetingTaskCandidateResolutionService.acceptAsNewTask(
        meetingId: meetingId,
        candidateId: candidateId,
        agenteeName: agenteeName,
        actorName: actorName,
      );
      return runtime.loadData();
    });
  }

  @override
  Future<AppShellData> saveMeetingCandidateAsProvisional({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) {
    return _withRuntime((runtime) async {
      await runtime.meetingTaskCandidateResolutionService.saveAsProvisionalTask(
        meetingId: meetingId,
        candidateId: candidateId,
        agenteeName: agenteeName,
        actorName: actorName,
      );
      return runtime.loadData();
    });
  }

  @override
  Future<AppShellData> rejectMeetingCandidate({
    required String meetingId,
    required String candidateId,
    String? actorName,
  }) {
    return _withRuntime((runtime) async {
      await runtime.meetingTaskCandidateResolutionService.rejectCandidate(
        meetingId: meetingId,
        candidateId: candidateId,
        actorName: actorName,
      );
      return runtime.loadData();
    });
  }

  Future<T> _withRuntime<T>(Future<T> Function(_LocalAppRuntime runtime) action) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final migrationsDirectory = await _materializeMigrations(supportDirectory);
    final runtime = await _LocalAppRuntime.open(
      supportDirectory: supportDirectory,
      migrationsDirectory: migrationsDirectory,
      databasePath: _join(supportDirectory.path, 'field_work_agent.sqlite'),
    );
    try {
      return await action(runtime);
    } finally {
      await runtime.dispose();
    }
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

  static Future<List<ImportRunEntity>> _loadImportRuns(DatabaseExecutor executor) async {
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

  static Future<List<ExportRunEntity>> _loadExportRuns(DatabaseExecutor executor) async {
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

  Future<void> _saveReviewedCapture({
    required _LocalAppRuntime runtime,
    required RawCaptureEntity capture,
    String? actorName,
  }) async {
    final reviewedCapture = RawCaptureEntity(
      id: capture.id,
      channel: capture.channel,
      rawText: capture.rawText,
      transcriptText: capture.transcriptText,
      transcriptionProvider: capture.transcriptionProvider,
      transcriptionModel: capture.transcriptionModel,
      transcriptionError: capture.transcriptionError,
      audioFilePath: capture.audioFilePath,
      attachmentGroupId: capture.attachmentGroupId,
      captureTime: capture.captureTime,
      captureTimezone: capture.captureTimezone,
      capturedByAgenteeName: capture.capturedByAgenteeName,
      classificationType: capture.classificationType,
      classificationConfidence: capture.classificationConfidence,
      parseStatus: RawCaptureParseStatus.reviewed,
      parseVersion: capture.parseVersion,
      sourceHash: capture.sourceHash,
      createdAt: capture.createdAt,
    );
    await runtime.database.rawCaptures.save(reviewedCapture);
    await runtime.auditLogService.logUpdate(
      recordType: 'raw_capture',
      recordId: reviewedCapture.id,
      before: _captureSnapshot(capture),
      after: _captureSnapshot(reviewedCapture),
      actorName: actorName,
    );
  }

  Map<String, Object?> _captureSnapshot(RawCaptureEntity capture) {
    return <String, Object?>{
      'id': capture.id,
      'classification_type': capture.classificationType,
      'classification_confidence': capture.classificationConfidence,
      'parse_status': capture.parseStatus.storageValue,
      'parse_version': capture.parseVersion,
    };
  }

  DateTime? _parseDateInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(value.trim());
    return parsed?.toUtc();
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

  ProjectEntity? projectById(String? projectId) {
    if (projectId == null) {
      return null;
    }
    for (final project in projects) {
      if (project.id == projectId) {
        return project;
      }
    }
    return null;
  }
}

class _LocalAppRuntime {
  const _LocalAppRuntime({
    required this.database,
    required this.auditLogService,
    required this.projectCrudService,
    required this.taskCrudService,
    required this.captureClassificationService,
    required this.meetingReviewService,
    required this.meetingReviewEditorService,
    required this.meetingTaskCandidateResolutionService,
  });

  final AppDatabase database;
  final AuditLogService auditLogService;
  final ProjectCrudService projectCrudService;
  final TaskCrudService taskCrudService;
  final CaptureClassificationService captureClassificationService;
  final MeetingReviewService meetingReviewService;
  final MeetingReviewEditorService meetingReviewEditorService;
  final MeetingTaskCandidateResolutionService meetingTaskCandidateResolutionService;

  static Future<_LocalAppRuntime> open({
    required Directory supportDirectory,
    required Directory migrationsDirectory,
    required String databasePath,
  }) async {
    final storageDirectory = Directory(
      _joinPaths(supportDirectory.path, 'storage'),
    );
    final database = await LocalDatabaseBootstrap.initialize(
      opener: _SqfliteDatabaseOpener(databasePath: databasePath),
      migrationsDirectoryPath: migrationsDirectory.path,
    );
    await LocalFileStorageBootstrap.initialize(rootDirectory: storageDirectory);

    final auditLogService = AuditLogService(repository: database.auditLogs);
    return _LocalAppRuntime(
      database: database,
      auditLogService: auditLogService,
      projectCrudService: ProjectCrudService(
        repository: database.projects,
        auditLogService: auditLogService,
      ),
      taskCrudService: TaskCrudService(
        repository: database.tasks,
        auditLogService: auditLogService,
      ),
      captureClassificationService: CaptureClassificationService(
        repository: database.rawCaptures,
        auditLogService: auditLogService,
      ),
      meetingReviewService: MeetingReviewService(
        meetingRepository: database.meetings,
        rawCaptureRepository: database.rawCaptures,
        auditLogService: auditLogService,
      ),
      meetingReviewEditorService: MeetingReviewEditorService(
        meetingRepository: database.meetings,
        auditLogService: auditLogService,
      ),
      meetingTaskCandidateResolutionService:
          MeetingTaskCandidateResolutionService(
        meetingRepository: database.meetings,
        projectRepository: database.projects,
        taskCrudService: TaskCrudService(
          repository: database.tasks,
          auditLogService: auditLogService,
        ),
        auditLogService: auditLogService,
      ),
    );
  }

  Future<AppShellData> loadData() async {
    return AppShellData(
      projects: await database.projects.listAll(),
      tasks: await database.tasks.listAll(),
      meetings: await database.meetings.listAll(),
      rawCaptures: await database.rawCaptures.listAll(),
      reportRuns: await database.reportRuns.listAll(),
      importRuns: await LocalAppShellController._loadImportRuns(database.executor),
      exportRuns: await LocalAppShellController._loadExportRuns(database.executor),
    );
  }

  Future<void> dispose() {
    return database.close();
  }

  static String _joinPaths(String left, String right) {
    final normalizedLeft = left.replaceAll('\\', '/').replaceFirst(RegExp(r'/$'), '');
    final normalizedRight = right.replaceAll('\\', '/').replaceFirst(RegExp('^/'), '');
    return '$normalizedLeft/$normalizedRight';
  }
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