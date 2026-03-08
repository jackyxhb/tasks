import '../../../domain/entities/task_entity.dart';
import '../../../domain/enums/task_priority.dart';
import '../../../domain/enums/task_status.dart';
import '../../../domain/enums/task_type.dart';
import '../database_executor.dart';
import '../database_value_codec.dart';

class TaskRepository {
  const TaskRepository(this.executor);

  final DatabaseExecutor executor;

  Future<void> save(TaskEntity task) {
    return executor.execute(
      'INSERT OR REPLACE INTO tasks ('
      'id, project_id, task_type, task_title, task_title_normalized, '
      'description, scheduled_date, start_time_local, time_bucket, '
      'duration_minutes, location_snapshot, worker_name, worker_phone, '
      'coordinator_name, project_manager_name, agentee_name, status, '
      'priority, source_capture_id, dedup_key, is_provisional, needs_review, '
      'created_at, updated_at, archived_at'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        task.id,
        task.projectId,
        task.taskType.storageValue,
        task.taskTitle,
        task.taskTitleNormalized,
        task.description,
        task.scheduledDate?.toUtc().toIso8601String(),
        task.startTimeLocal,
        task.timeBucket,
        task.durationMinutes,
        task.locationSnapshot,
        task.workerName,
        task.workerPhone,
        task.coordinatorName,
        task.projectManagerName,
        task.agenteeName,
        task.status.storageValue,
        task.priority.storageValue,
        task.sourceCaptureId,
        task.dedupKey,
        DatabaseValueCodec.boolToSql(task.isProvisional),
        DatabaseValueCodec.boolToSql(task.needsReview),
        task.createdAt.toUtc().toIso8601String(),
        task.updatedAt.toUtc().toIso8601String(),
        task.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  Future<TaskEntity?> findById(String id) async {
    final rows = await executor.query(
      'SELECT * FROM tasks WHERE id = ? LIMIT 1',
      <Object?>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  Future<List<TaskEntity>> listAll() async {
    final rows = await executor.query(
      'SELECT * FROM tasks ORDER BY updated_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  TaskEntity _fromRow(DatabaseRow row) {
    return TaskEntity(
      id: DatabaseValueCodec.string(row['id']),
      projectId: DatabaseValueCodec.stringOrNull(row['project_id']),
      taskType: taskTypeFromStorage(DatabaseValueCodec.string(row['task_type'])),
      taskTitle: DatabaseValueCodec.stringOrNull(row['task_title']),
      taskTitleNormalized: DatabaseValueCodec.stringOrNull(
        row['task_title_normalized'],
      ),
      description: DatabaseValueCodec.stringOrNull(row['description']),
      scheduledDate: DatabaseValueCodec.dateTimeOrNull(row['scheduled_date']),
      startTimeLocal: DatabaseValueCodec.stringOrNull(row['start_time_local']),
      timeBucket: DatabaseValueCodec.stringOrNull(row['time_bucket']),
      durationMinutes: DatabaseValueCodec.intOrNull(row['duration_minutes']),
      locationSnapshot: DatabaseValueCodec.stringOrNull(
        row['location_snapshot'],
      ),
      workerName: DatabaseValueCodec.stringOrNull(row['worker_name']),
      workerPhone: DatabaseValueCodec.stringOrNull(row['worker_phone']),
      coordinatorName: DatabaseValueCodec.stringOrNull(
        row['coordinator_name'],
      ),
      projectManagerName: DatabaseValueCodec.stringOrNull(
        row['project_manager_name'],
      ),
      agenteeName: DatabaseValueCodec.string(row['agentee_name']),
      status: taskStatusFromStorage(DatabaseValueCodec.string(row['status'])),
      priority: taskPriorityFromStorage(
        DatabaseValueCodec.string(row['priority']),
      ),
      sourceCaptureId: DatabaseValueCodec.stringOrNull(row['source_capture_id']),
      dedupKey: DatabaseValueCodec.stringOrNull(row['dedup_key']),
      isProvisional: DatabaseValueCodec.boolFromSql(row['is_provisional']),
      needsReview: DatabaseValueCodec.boolFromSql(row['needs_review']),
      createdAt: DatabaseValueCodec.dateTime(row['created_at']),
      updatedAt: DatabaseValueCodec.dateTime(row['updated_at']),
      archivedAt: DatabaseValueCodec.dateTimeOrNull(row['archived_at']),
    );
  }
}