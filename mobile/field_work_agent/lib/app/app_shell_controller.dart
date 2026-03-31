import '../domain/entities/export_run_entity.dart';
import '../domain/entities/import_run_entity.dart';
import '../domain/entities/import_export_bundle_entity.dart';
import '../domain/entities/meeting_entity.dart';
import '../domain/entities/project_entity.dart';
import '../domain/entities/raw_capture_entity.dart';
import '../domain/entities/report_run_entity.dart';
import '../domain/entities/task_entity.dart';
import '../domain/enums/task_priority.dart';
import '../domain/enums/task_status.dart';
import '../domain/enums/task_type.dart';
import '../features/exchange/application/exchange_models.dart';
import '../features/meetings/application/meeting_review_models.dart';
import '../features/meetings/application/meeting_task_candidate_resolution_service.dart';
import '../features/projects/application/project_draft.dart';
import '../features/reports/application/report_models.dart';
import '../features/search/application/search_models.dart';
import '../features/tasks/application/task_models.dart';

abstract class AppShellController {
  Future<AppShellData> load();

  Future<AppShellData> createProject({
    required ProjectDraft draft,
    String? actorName,
  });

  Future<AppShellData> updateProject({
    required String projectId,
    required ProjectDraft draft,
    String? actorName,
  });

  Future<AppShellData> archiveProject({
    required String projectId,
    String? actorName,
  });

  Future<AppShellData> createTask({
    required TaskDraft draft,
    String? actorName,
  });

  Future<AppShellData> updateTask({
    required String taskId,
    required TaskDraft draft,
    String? actorName,
  });

  Future<AppShellData> archiveTask({
    required String taskId,
    String? actorName,
  });

  Future<AppShellData> markCaptureReviewed({
    required String captureId,
    String? actorName,
  });

