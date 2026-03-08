import '../enums/meeting_review_state.dart';
import 'meeting_task_candidate_entity.dart';

class MeetingEntity {
  const MeetingEntity({
    required this.id,
    required this.reviewState,
    required this.needsReview,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.meetingDateTime,
    this.meetingTimezone,
    this.locationText,
    this.summary,
    this.minutesMarkdown,
    this.transcriptText,
    this.sourceCaptureId,
    this.sourceHash,
    this.projectIds = const <String>[],
    this.taskCandidates = const <MeetingTaskCandidateEntity>[],
    this.archivedAt,
  });

  final String id;
  final String? title;
  final DateTime? meetingDateTime;
  final String? meetingTimezone;
  final String? locationText;
  final String? summary;
  final String? minutesMarkdown;
  final String? transcriptText;
  final String? sourceCaptureId;
  final String? sourceHash;
  final MeetingReviewState reviewState;
  final bool needsReview;
  final List<String> projectIds;
  final List<MeetingTaskCandidateEntity> taskCandidates;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}