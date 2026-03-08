import '../enums/task_priority.dart';
import '../enums/task_status.dart';
import '../enums/task_type.dart';

class TaskEntity {
  const TaskEntity({
    required this.id,
    required this.taskType,
    required this.agenteeName,
    required this.status,
    required this.priority,
    required this.isProvisional,
    required this.needsReview,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.taskTitle,
    this.taskTitleNormalized,
    this.description,
    this.scheduledDate,
    this.startTimeLocal,
    this.timeBucket,
    this.durationMinutes,
    this.locationSnapshot,
    this.workerName,
    this.workerPhone,
    this.coordinatorName,
    this.projectManagerName,
    this.sourceCaptureId,
    this.dedupKey,
    this.archivedAt,
  });

  final String id;
  final String? projectId;
  final TaskType taskType;
  final String? taskTitle;
  final String? taskTitleNormalized;
  final String? description;
  final DateTime? scheduledDate;
  final String? startTimeLocal;
  final String? timeBucket;
  final int? durationMinutes;
  final String? locationSnapshot;
  final String? workerName;
  final String? workerPhone;
  final String? coordinatorName;
  final String? projectManagerName;
  final String agenteeName;
  final TaskStatus status;
  final TaskPriority priority;
  final String? sourceCaptureId;
  final String? dedupKey;
  final bool isProvisional;
  final bool needsReview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}