import '../../../domain/enums/task_priority.dart';
import '../../../domain/enums/task_status.dart';
import '../../../domain/enums/task_type.dart';

class TaskDraft {
  const TaskDraft({
    required this.taskType,
    required this.agenteeName,
    required this.status,
    required this.priority,
    required this.isProvisional,
    required this.needsReview,
    this.projectId,
    this.projectName,
    this.taskTitle,
    this.description,
    this.scheduledDate,
    this.startTimeLocal,
    this.durationMinutes,
    this.locationSnapshot,
    this.workerName,
    this.workerPhone,
    this.coordinatorName,
    this.projectManagerName,
    this.sourceCaptureId,
  });

  final String? projectId;
  final String? projectName;
  final TaskType taskType;
  final String? taskTitle;
  final String? description;
  final DateTime? scheduledDate;
  final String? startTimeLocal;
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
  final bool isProvisional;
  final bool needsReview;
}

class TaskFilter {
  const TaskFilter({
    this.projectId,
    this.taskTypes,
    this.statuses,
    this.priorities,
    this.needsReview,
    this.isProvisional,
    this.workerNameQuery,
    this.fromDate,
    this.toDate,
    this.includeArchived = false,
  });

  final String? projectId;
  final Set<TaskType>? taskTypes;
  final Set<TaskStatus>? statuses;
  final Set<TaskPriority>? priorities;
  final bool? needsReview;
  final bool? isProvisional;
  final String? workerNameQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool includeArchived;
}