  Future<AppShellData> createRawTextCapture({
    required String textContent,
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
    required String reason,
    MeetingReviewDraft? draft,
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

  Future<AppShellData> mergeMeetingCandidateIntoTask({
    required String meetingId,
    required String candidateId,
    required String taskId,
    String? actorName,
  });

  Future<AppShellData> updateMeetingCandidate({
    required String meetingId,
    required String candidateId,
    required MeetingTaskCandidateDraft draft,
    String? actorName,
  });

  Future<AppShellData> rejectMeetingCandidate({
    required String meetingId,
    required String candidateId,
    String? actorName,
  });

  Future<GroupedSearchResults> searchRecords({
    required SearchRequest request,
  });

  Future<GeneratedReport> generateDailyTaskListReport({
    required DateTime date,
    required ReportOutputFormat outputFormat,
    String? actorName,
  });

  Future<GeneratedReport> generateProjectSummaryReport({
    required String projectId,
    required ReportOutputFormat outputFormat,
    String? actorName,
  });

  Future<GeneratedReport> generateMeetingMinutesPackReport({
    required ReportFilter filter,
    required ReportOutputFormat outputFormat,
    String? actorName,
  });

  Future<ImportExportBundleEntity> createExportBundle({
    required ExportScopeRequest scope,
    String? actorName,
  });

  Future<ImportPreviewResult> previewImportBundle({
    required String relativeImportPath,
    String? actorName,
  });

  Future<AppShellData> applyImportBundle({
    required String relativeImportPath,
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
  Future<AppShellData> createProject(
          {required ProjectDraft draft, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> updateProject({
    required String projectId,
    required ProjectDraft draft,
    String? actorName,
  }) async =>
      data;

  @override
  Future<AppShellData> archiveProject(
          {required String projectId, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> createTask(
          {required TaskDraft draft, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> updateTask({
    required String taskId,
    required TaskDraft draft,
    String? actorName,
  }) async =>
      data;

  @override
  Future<AppShellData> archiveTask(
          {required String taskId, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> markCaptureReviewed(
          {required String captureId, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> createRawTextCapture({
    required String textContent,
    String? actorName,
  }) async =>
      data;

  @override
  Future<AppShellData> createTaskFromCapture(
          {required CaptureTaskReviewDraft draft, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> beginMeetingReview(
          {required String meetingId, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> moveMeetingToManualReview({
    required String meetingId,
    required String reason,
    MeetingReviewDraft? draft,
    String? actorName,
  }) async =>
      data;

  @override
  Future<AppShellData> updateMeetingDraft({
    required String meetingId,
    required MeetingReviewDraft draft,
    String? actorName,
  }) async =>
      data;

  @override
  Future<AppShellData> beginMeetingTaskCandidateResolution(
          {required String meetingId, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> finalizeMeeting(
          {required String meetingId, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> acceptMeetingCandidateAsNewTask({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) async =>
      data;

  @override
  Future<AppShellData> saveMeetingCandidateAsProvisional({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) async =>
      data;

  @override
  Future<AppShellData> mergeMeetingCandidateIntoTask({
    required String meetingId,
    required String candidateId,
    required String taskId,
    String? actorName,
  }) async =>
      data;

  @override
  Future<AppShellData> updateMeetingCandidate({
    required String meetingId,
    required String candidateId,
    required MeetingTaskCandidateDraft draft,
    String? actorName,
  }) async =>
      data;

  @override
  Future<AppShellData> rejectMeetingCandidate({
    required String meetingId,
    required String candidateId,
    String? actorName,
  }) async =>
      data;

  @override
  Future<GroupedSearchResults> searchRecords(
      {required SearchRequest request}) async {
    return const GroupedSearchResults(
      projects: <SearchHit>[],
      tasks: <SearchHit>[],
      meetings: <SearchHit>[],
      rawCaptures: <SearchHit>[],
      people: <SearchHit>[],
    );
  }

  @override
  Future<GeneratedReport> generateDailyTaskListReport({
    required DateTime date,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    return const GeneratedReport(
      reportType: 'daily_task_list',
      summary: 'No report generation is configured for the static controller.',
      payload: <String, Object?>{},
    );
  }

  @override
  Future<GeneratedReport> generateProjectSummaryReport({
    required String projectId,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    return const GeneratedReport(
      reportType: 'project_summary',
      summary: 'No report generation is configured for the static controller.',
      payload: <String, Object?>{},
    );
  }

  @override
  Future<GeneratedReport> generateMeetingMinutesPackReport({
    required ReportFilter filter,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    return const GeneratedReport(
      reportType: 'meeting_minutes_pack',
      summary: 'No report generation is configured for the static controller.',
      payload: <String, Object?>{},
    );
  }

  @override
  Future<ImportExportBundleEntity> createExportBundle({
    required ExportScopeRequest scope,
    String? actorName,
  }) async {
    return ImportExportBundleEntity(
      schemaVersion: 'v1',
      bundleId: 'static_bundle',
      exportedAt: DateTime.utc(2026, 3, 10),
      sourceAppName: 'field_work_agent',
      sourceAppVersion: '0.1.0',
      scope: ExportScope(type: scope.type, value: scope.value),
      projects: const <Map<String, Object?>>[],
      tasks: const <Map<String, Object?>>[],
      meetings: const <Map<String, Object?>>[],
      people: const <Map<String, Object?>>[],
      attachmentsManifest: const <AttachmentManifestEntry>[],
    );
  }

  @override
  Future<ImportPreviewResult> previewImportBundle({
    required String relativeImportPath,
    String? actorName,
  }) async {
    return ImportPreviewResult(
      bundle: ImportExportBundleEntity(
        schemaVersion: 'v1',
        bundleId: 'static_preview',
        exportedAt: DateTime.utc(2026, 3, 10),
        sourceAppName: 'field_work_agent',
        sourceAppVersion: '0.1.0',
        scope: const ExportScope(type: 'all'),
        projects: const <Map<String, Object?>>[],
        tasks: const <Map<String, Object?>>[],
        meetings: const <Map<String, Object?>>[],
        people: const <Map<String, Object?>>[],
        attachmentsManifest: const <AttachmentManifestEntry>[],
      ),
      projectCount: 0,
      taskCount: 0,
      meetingCount: 0,
      peopleCount: 0,
      duplicateIds: const <String>[],
    );
  }

  @override
  Future<AppShellData> applyImportBundle({
    required String relativeImportPath,
    String? actorName,
  }) async =>
      data;
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

  bool get hasAnyData =>
      projects.isNotEmpty ||
      tasks.isNotEmpty ||
      meetings.isNotEmpty ||
      rawCaptures.isNotEmpty;

  bool get hasPendingWork =>
      rawCaptures.isNotEmpty ||
      tasks.any((task) => task.isProvisional && task.archivedAt == null);

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
