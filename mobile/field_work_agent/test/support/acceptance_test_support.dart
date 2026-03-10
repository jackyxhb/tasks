import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import 'package:field_work_agent/bootstrap/local_database_bootstrap.dart';
import 'package:field_work_agent/bootstrap/local_file_storage_bootstrap.dart';
import 'package:field_work_agent/core/audit/audit_log_service.dart';
import 'package:field_work_agent/core/storage/local_file_storage_service.dart';
import 'package:field_work_agent/data/database/app_database.dart';
import 'package:field_work_agent/data/database/database_executor.dart';
import 'package:field_work_agent/data/database/repositories/audit_log_repository.dart';
import 'package:field_work_agent/domain/enums/raw_capture_channel.dart';
import 'package:field_work_agent/domain/enums/task_priority.dart';
import 'package:field_work_agent/domain/enums/task_status.dart';
import 'package:field_work_agent/domain/enums/task_type.dart';
import 'package:field_work_agent/features/capture/application/capture_classification_service.dart';
import 'package:field_work_agent/features/capture/application/raw_capture_intake_service.dart';
import 'package:field_work_agent/features/exchange/application/export_bundle_creator_service.dart';
import 'package:field_work_agent/features/exchange/application/import_preview_and_apply_service.dart';
import 'package:field_work_agent/features/meetings/application/meeting_extraction_service.dart';
import 'package:field_work_agent/features/meetings/application/meeting_recording_service.dart';
import 'package:field_work_agent/features/meetings/application/meeting_review_service.dart';
import 'package:field_work_agent/features/meetings/application/meeting_task_candidate_resolution_service.dart';
import 'package:field_work_agent/features/meetings/application/meeting_transcript_service.dart';
import 'package:field_work_agent/features/meetings/application/transcription_provider.dart';
import 'package:field_work_agent/features/meetings/application/transcription_result.dart';
import 'package:field_work_agent/features/projects/application/project_crud_service.dart';
import 'package:field_work_agent/features/reports/application/report_service.dart';
import 'package:field_work_agent/features/search/application/search_service.dart';
import 'package:field_work_agent/features/tasks/application/task_crud_service.dart';

var _sqfliteFactoryConfigured = false;

class ValidationSeedData {
  const ValidationSeedData({
    required this.project,
    required this.textCapture,
    required this.meeting,
  });

  final SeedProject project;
  final SeedTextCapture textCapture;
  final SeedMeeting meeting;

  static ValidationSeedData fromJson(Map<String, Object?> json) {
    return ValidationSeedData(
      project: SeedProject.fromJson(json['project']! as Map<String, Object?>),
      textCapture: SeedTextCapture.fromJson(
          json['text_capture']! as Map<String, Object?>),
      meeting: SeedMeeting.fromJson(json['meeting']! as Map<String, Object?>),
    );
  }
}

class SeedProject {
  const SeedProject({
    required this.projectName,
    required this.clientOem,
    required this.siteLocation,
    required this.siteContactName,
    required this.siteContactPhone,
    required this.coordinatorName,
    required this.projectManagerName,
  });

  final String projectName;
  final String? clientOem;
  final String? siteLocation;
  final String? siteContactName;
  final String? siteContactPhone;
  final String? coordinatorName;
  final String? projectManagerName;

  static SeedProject fromJson(Map<String, Object?> json) {
    return SeedProject(
      projectName: json['project_name']! as String,
      clientOem: json['client_oem'] as String?,
      siteLocation: json['site_location'] as String?,
      siteContactName: json['site_contact_name'] as String?,
      siteContactPhone: json['site_contact_phone'] as String?,
      coordinatorName: json['coordinator_name'] as String?,
      projectManagerName: json['project_manager_name'] as String?,
    );
  }
}

class SeedTextCapture {
  const SeedTextCapture({
    required this.channel,
    required this.rawText,
    required this.classificationType,
    required this.classificationConfidence,
    required this.task,
  });

