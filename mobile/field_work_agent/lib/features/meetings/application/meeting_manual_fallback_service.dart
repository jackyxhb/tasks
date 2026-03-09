import '../../../core/audit/audit_log_service.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/enums/meeting_review_state.dart';
import 'meeting_review_models.dart';
import 'meeting_review_transition_policy.dart';

class MeetingManualFallbackService {
  MeetingManualFallbackService({
    required this.meetingRepository,
    required this.auditLogService,
    MeetingReviewTransitionPolicy? transitionPolicy,
  }) : _transitionPolicy = transitionPolicy ?? const MeetingReviewTransitionPolicy();

  final MeetingRepository meetingRepository;
  final AuditLogService auditLogService;
  final MeetingReviewTransitionPolicy _transitionPolicy;

  Future<MeetingEntity> prepareManualReview({
    required String meetingId,
    required String reason,
    MeetingReviewDraft? draft,
    String? actorName,
  }) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null) {
      throw StateError('Meeting not found: $meetingId');
    }

    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw StateError('Manual fallback reason is required.');
    }

    final nextState = meeting.reviewState == MeetingReviewState.manualReviewOnly
        ? MeetingReviewState.manualReviewOnly
        : MeetingReviewState.manualReviewOnly;
    if (meeting.reviewState != nextState) {
      _transitionPolicy.requireTransition(
        from: meeting.reviewState,
        to: nextState,
      );
    }

    final updatedMeeting = MeetingEntity(
      id: meeting.id,
      title: meeting.title,
      meetingDateTime: meeting.meetingDateTime,
      meetingTimezone: meeting.meetingTimezone,
      locationText: meeting.locationText,
      summary: _firstNonEmpty(draft?.summary, meeting.summary),
      minutesMarkdown: _firstNonEmpty(draft?.minutesMarkdown, meeting.minutesMarkdown),
      transcriptText: _firstNonEmpty(draft?.transcriptText, meeting.transcriptText),
      sourceCaptureId: meeting.sourceCaptureId,
      sourceHash: meeting.sourceHash,
      reviewState: nextState,
      needsReview: true,
      projectIds: draft?.projectIds ?? meeting.projectIds,
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
      after: <String, Object?>{
        ..._meetingSnapshot(updatedMeeting),
        'manual_fallback_reason': trimmedReason,
        'manual_fallback_ready': true,
      },
      sourceCaptureId: updatedMeeting.sourceCaptureId,
      actorName: actorName,
    );

    return updatedMeeting;
  }

  Map<String, Object?> _meetingSnapshot(MeetingEntity meeting) {
    return <String, Object?>{
      'id': meeting.id,
      'review_state': meeting.reviewState.storageValue,
      'needs_review': meeting.needsReview,
      'transcript_present': _hasText(meeting.transcriptText),
      'summary_present': _hasText(meeting.summary),
      'minutes_present': _hasText(meeting.minutesMarkdown),
      'project_ids': meeting.projectIds,
      'updated_at': meeting.updatedAt,
    };
  }

  String? _firstNonEmpty(String? primary, String? fallback) {
    if (_hasText(primary)) {
      return primary!.trim();
    }
    if (_hasText(fallback)) {
      return fallback!.trim();
    }
    return null;
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}