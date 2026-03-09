import '../../../core/audit/audit_log_service.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/meeting_task_candidate_entity.dart';
import 'meeting_review_models.dart';

class MeetingReviewEditorService {
  const MeetingReviewEditorService({
    required this.meetingRepository,
    required this.auditLogService,
  });

  final MeetingRepository meetingRepository;
  final AuditLogService auditLogService;

  Future<MeetingEntity> updateMeetingDraft({
    required String meetingId,
    required MeetingReviewDraft draft,
    String? actorName,
  }) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null) {
      throw StateError('Meeting not found: $meetingId');
    }

    final updatedMeeting = MeetingEntity(
      id: meeting.id,
      title: meeting.title,
      meetingDateTime: meeting.meetingDateTime,
      meetingTimezone: meeting.meetingTimezone,
      locationText: meeting.locationText,
      summary: _trimOrNull(draft.summary),
      minutesMarkdown: _trimOrNull(draft.minutesMarkdown),
      transcriptText: _trimOrNull(draft.transcriptText),
      sourceCaptureId: meeting.sourceCaptureId,
      sourceHash: meeting.sourceHash,
      reviewState: meeting.reviewState,
      needsReview: meeting.needsReview,
      projectIds: draft.projectIds,
      taskCandidates: meeting.taskCandidates,
      createdAt: meeting.createdAt,
      updatedAt: DateTime.now().toUtc(),
      archivedAt: meeting.archivedAt,
    );

    await meetingRepository.save(updatedMeeting);
    await auditLogService.logUpdate(
      recordType: 'meeting',
      recordId: updatedMeeting.id,
      before: _meetingSnapshot(meeting),
      after: _meetingSnapshot(updatedMeeting),
      sourceCaptureId: updatedMeeting.sourceCaptureId,
      actorName: actorName,
    );
    return updatedMeeting;
  }

  Future<MeetingEntity> updateTaskCandidate({
    required String meetingId,
    required String candidateId,
    required MeetingTaskCandidateDraft draft,
    String? actorName,
  }) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null) {
      throw StateError('Meeting not found: $meetingId');
    }

    var found = false;
    final updatedCandidates = meeting.taskCandidates.map((candidate) {
      if (candidate.id != candidateId) {
        return candidate;
      }
      found = true;
      return MeetingTaskCandidateEntity(
        id: candidate.id,
        taskType: candidate.taskType,
        state: candidate.state,
        confidence: candidate.confidence,
        sourceSnippet: candidate.sourceSnippet,
        taskTitle: _firstNonEmpty(draft.taskTitle, candidate.taskTitle),
        description: _firstNonEmpty(draft.description, candidate.description),
        projectName: _firstNonEmpty(draft.projectName, candidate.projectName),
        workerName: _firstNonEmpty(draft.workerName, candidate.workerName),
        workerPhone: _firstNonEmpty(draft.workerPhone, candidate.workerPhone),
        coordinatorName: _firstNonEmpty(draft.coordinatorName, candidate.coordinatorName),
        projectManagerName: _firstNonEmpty(draft.projectManagerName, candidate.projectManagerName),
        scheduledDateText: _firstNonEmpty(draft.scheduledDateText, candidate.scheduledDateText),
        startTimeText: _firstNonEmpty(draft.startTimeText, candidate.startTimeText),
        durationText: _firstNonEmpty(draft.durationText, candidate.durationText),
        locationText: _firstNonEmpty(draft.locationText, candidate.locationText),
        ambiguities: draft.ambiguities,
        linkedTaskId: candidate.linkedTaskId,
      );
    }).toList(growable: false);

    if (!found) {
      throw StateError('Meeting task candidate not found: $candidateId');
    }

    final updatedMeeting = MeetingEntity(
      id: meeting.id,
      title: meeting.title,
      meetingDateTime: meeting.meetingDateTime,
      meetingTimezone: meeting.meetingTimezone,
      locationText: meeting.locationText,
      summary: meeting.summary,
      minutesMarkdown: meeting.minutesMarkdown,
      transcriptText: meeting.transcriptText,
      sourceCaptureId: meeting.sourceCaptureId,
      sourceHash: meeting.sourceHash,
      reviewState: meeting.reviewState,
      needsReview: meeting.needsReview,
      projectIds: meeting.projectIds,
      taskCandidates: updatedCandidates,
      createdAt: meeting.createdAt,
      updatedAt: DateTime.now().toUtc(),
      archivedAt: meeting.archivedAt,
    );

    await meetingRepository.save(updatedMeeting);
    await auditLogService.logUpdate(
      recordType: 'meeting',
      recordId: updatedMeeting.id,
      before: _meetingSnapshot(meeting),
      after: _meetingSnapshot(updatedMeeting),
      sourceCaptureId: updatedMeeting.sourceCaptureId,
      actorName: actorName,
    );
    return updatedMeeting;
  }

  Map<String, Object?> _meetingSnapshot(MeetingEntity meeting) {
    return <String, Object?>{
      'id': meeting.id,
      'summary': meeting.summary,
      'minutes_markdown': meeting.minutesMarkdown,
      'transcript_text': meeting.transcriptText,
      'project_ids': meeting.projectIds,
      'task_candidates': meeting.taskCandidates
          .map(
            (candidate) => <String, Object?>{
              'id': candidate.id,
              'state': candidate.state.storageValue,
              'task_title': candidate.taskTitle,
              'project_name': candidate.projectName,
              'linked_task_id': candidate.linkedTaskId,
            },
          )
          .toList(growable: false),
    };
  }

  String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _firstNonEmpty(String? primary, String? fallback) {
    return _trimOrNull(primary) ?? _trimOrNull(fallback);
  }
}