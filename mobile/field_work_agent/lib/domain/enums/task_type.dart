enum TaskType {
  siteSurvey,
  installation,
  tuning,
  handover,
  maintenance,
  unknown,
}

extension TaskTypeCodec on TaskType {
  String get storageValue {
    switch (this) {
      case TaskType.siteSurvey:
        return 'site_survey';
      case TaskType.installation:
        return 'installation';
      case TaskType.tuning:
        return 'tuning';
      case TaskType.handover:
        return 'handover';
      case TaskType.maintenance:
        return 'maintenance';
      case TaskType.unknown:
        return 'unknown';
    }
  }
}

TaskType taskTypeFromStorage(String value) {
  switch (value) {
    case 'site_survey':
      return TaskType.siteSurvey;
    case 'installation':
      return TaskType.installation;
    case 'tuning':
      return TaskType.tuning;
    case 'handover':
      return TaskType.handover;
    case 'maintenance':
      return TaskType.maintenance;
    default:
      return TaskType.unknown;
  }
}