  final RawCaptureChannel channel;
  final String rawText;
  final String classificationType;
  final double classificationConfidence;
  final SeedTask task;

  static SeedTextCapture fromJson(Map<String, Object?> json) {
    return SeedTextCapture(
      channel: rawCaptureChannelFromStorage(json['channel']! as String),
      rawText: json['raw_text']! as String,
      classificationType: json['classification_type']! as String,
      classificationConfidence:
          (json['classification_confidence']! as num).toDouble(),
      task: SeedTask.fromJson(json['task']! as Map<String, Object?>),
    );
  }
}

class SeedTask {
  const SeedTask({
    required this.taskType,
    required this.taskTitle,
    required this.description,
    required this.scheduledDate,
    required this.startTimeLocal,
    required this.locationSnapshot,
    required this.workerName,
    required this.workerPhone,
    required this.coordinatorName,
    required this.agenteeName,
    required this.status,
    required this.priority,
  });

  final TaskType taskType;
  final String taskTitle;
  final String description;
  final DateTime scheduledDate;
  final String startTimeLocal;
  final String locationSnapshot;
  final String workerName;
  final String workerPhone;
  final String coordinatorName;
  final String agenteeName;
  final TaskStatus status;
  final TaskPriority priority;

  static SeedTask fromJson(Map<String, Object?> json) {
    return SeedTask(
      taskType: taskTypeFromStorage(json['task_type']! as String),
      taskTitle: json['task_title']! as String,
      description: json['description']! as String,
      scheduledDate: DateTime.parse(json['scheduled_date']! as String).toUtc(),
      startTimeLocal: json['start_time_local']! as String,
      locationSnapshot: json['location_snapshot']! as String,
      workerName: json['worker_name']! as String,
      workerPhone: json['worker_phone']! as String,
      coordinatorName: json['coordinator_name']! as String,
      agenteeName: json['agentee_name']! as String,
      status: taskStatusFromStorage(json['status']! as String),
      priority: taskPriorityFromStorage(json['priority']! as String),
    );
  }
}

class SeedMeeting {
  const SeedMeeting({
    required this.title,
    required this.recordingPath,
    required this.transcription,
    required this.extractionJson,
  });

  final String title;
  final String recordingPath;
  final SeedTranscription transcription;
  final String extractionJson;

  static SeedMeeting fromJson(Map<String, Object?> json) {
    return SeedMeeting(
      title: json['title']! as String,
      recordingPath: json['recording_path']! as String,
      transcription: SeedTranscription.fromJson(
          json['transcription']! as Map<String, Object?>),
      extractionJson: json['extraction_json']! as String,
    );
  }
}

class SeedTranscription {
  const SeedTranscription({
    required this.providerName,
    required this.providerModel,
    required this.rawTranscript,
    required this.cleanedTranscript,
    required this.parseVersion,
  });

  final String providerName;
  final String providerModel;
  final String rawTranscript;
  final String cleanedTranscript;
  final String parseVersion;

  static SeedTranscription fromJson(Map<String, Object?> json) {
    return SeedTranscription(
      providerName: json['provider_name']! as String,
      providerModel: json['provider_model']! as String,
      rawTranscript: json['raw_transcript']! as String,
      cleanedTranscript: json['cleaned_transcript']! as String,
      parseVersion: json['parse_version']! as String,
    );
  }
}

class AcceptanceHarness {
  AcceptanceHarness._({
    required this.tempRoot,
    required this.storageService,
    required this.database,
    required this.auditLogService,
    required this.projectCrudService,
    required this.rawCaptureIntakeService,
    required this.captureClassificationService,
    required this.taskCrudService,
    required this.meetingRecordingService,
    required this.meetingTranscriptService,
    required this.meetingExtractionService,
    required this.meetingReviewService,
    required this.meetingTaskCandidateResolutionService,
    required this.searchService,
    required this.reportService,
    required this.exportBundleCreatorService,
    required this.importPreviewAndApplyService,
  });

