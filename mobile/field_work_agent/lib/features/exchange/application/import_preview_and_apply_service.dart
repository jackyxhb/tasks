import 'dart:convert';
import 'dart:io';

import '../../../core/audit/audit_log_service.dart';
import '../../../core/storage/local_file_storage_service.dart';
import '../../../data/database/repositories/import_run_repository.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../data/database/repositories/person_repository.dart';
import '../../../data/database/repositories/project_repository.dart';
import '../../../data/database/repositories/task_repository.dart';
import '../../../domain/entities/import_run_entity.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/person_entity.dart';
import '../../../domain/entities/project_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/enums/meeting_review_state.dart';
import '../../../domain/enums/task_priority.dart';
import '../../../domain/enums/task_status.dart';
import '../../../domain/enums/task_type.dart';
import 'exchange_models.dart';
import 'import_export_bundle_validator.dart';

typedef ImportRunIdFactory = String Function();

class ImportPreviewAndApplyService {
  ImportPreviewAndApplyService({
    required this.projectRepository,
    required this.taskRepository,
    required this.meetingRepository,
    required this.personRepository,
    required this.importRunRepository,
    required this.fileStorageService,
    required this.auditLogService,
    ImportExportBundleValidator? validator,
    ImportRunIdFactory? importRunIdFactory,
  })  : _validator = validator ?? const ImportExportBundleValidator(),
        _importRunIdFactory = importRunIdFactory ?? _defaultImportRunIdFactory;

  final ProjectRepository projectRepository;
  final TaskRepository taskRepository;
  final MeetingRepository meetingRepository;
  final PersonRepository personRepository;
  final ImportRunRepository importRunRepository;
  final LocalFileStorageService fileStorageService;
  final AuditLogService auditLogService;
  final ImportExportBundleValidator _validator;
  final ImportRunIdFactory _importRunIdFactory;

  Future<ImportPreviewResult> previewBundle({
    required String relativeImportPath,
    String? actorName,
  }) async {
    final file = fileStorageService.resolveRelativePath(relativeImportPath);
    final content = await file.readAsString();
    final validation = _validator.validateJson(content);
    if (!validation.isValid || validation.bundle == null) {
      throw StateError('Bundle validation failed: ${validation.issues.map((issue) => '${issue.path}: ${issue.message}').join('; ')}');
    }

    final bundle = validation.bundle!;
    final duplicateIds = <String>[
      ...await _findExistingProjectIds(bundle.projects),
      ...await _findExistingTaskIds(bundle.tasks),
      ...await _findExistingMeetingIds(bundle.meetings),
      ...await _findExistingPersonIds(bundle.people),
    ];

    final preview = ImportPreviewResult(
      bundle: bundle,
      projectCount: bundle.projects.length,
      taskCount: bundle.tasks.length,
      meetingCount: bundle.meetings.length,
      peopleCount: bundle.people.length,
      duplicateIds: duplicateIds,
    );
    final importRun = ImportRunEntity(
      id: _importRunIdFactory(),
      bundleName: file.uri.pathSegments.last,
      bundlePath: relativeImportPath,
      bundleChecksum: await fileStorageService.checksumForRelativePath(relativeImportPath),
      importTime: DateTime.now().toUtc(),
      previewSummaryJson: jsonEncode(<String, Object?>{
        'project_count': preview.projectCount,
        'task_count': preview.taskCount,
        'meeting_count': preview.meetingCount,
        'people_count': preview.peopleCount,
        'duplicate_ids': preview.duplicateIds,
      }),
      decisionSummaryJson: null,
      status: 'previewed',
    );
    await importRunRepository.save(importRun);
    await auditLogService.logImportApply(
      recordType: 'import_bundle',
      recordId: importRun.id,
      after: <String, Object?>{
        'bundle_name': importRun.bundleName,
        'bundle_path': importRun.bundlePath,
        'status': importRun.status,
        'duplicate_ids': duplicateIds,
      },
      actorName: actorName,
    );
    return preview;
  }

