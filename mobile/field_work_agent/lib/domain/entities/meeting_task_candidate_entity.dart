import '../enums/task_candidate_state.dart';
import '../enums/task_type.dart';

class MeetingTaskCandidateEntity {
  const MeetingTaskCandidateEntity({
    required this.id,
    required this.taskType,
    required this.state,
    required this.confidence,
    required this.sourceSnippet,
    this.taskTitle,
    this.description,
    this.projectName,
    this.workerName,
    this.workerPhone,
    this.coordinatorName,
    this.projectManagerName,
    this.scheduledDateText,
    this.startTimeText,
    this.durationText,
    this.locationText,
    this.ambiguities = const <String>[],
  });

  final String id;
  final TaskType taskType;
  final TaskCandidateState state;
  final double confidence;
  final String sourceSnippet;
  final String? taskTitle;
  final String? description;
  final String? projectName;
  final String? workerName;
  final String? workerPhone;
  final String? coordinatorName;
  final String? projectManagerName;
  final String? scheduledDateText;
  final String? startTimeText;
  final String? durationText;
  final String? locationText;
  final List<String> ambiguities;
}