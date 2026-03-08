enum TaskPriority {
  low,
  medium,
  high,
  critical,
}

extension TaskPriorityCodec on TaskPriority {
  String get storageValue {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.critical:
        return 'critical';
    }
  }
}

TaskPriority taskPriorityFromStorage(String value) {
  switch (value) {
    case 'low':
      return TaskPriority.low;
    case 'high':
      return TaskPriority.high;
    case 'critical':
      return TaskPriority.critical;
    default:
      return TaskPriority.medium;
  }
}