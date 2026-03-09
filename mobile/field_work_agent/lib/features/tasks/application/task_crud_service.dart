import '../../../core/audit/audit_log_service.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../data/database/repositories/task_repository.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/enums/task_priority.dart';
import '../../../domain/enums/task_status.dart';
import '../../../domain/enums/task_type.dart';
import 'task_dedup_key_factory.dart';
import 'task_models.dart';

typedef TaskIdFactory = String Function();
typedef TaskClock = DateTime Function();

class TaskCrudService {
  TaskCrudService({
    required this.repository,
    required this.auditLogService,
    TaskDedupKeyFactory? dedupKeyFactory,
    TaskIdFactory? idFactory,
    TaskClock? clock,
  })  : _dedupKeyFactory = dedupKeyFactory ?? const TaskDedupKeyFactory(),
        _idFactory = idFactory ?? _defaultIdFactory,
        _clock = clock ?? _defaultClock;

  final TaskRepository repository;
  final AuditLogService auditLogService;
  final TaskDedupKeyFactory _dedupKeyFactory;
  final TaskIdFactory _idFactory;
  final TaskClock _clock;

  Future<TaskEntity> create(TaskDraft draft, {String? actorName}) async {
    final now = _clock().toUtc();
    final task = _buildEntity(
      id: _idFactory(),
      draft: draft,
      createdAt: now,
      updatedAt: now,
    );

    await repository.save(task);
    await auditLogService.logCreate(
      recordType: 'task',
      recordId: task.id,
      after: _snapshot(task),
      sourceCaptureId: task.sourceCaptureId,
      actorName: actorName,
    );
    return task;
  }

  Future<TaskEntity> update(
    String taskId,
    TaskDraft draft, {
    String? actorName,
  }) async {
    final existing = await requireDetail(taskId);
    final updated = _buildEntity(
      id: existing.id,
      draft: draft,
      createdAt: existing.createdAt,
      updatedAt: _clock().toUtc(),
      archivedAt: existing.archivedAt,
    );

    await repository.save(updated);
    await auditLogService.logUpdate(
      recordType: 'task',
      recordId: updated.id,
      before: _snapshot(existing),
      after: _snapshot(updated),
      sourceCaptureId: updated.sourceCaptureId,
      actorName: actorName,
    );
    return updated;
  }

  Future<TaskEntity> archive(String taskId, {String? actorName}) async {
    final existing = await requireDetail(taskId);
    final archivedAt = _clock().toUtc();
    final archived = TaskEntity(
      id: existing.id,
      projectId: existing.projectId,
      taskType: existing.taskType,
      taskTitle: existing.taskTitle,
      taskTitleNormalized: existing.taskTitleNormalized,
      description: existing.description,
      scheduledDate: existing.scheduledDate,
      startTimeLocal: existing.startTimeLocal,
      timeBucket: existing.timeBucket,
      durationMinutes: existing.durationMinutes,
      locationSnapshot: existing.locationSnapshot,
      workerName: existing.workerName,
      workerPhone: existing.workerPhone,
      coordinatorName: existing.coordinatorName,
      projectManagerName: existing.projectManagerName,
      agenteeName: existing.agenteeName,
      status: existing.status,
      priority: existing.priority,
      sourceCaptureId: existing.sourceCaptureId,
      dedupKey: existing.dedupKey,
      isProvisional: existing.isProvisional,
      needsReview: existing.needsReview,
      createdAt: existing.createdAt,
      updatedAt: archivedAt,
      archivedAt: archivedAt,
    );

    await repository.save(archived);
    await auditLogService.logArchive(
      recordType: 'task',
      recordId: archived.id,
      before: _snapshot(existing),
      after: _snapshot(archived),
      sourceCaptureId: archived.sourceCaptureId,
      actorName: actorName,
    );
    return archived;
  }

  Future<TaskEntity?> detail(String taskId) {
    return repository.findById(taskId);
  }

  Future<TaskEntity> requireDetail(String taskId) async {
    final task = await detail(taskId);
    if (task == null) {
      throw StateError('Task not found: $taskId');
    }
    return task;
  }