  final Directory tempRoot;
  final LocalFileStorageService storageService;
  final AppDatabase database;
  final AuditLogService auditLogService;
  final ProjectCrudService projectCrudService;
  final RawCaptureIntakeService rawCaptureIntakeService;
  final CaptureClassificationService captureClassificationService;
  final TaskCrudService taskCrudService;
  final MeetingRecordingService meetingRecordingService;
  final MeetingTranscriptService meetingTranscriptService;
  final MeetingExtractionService meetingExtractionService;
  final MeetingReviewService meetingReviewService;
  final MeetingTaskCandidateResolutionService
      meetingTaskCandidateResolutionService;
  final SearchService searchService;
  final ReportService reportService;
  final ExportBundleCreatorService exportBundleCreatorService;
  final ImportPreviewAndApplyService importPreviewAndApplyService;

  static Future<AcceptanceHarness> create() async {
    if (!_sqfliteFactoryConfigured) {
      ffi.sqfliteFfiInit();
      sqflite.databaseFactory = ffi.databaseFactoryFfi;
      _sqfliteFactoryConfigured = true;
    }

    final tempRoot =
        await Directory.systemTemp.createTemp('field_work_agent_acceptance_');
    final storageRoot = Directory(_join(tempRoot.path, 'storage'));
    final databasePath = _join(tempRoot.path, 'field_work_agent.sqlite');
    final migrationsDirectoryPath = _join(
      Directory.current.path,
      'lib/data/database/migrations',
    );

    final database = await LocalDatabaseBootstrap.initialize(
      opener: _SqfliteDatabaseOpener(databasePath: databasePath),
      migrationsDirectoryPath: migrationsDirectoryPath,
    );
    final storageService =
        await LocalFileStorageBootstrap.initialize(rootDirectory: storageRoot);
    final auditLogService =
        AuditLogService(repository: AuditLogRepository(database.executor));

    final projectCrudService = ProjectCrudService(
      repository: database.projects,
      auditLogService: auditLogService,
    );
    final rawCaptureIntakeService = RawCaptureIntakeService(
      repository: database.rawCaptures,
      auditLogService: auditLogService,
    );
    final captureClassificationService = CaptureClassificationService(
      repository: database.rawCaptures,
      auditLogService: auditLogService,
    );
    final taskCrudService = TaskCrudService(
      repository: database.tasks,
      auditLogService: auditLogService,
    );
    final meetingRecordingService = MeetingRecordingService(
      meetingRepository: database.meetings,
      rawCaptureRepository: database.rawCaptures,
      rawCaptureIntakeService: rawCaptureIntakeService,
      fileStorageService: storageService,
      auditLogService: auditLogService,
    );
    final meetingTranscriptService = MeetingTranscriptService(
      meetingRepository: database.meetings,
      rawCaptureRepository: database.rawCaptures,
      auditLogService: auditLogService,
    );
    final meetingExtractionService = MeetingExtractionService(
      meetingRepository: database.meetings,
      auditLogService: auditLogService,
    );
    final meetingReviewService = MeetingReviewService(
      meetingRepository: database.meetings,
      rawCaptureRepository: database.rawCaptures,
      auditLogService: auditLogService,
    );
    final meetingTaskCandidateResolutionService =
        MeetingTaskCandidateResolutionService(
      meetingRepository: database.meetings,
      projectRepository: database.projects,
      taskCrudService: taskCrudService,
      auditLogService: auditLogService,
    );
    final searchService = SearchService(executor: database.executor);
    final reportService = ReportService(
      projectRepository: database.projects,
      taskRepository: database.tasks,
      meetingRepository: database.meetings,
      reportRunRepository: database.reportRuns,
      fileStorageService: storageService,
      auditLogService: auditLogService,
    );
    final exportBundleCreatorService = ExportBundleCreatorService(
      projectRepository: database.projects,
      taskRepository: database.tasks,
      meetingRepository: database.meetings,
      personRepository: database.people,
      attachmentRepository: database.attachments,
      exportRunRepository: database.exportRuns,
      fileStorageService: storageService,
      auditLogService: auditLogService,
    );
    final importPreviewAndApplyService = ImportPreviewAndApplyService(
      projectRepository: database.projects,
      taskRepository: database.tasks,
      meetingRepository: database.meetings,
      personRepository: database.people,
      importRunRepository: database.importRuns,
      fileStorageService: storageService,
      auditLogService: auditLogService,
    );

    return AcceptanceHarness._(
      tempRoot: tempRoot,
      storageService: storageService,
      database: database,
      auditLogService: auditLogService,
      projectCrudService: projectCrudService,
      rawCaptureIntakeService: rawCaptureIntakeService,
      captureClassificationService: captureClassificationService,
      taskCrudService: taskCrudService,
      meetingRecordingService: meetingRecordingService,
      meetingTranscriptService: meetingTranscriptService,
      meetingExtractionService: meetingExtractionService,
      meetingReviewService: meetingReviewService,
      meetingTaskCandidateResolutionService:
          meetingTaskCandidateResolutionService,
      searchService: searchService,
      reportService: reportService,
      exportBundleCreatorService: exportBundleCreatorService,
      importPreviewAndApplyService: importPreviewAndApplyService,
    );
  }

