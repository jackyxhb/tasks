enum TaskStatus {
  planned,
  inProgress,
  blocked,
  completed,
  cancelled,
}

extension TaskStatusCodec on TaskStatus {
  String get storageValue {
    switch (this) {
      case TaskStatus.planned:
        return 'planned';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.blocked:
        return 'blocked';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }
}

TaskStatus taskStatusFromStorage(String value) {
  switch (value) {
    case 'in_progress':
      return TaskStatus.inProgress;
    case 'blocked':
      return TaskStatus.blocked;
    case 'completed':
      return TaskStatus.completed;
    case 'cancelled':
      return TaskStatus.cancelled;
    default:
      return TaskStatus.planned;
  }
}