  Future<List<TaskEntity>> browse({TaskFilter filter = const TaskFilter()}) async {
    final tasks = await repository.listAll();
    final normalizedWorkerQuery = TextNormalizer.normalizeNullable(filter.workerNameQuery);

    return tasks.where((task) {
      if (!filter.includeArchived && task.archivedAt != null) {
        return false;
      }
      if (filter.projectId != null && task.projectId != filter.projectId) {
        return false;
      }
      if (filter.taskTypes != null && !filter.taskTypes!.contains(task.taskType)) {
        return false;
      }
      if (filter.statuses != null && !filter.statuses!.contains(task.status)) {
        return false;
      }
      if (filter.priorities != null && !filter.priorities!.contains(task.priority)) {
        return false;
      }
      if (filter.needsReview != null && task.needsReview != filter.needsReview) {
        return false;
      }
      if (filter.isProvisional != null && task.isProvisional != filter.isProvisional) {
        return false;
      }
      if (filter.fromDate != null) {
        final taskDate = task.scheduledDate;
        if (taskDate == null || taskDate.isBefore(filter.fromDate!)) {
          return false;
        }
      }
      if (filter.toDate != null) {
        final taskDate = task.scheduledDate;
        if (taskDate == null || taskDate.isAfter(filter.toDate!)) {
          return false;
        }
      }
      if (normalizedWorkerQuery != null) {
        final normalizedWorker = TextNormalizer.normalizeNullable(task.workerName);
        if (normalizedWorker == null || !normalizedWorker.contains(normalizedWorkerQuery)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  TaskEntity _buildEntity({
    required String id,
    required TaskDraft draft,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? archivedAt,
  }) {
    final trimmedTaskTitle = _trimOrNull(draft.taskTitle);
    final dedupKey = _dedupKeyFactory.build(draft);
    if (!draft.isProvisional && dedupKey == null) {
      throw StateError(
        'Finalized tasks require enough data to compute a dedup key.',
      );
    }

    return TaskEntity(
      id: id,
      projectId: _trimOrNull(draft.projectId),
      taskType: draft.taskType,
      taskTitle: trimmedTaskTitle,
      taskTitleNormalized: TextNormalizer.normalizeNullable(trimmedTaskTitle),
      description: _trimOrNull(draft.description),
      scheduledDate: draft.scheduledDate?.toUtc(),
      startTimeLocal: _trimOrNull(draft.startTimeLocal),
      timeBucket: _dedupKeyFactory.timeBucketFor(draft.startTimeLocal),
      durationMinutes: draft.durationMinutes,
      locationSnapshot: _trimOrNull(draft.locationSnapshot),
      workerName: _trimOrNull(draft.workerName),
      workerPhone: _trimOrNull(draft.workerPhone),
      coordinatorName: _trimOrNull(draft.coordinatorName),
      projectManagerName: _trimOrNull(draft.projectManagerName),
      agenteeName: draft.agenteeName.trim(),
      status: draft.status,
      priority: draft.priority,
      sourceCaptureId: _trimOrNull(draft.sourceCaptureId),
      dedupKey: dedupKey,
      isProvisional: draft.isProvisional,
      needsReview: draft.needsReview,
      createdAt: createdAt,
      updatedAt: updatedAt,
      archivedAt: archivedAt,
    );
  }

  Map<String, Object?> _snapshot(TaskEntity task) {
    return <String, Object?>{
      'id': task.id,
      'project_id': task.projectId,
      'task_type': task.taskType.storageValue,
      'task_title': task.taskTitle,
      'task_title_normalized': task.taskTitleNormalized,
      'description': task.description,
      'scheduled_date': task.scheduledDate,
      'start_time_local': task.startTimeLocal,
      'time_bucket': task.timeBucket,
      'duration_minutes': task.durationMinutes,
      'location_snapshot': task.locationSnapshot,
      'worker_name': task.workerName,
      'worker_phone': task.workerPhone,
      'coordinator_name': task.coordinatorName,
      'project_manager_name': task.projectManagerName,
      'agentee_name': task.agenteeName,
      'status': task.status.storageValue,
      'priority': task.priority.storageValue,
      'source_capture_id': task.sourceCaptureId,
      'dedup_key': task.dedupKey,
      'is_provisional': task.isProvisional,
      'needs_review': task.needsReview,
      'created_at': task.createdAt,
      'updated_at': task.updatedAt,
      'archived_at': task.archivedAt,
    };
  }

  String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _defaultIdFactory() {
    return 'task_${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  static DateTime _defaultClock() => DateTime.now();
}