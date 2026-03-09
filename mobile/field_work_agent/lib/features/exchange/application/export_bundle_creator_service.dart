import 'dart:convert';
import 'dart:io';

import '../../../core/audit/audit_log_service.dart';
import '../../../core/storage/local_file_storage_service.dart';
import '../../../data/database/repositories/attachment_repository.dart';
import '../../../data/database/repositories/export_run_repository.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../data/database/repositories/person_repository.dart';
import '../../../data/database/repositories/project_repository.dart';
import '../../../data/database/repositories/task_repository.dart';
import '../../../domain/entities/export_run_entity.dart';
import '../../../domain/entities/import_export_bundle_entity.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/person_entity.dart';
import '../../../domain/entities/project_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/enums/meeting_review_state.dart';
import '../../../domain/enums/task_priority.dart';
import '../../../domain/enums/task_status.dart';
import '../../../domain/enums/task_type.dart';
import 'exchange_models.dart';

typedef ExportRunIdFactory = String Function();

class ExportBundleCreatorService {
  ExportBundleCreatorService({
    required this.projectRepository,
    required this.taskRepository,
    required this.meetingRepository,
    required this.personRepository,
    required this.attachmentRepository,
    required this.exportRunRepository,
    required this.fileStorageService,
    required this.auditLogService,
    ExportRunIdFactory? exportRunIdFactory,
  }) : _exportRunIdFactory = exportRunIdFactory ?? _defaultExportRunIdFactory;

  final ProjectRepository projectRepository;
  final TaskRepository taskRepository;
  final MeetingRepository meetingRepository;
  final PersonRepository personRepository;
  final AttachmentRepository attachmentRepository;
  final ExportRunRepository exportRunRepository;
  final LocalFileStorageService fileStorageService;
  final AuditLogService auditLogService;
  final ExportRunIdFactory _exportRunIdFactory;

  Future<ImportExportBundleEntity> createBundle({
    required ExportScopeRequest scope,
    String? actorName,
  }) async {
    final projects = await projectRepository.listAll();
    final tasks = await taskRepository.listAll();
    final meetings = await meetingRepository.listAll();
    final people = await personRepository.suggest(limit: 1000);

    final selectedProjects = _selectProjects(projects, scope);
    final selectedProjectIds = selectedProjects.map((project) => project.id).toSet();
    final selectedTasks = _selectTasks(tasks, scope, selectedProjectIds);
    final selectedMeetings = _selectMeetings(meetings, scope, selectedProjectIds);
    final selectedPeople = people;

    final ownerIds = <String>{
      ...selectedProjects.map((project) => project.id),
      ...selectedTasks.map((task) => task.id),
      ...selectedMeetings.map((meeting) => meeting.id),
      ...selectedPeople.map((person) => person.id),
    };
    final attachments = await attachmentRepository.listForOwners(ownerIds);
    final manifest = <AttachmentManifestEntry>[];
    for (final attachment in attachments) {
      final checksum = attachment.checksum ?? await fileStorageService.checksumForRelativePath(attachment.filePath);
      manifest.add(
        AttachmentManifestEntry(
          attachmentId: attachment.id,
          ownerRecordType: attachment.ownerRecordType,
          ownerRecordId: attachment.ownerRecordId,
          relativePath: attachment.filePath,
          checksum: checksum,
          mimeType: attachment.mimeType,
        ),
      );
    }

    final bundle = ImportExportBundleEntity(
      schemaVersion: 'v1',
      bundleId: 'bundle_${DateTime.now().toUtc().microsecondsSinceEpoch}',
      exportedAt: DateTime.now().toUtc(),
      sourceAppName: 'personal-field-work-agent',
      sourceAppVersion: '0.1.0',
      scope: ExportScope(type: scope.type, value: scope.value),
      projects: selectedProjects.map(_projectRecord).toList(growable: false),
      tasks: selectedTasks.map(_taskRecord).toList(growable: false),
      meetings: selectedMeetings.map(_meetingRecord).toList(growable: false),
      people: selectedPeople.map(_personRecord).toList(growable: false),
      attachmentsManifest: manifest,
    );

    final jsonPayload = const JsonEncoder.withIndent('  ').convert(_bundleToJson(bundle));
    final fileReference = await fileStorageService.prepareFile(
      directory: LocalStorageDirectory.exports,
      fileName: '${bundle.bundleId}.json',
    );
    final file = File(fileReference.absolutePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonPayload);
    final checksum = await fileStorageService.checksumForRelativePath(fileReference.relativePath);

    final exportRun = ExportRunEntity(
      id: _exportRunIdFactory(),
      bundleName: '${bundle.bundleId}.json',
      bundlePath: fileReference.relativePath,
      bundleChecksum: checksum,
      exportScopeType: scope.type,
      exportScopeValue: scope.value,
      createdAt: DateTime.now().toUtc(),
    );
    await exportRunRepository.save(exportRun);
    await auditLogService.logExportCreate(
      recordType: 'export_bundle',
      recordId: exportRun.id,
      after: <String, Object?>{
        'bundle_name': exportRun.bundleName,
        'bundle_path': exportRun.bundlePath,
        'bundle_checksum': exportRun.bundleChecksum,
        'scope_type': exportRun.exportScopeType,
        'scope_value': exportRun.exportScopeValue,
      },
      actorName: actorName,
    );
    return bundle;
  }

