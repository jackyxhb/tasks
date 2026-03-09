import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/meeting_task_candidate_entity.dart';
import '../../../domain/entities/project_entity.dart';

class MeetingReviewDraft {
  const MeetingReviewDraft({
    required this.transcriptText,
    required this.summary,
    required this.minutesMarkdown,
    required this.projectIds,
  });

  final String? transcriptText;
  final String? summary;
  final String? minutesMarkdown;
  final List<String> projectIds;
}

class MeetingTaskCandidateDraft {
  const MeetingTaskCandidateDraft({
    required this.taskTitle,
    required this.description,
    required this.projectName,
    required this.workerName,
    required this.workerPhone,
    required this.coordinatorName,
    required this.projectManagerName,
    required this.scheduledDateText,
    required this.startTimeText,
    required this.durationText,
    required this.locationText,
    required this.ambiguities,
  });

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

class MeetingReviewCandidateView {
  const MeetingReviewCandidateView({
    required this.candidate,
    required this.linkedProject,
    required this.isResolved,
  });

  final MeetingTaskCandidateEntity candidate;
  final ProjectEntity? linkedProject;
  final bool isResolved;
}

class MeetingReviewViewModel {
  const MeetingReviewViewModel({
    required this.meeting,
    required this.linkedProjects,
    required this.candidates,
    required this.hasTranscript,
    required this.hasMinutes,
    required this.unresolvedCandidateCount,
  });

  final MeetingEntity meeting;
  final List<ProjectEntity> linkedProjects;
  final List<MeetingReviewCandidateView> candidates;
  final bool hasTranscript;
  final bool hasMinutes;
  final int unresolvedCandidateCount;
}