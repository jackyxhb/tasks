import '../../../core/utils/text_normalizer.dart';
import '../../../domain/enums/task_type.dart';
import 'task_models.dart';

class TaskDedupKeyFactory {
  const TaskDedupKeyFactory();

  String? build(TaskDraft draft) {
    final normalizedProjectName = TextNormalizer.normalizeNullable(draft.projectName);
    final normalizedAgenteeName = TextNormalizer.normalizeNullable(draft.agenteeName);
    final scheduledDate = draft.scheduledDate;

    if (normalizedProjectName == null || normalizedAgenteeName == null || scheduledDate == null) {
      return null;
    }

    final datePart = _dateKey(scheduledDate.toUtc());
    final timeBucket = timeBucketFor(draft.startTimeLocal);
    final taskType = draft.taskType.storageValue;

    return '$datePart|$timeBucket|$normalizedProjectName|$normalizedAgenteeName|$taskType';
  }

  String timeBucketFor(String? startTimeLocal) {
    return _timeBucket(startTimeLocal);
  }

  String _dateKey(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _timeBucket(String? startTimeLocal) {
    if (startTimeLocal == null || startTimeLocal.trim().isEmpty) {
      return 'unscheduled';
    }

    final match = RegExp(r'^(\d{1,2})(?::(\d{2}))?$').firstMatch(startTimeLocal.trim());
    if (match == null) {
      return TextNormalizer.normalize(startTimeLocal);
    }

    final hour = int.parse(match.group(1)!);
    if (hour < 6) {
      return 'overnight';
    }
    if (hour < 12) {
      return 'morning';
    }
    if (hour < 17) {
      return 'afternoon';
    }
    return 'evening';
  }
}