  Future<void> dispose() async {
    await database.close();
    await sqflite
        .deleteDatabase(_join(tempRoot.path, 'field_work_agent.sqlite'));
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  }
}

Future<ValidationSeedData> loadValidationSeed() async {
  final seedPath = _join(
    Directory.current.parent.parent.path,
    'examples/validation/pompallier-ponsonby-seed.json',
  );
  final file = File(seedPath);
  final jsonMap = jsonDecode(await file.readAsString()) as Map<String, Object?>;
  return ValidationSeedData.fromJson(jsonMap);
}

class StubTranscriptionProvider implements TranscriptionProvider {
  const StubTranscriptionProvider(this.seed);

  final SeedTranscription seed;

  @override
  Future<TranscriptionResult> transcribe(
      {required String audioFilePath}) async {
    return TranscriptionResult(
      providerName: seed.providerName,
      providerModel: seed.providerModel,
      rawTranscript: seed.rawTranscript,
      cleanedTranscript: seed.cleanedTranscript,
      parseVersion: seed.parseVersion,
    );
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
  const _SqfliteDatabaseExecutor._(
      {this.database, required sqflite.DatabaseExecutor executor})
      : _executor = executor;

  factory _SqfliteDatabaseExecutor.database(sqflite.Database database) {
    return _SqfliteDatabaseExecutor._(database: database, executor: database);
  }

  factory _SqfliteDatabaseExecutor.transaction(
      sqflite.Transaction transaction) {
    return _SqfliteDatabaseExecutor._(executor: transaction);
  }

  final sqflite.Database? database;
  final sqflite.DatabaseExecutor _executor;

  @override
  Future<void> execute(String sql,
      [List<Object?> parameters = const <Object?>[]]) {
    return _executor.execute(sql, parameters);
  }

  @override
  Future<List<DatabaseRow>> query(String sql,
      [List<Object?> parameters = const <Object?>[]]) async {
    final rows = await _executor.rawQuery(sql, parameters);
    return rows.cast<DatabaseRow>();
  }

  @override
  Future<T> transaction<T>(
      Future<T> Function(DatabaseExecutor txn) action) async {
    final currentDatabase = database;
    if (currentDatabase == null) {
      return action(this);
    }

    return currentDatabase
        .transaction<T>((sqflite.Transaction transaction) async {
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

String _join(String left, String right) {
  final normalizedLeft =
      left.replaceAll('\\', '/').replaceFirst(RegExp(r'/$'), '');
  final normalizedRight =
      right.replaceAll('\\', '/').replaceFirst(RegExp('^/'), '');
  return '$normalizedLeft/$normalizedRight';
}