  Future<void> applyBundle({
    required String relativeImportPath,
    String? actorName,
  }) async {
    final preview = await previewBundle(relativeImportPath: relativeImportPath, actorName: actorName);
    final bundle = preview.bundle;

    for (final project in bundle.projects) {
      await projectRepository.save(
        ProjectEntity(
          id: project['id'] as String,
          projectName: project['project_name'] as String,
          projectNameNormalized: (project['project_name'] as String).trim().toLowerCase(),
          clientOem: project['client_oem'] as String?,
          siteLocation: project['site_location'] as String?,
          siteLocationNormalized: (project['site_location'] as String?)?.trim().toLowerCase(),
          siteContactName: project['site_contact_name'] as String?,
          siteContactPhone: project['site_contact_phone'] as String?,
          coordinatorName: project['coordinator_name'] as String?,
          projectManagerName: project['project_manager_name'] as String?,
          status: project['status'] as String?,
          notes: project['notes'] as String?,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    for (final person in bundle.people) {
      await personRepository.save(
        PersonEntity(
          id: person['id'] as String,
          name: person['name'] as String,
          nameNormalized: (person['name'] as String).trim().toLowerCase(),
          phone: person['phone'] as String?,
          roleHint: person['role_hint'] as String?,
          company: person['company'] as String?,
          notes: person['notes'] as String?,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    for (final task in bundle.tasks) {
      await taskRepository.save(
        TaskEntity(
          id: task['id'] as String,
          projectId: task['project_id'] as String?,
          taskType: taskTypeFromStorage(task['task_type'] as String? ?? 'unknown'),
          taskTitle: task['task_title'] as String?,
          taskTitleNormalized: (task['task_title'] as String?)?.trim().toLowerCase(),
          description: task['description'] as String?,
          scheduledDate: (task['scheduled_date'] as String?) != null ? DateTime.tryParse(task['scheduled_date'] as String) : null,
          startTimeLocal: task['start_time_local'] as String?,
          timeBucket: null,
          durationMinutes: null,
          locationSnapshot: null,
          workerName: task['worker_name'] as String?,
          workerPhone: task['worker_phone'] as String?,
          coordinatorName: task['coordinator_name'] as String?,
          projectManagerName: task['project_manager_name'] as String?,
          agenteeName: task['agentee_name'] as String? ?? 'imported-agentee',
          status: taskStatusFromStorage(task['status'] as String? ?? 'planned'),
          priority: taskPriorityFromStorage(task['priority'] as String? ?? 'medium'),
          sourceCaptureId: null,
          dedupKey: null,
          isProvisional: false,
          needsReview: true,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    for (final meeting in bundle.meetings) {
      final projectIds = (meeting['project_ids'] as List<Object?>?)?.map((item) => item.toString()).toList(growable: false) ?? const <String>[];
      await meetingRepository.save(
        MeetingEntity(
          id: meeting['id'] as String,
          title: meeting['title'] as String?,
          meetingDateTime: (meeting['meeting_datetime'] as String?) != null ? DateTime.tryParse(meeting['meeting_datetime'] as String) : null,
          meetingTimezone: meeting['meeting_timezone'] as String?,
          locationText: meeting['location_text'] as String?,
          summary: meeting['summary'] as String?,
          minutesMarkdown: meeting['minutes_markdown'] as String?,
          transcriptText: meeting['transcript_text'] as String?,
          sourceCaptureId: null,
          sourceHash: null,
          reviewState: meetingReviewStateFromStorage(meeting['review_state'] as String? ?? 'review_required'),
          needsReview: true,
          projectIds: projectIds,
          taskCandidates: const [],
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    final bundleFile = File(fileStorageService.resolveRelativePath(relativeImportPath).path);
    final importRun = ImportRunEntity(
      id: _importRunIdFactory(),
      bundleName: bundleFile.uri.pathSegments.last,
      bundlePath: relativeImportPath,
      bundleChecksum: await fileStorageService.checksumForRelativePath(relativeImportPath),
      importTime: DateTime.now().toUtc(),
      previewSummaryJson: null,
      decisionSummaryJson: jsonEncode(<String, Object?>{
        'action': 'upsert_merge',
        'project_count': bundle.projects.length,
        'task_count': bundle.tasks.length,
        'meeting_count': bundle.meetings.length,
        'people_count': bundle.people.length,
      }),
      status: 'applied',
    );
    await importRunRepository.save(importRun);
    await auditLogService.logImportApply(
      recordType: 'import_bundle',
      recordId: importRun.id,
      after: <String, Object?>{
        'bundle_name': importRun.bundleName,
        'bundle_path': importRun.bundlePath,
        'status': importRun.status,
      },
      actorName: actorName,
    );
  }

  Future<List<String>> _findExistingProjectIds(List<Map<String, Object?>> projects) async {
    final duplicates = <String>[];
    for (final project in projects) {
      final existing = await projectRepository.findById(project['id'] as String);
      if (existing != null) {
        duplicates.add(existing.id);
      }
    }
    return duplicates;
  }

  Future<List<String>> _findExistingTaskIds(List<Map<String, Object?>> tasks) async {
    final duplicates = <String>[];
    for (final task in tasks) {
      final existing = await taskRepository.findById(task['id'] as String);
      if (existing != null) {
        duplicates.add(existing.id);
      }
    }
    return duplicates;
  }

  Future<List<String>> _findExistingMeetingIds(List<Map<String, Object?>> meetings) async {
    final duplicates = <String>[];
    for (final meeting in meetings) {
      final existing = await meetingRepository.findById(meeting['id'] as String);
      if (existing != null) {
        duplicates.add(existing.id);
      }
    }
    return duplicates;
  }

  Future<List<String>> _findExistingPersonIds(List<Map<String, Object?>> people) async {
    final duplicates = <String>[];
    for (final person in people) {
      final existing = await personRepository.findById(person['id'] as String);
      if (existing != null) {
        duplicates.add(existing.id);
      }
    }
    return duplicates;
  }

  static String _defaultImportRunIdFactory() {
    return 'import_run_${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }
}