  List<ProjectEntity> _selectProjects(List<ProjectEntity> projects, ExportScopeRequest scope) {
    if (scope.type == 'project' && scope.value != null) {
      return projects.where((project) => project.id == scope.value || project.projectName == scope.value).toList(growable: false);
    }
    return projects;
  }

  List<TaskEntity> _selectTasks(List<TaskEntity> tasks, ExportScopeRequest scope, Set<String> selectedProjectIds) {
    if (scope.type == 'project' && selectedProjectIds.isNotEmpty) {
      return tasks.where((task) => task.projectId != null && selectedProjectIds.contains(task.projectId)).toList(growable: false);
    }
    return tasks;
  }

  List<MeetingEntity> _selectMeetings(List<MeetingEntity> meetings, ExportScopeRequest scope, Set<String> selectedProjectIds) {
    if (scope.type == 'project' && selectedProjectIds.isNotEmpty) {
      return meetings.where((meeting) => meeting.projectIds.any(selectedProjectIds.contains)).toList(growable: false);
    }
    return meetings;
  }

  Map<String, Object?> _projectRecord(ProjectEntity project) {
    return <String, Object?>{
      'id': project.id,
      'project_name': project.projectName,
      'client_oem': project.clientOem,
      'site_location': project.siteLocation,
      'site_contact_name': project.siteContactName,
      'site_contact_phone': project.siteContactPhone,
      'coordinator_name': project.coordinatorName,
      'project_manager_name': project.projectManagerName,
      'status': project.status,
      'notes': project.notes,
    };
  }

  Map<String, Object?> _taskRecord(TaskEntity task) {
    return <String, Object?>{
      'id': task.id,
      'project_id': task.projectId,
      'task_type': task.taskType.storageValue,
      'task_title': task.taskTitle,
      'description': task.description,
      'scheduled_date': task.scheduledDate?.toUtc().toIso8601String(),
      'start_time_local': task.startTimeLocal,
      'worker_name': task.workerName,
      'worker_phone': task.workerPhone,
      'coordinator_name': task.coordinatorName,
      'project_manager_name': task.projectManagerName,
      'agentee_name': task.agenteeName,
      'status': task.status.storageValue,
      'priority': task.priority.storageValue,
    };
  }

  Map<String, Object?> _meetingRecord(MeetingEntity meeting) {
    return <String, Object?>{
      'id': meeting.id,
      'title': meeting.title,
      'meeting_datetime': meeting.meetingDateTime?.toUtc().toIso8601String(),
      'meeting_timezone': meeting.meetingTimezone,
      'location_text': meeting.locationText,
      'summary': meeting.summary,
      'minutes_markdown': meeting.minutesMarkdown,
      'transcript_text': meeting.transcriptText,
      'review_state': meeting.reviewState.storageValue,
      'project_ids': meeting.projectIds,
    };
  }

  Map<String, Object?> _personRecord(PersonEntity person) {
    return <String, Object?>{
      'id': person.id,
      'name': person.name,
      'phone': person.phone,
      'role_hint': person.roleHint,
      'company': person.company,
      'notes': person.notes,
    };
  }

  Map<String, Object?> _bundleToJson(ImportExportBundleEntity bundle) {
    return <String, Object?>{
      'schema_version': bundle.schemaVersion,
      'bundle_id': bundle.bundleId,
      'exported_at': bundle.exportedAt.toUtc().toIso8601String(),
      'source_app': <String, Object?>{
        'name': bundle.sourceAppName,
        'version': bundle.sourceAppVersion,
      },
      'scope': <String, Object?>{
        'type': bundle.scope.type,
        'value': bundle.scope.value,
      },
      'records': <String, Object?>{
        'projects': bundle.projects,
        'tasks': bundle.tasks,
        'meetings': bundle.meetings,
        'people': bundle.people,
      },
      'attachments_manifest': bundle.attachmentsManifest
          .map(
            (attachment) => <String, Object?>{
              'attachment_id': attachment.attachmentId,
              'owner_record_type': attachment.ownerRecordType,
              'owner_record_id': attachment.ownerRecordId,
              'relative_path': attachment.relativePath,
              'checksum': attachment.checksum,
              'mime_type': attachment.mimeType,
            },
          )
          .toList(growable: false),
    };
  }

  static String _defaultExportRunIdFactory() {
    return 'export_run_${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }
}