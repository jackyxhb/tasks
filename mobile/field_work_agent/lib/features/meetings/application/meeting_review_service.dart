import '../../../core/audit/audit_log_service.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../data/database/repositories/raw_capture_repository.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/enums/meeting_review_state.dart';
import '../../../domain/enums/raw_capture_channel.dart';
import 'meeting_review_transition_policy.dart';

class MeetingReviewService {
  MeetingReviewService({
    required this.meetingRepository,
    required this.rawCaptureRepository,
    required this.auditLogService,
    MeetingReviewTransitionPolicy? transitionPolicy,
  }) : _transitionPolicy = transitionPolicy ?? const MeetingReviewTransitionPolicy();

  final MeetingRepository meetingRepository;
  final RawCaptureRepository rawCaptureRepository;
  final AuditLogService auditLogService;
  final MeetingReviewTransitionPolicy _transitionPolicy;

  Future<MeetingEntity> transitionMeeting({
    required String meetingId,
    required MeetingReviewState toState,
    String? actorName,
  }) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null) {
      throw StateError('Meeting not found: $meetingId');
    }

    _transitionPolicy.requireTransition(
      from: meeting.reviewState,
      to: toState,
    );

    if (toState == MeetingReviewState.finalized) {
      await _ensureCanFinalize(meeting);
    }

    final updatedMeeting = _copyMeeting(
      meeting,
      reviewState: toState,
      needsReview: _needsReviewForState(toState),
      updatedAt: DateTime.now().toUtc(),
      archivedAt: toState == MeetingReviewState.archived
          ? DateTime.now().toUtc()
          : (toState == MeetingReviewState.reopened ? null : meeting.archivedAt),
    );
    await meetingRepository.save(updatedMeeting);
    await _logTransition(
      before: meeting,
      after: updatedMeeting,
      actorName: actorName,
    );
    return updatedMeeting;
  }

  Future<MeetingEntity> moveToManualReviewOnly({
    required String meetingId,
    String? actorName,
  }) {
    return transitionMeeting(
      meetingId: meetingId,
      toState: MeetingReviewState.manualReviewOnly,
      actorName: actorName,
    );
  }

  Future<MeetingEntity> beginReview({
    required String meetingId,
    String? actorName,
  }) {
    return transitionMeeting(
      meetingId: meetingId,
      toState: MeetingReviewState.reviewInProgress,
      actorName: actorName,
    );
  }

  Future<MeetingEntity> markReviewRequired({
    required String meetingId,
    String? actorName,
  }) {
    return transitionMeeting(
      meetingId: meetingId,
      toState: MeetingReviewState.reviewRequired,
      actorName: actorName,
    );
  }

  Future<MeetingEntity> beginTaskCandidateResolution({
    required String meetingId,
    String? actorName,
  }) {
    return transitionMeeting(
      meetingId: meetingId,
      toState: MeetingReviewState.taskCandidateResolution,
      actorName: actorName,
    );
  }

  Future<MeetingEntity> finalizeMeeting({
    required String meetingId,
    String? actorName,
  }) {
    return transitionMeeting(
      meetingId: meetingId,
      toState: MeetingReviewState.finalized,
      actorName: actorName,
    );
  }

  Future<MeetingEntity> reopenMeeting({
    required String meetingId,
    String? actorName,
  }) {
    return transitionMeeting(
      meetingId: meetingId,
      toState: MeetingReviewState.reopened,
      actorName: actorName,
    );
  }

  Future<MeetingEntity> archiveMeeting({
    required String meetingId,
    String? actorName,
  }) {
    return transitionMeeting(
      meetingId: meetingId,
      toState: MeetingReviewState.archived,
      actorName: actorName,
    );
  }

  Future<MeetingEntity> cancelMeeting({
    required String meetingId,
    String? actorName,
  }) {
    return transitionMeeting(
      meetingId: meetingId,
      toState: MeetingReviewState.cancelled,
      actorName: actorName,
    );
  }

  Future<void> _ensureCanFinalize(MeetingEntity meeting) async {
    if (meeting.reviewState == MeetingReviewState.extractionFailed) {
      throw StateError(
        'Cannot finalize a meeting from extraction_failed. Move it to manual_review_only first.',
      );
    }

    if (meeting.sourceCaptureId != null) {
      final rawCapture = await rawCaptureRepository.findById(meeting.sourceCaptureId!);
      if (rawCapture == null) {
        throw StateError('Cannot finalize meeting with missing linked raw capture: ${meeting.sourceCaptureId}');
      }
      if (rawCapture.channel == RawCaptureChannel.audio && !_hasText(rawCapture.audioFilePath)) {
        throw StateError('Cannot finalize audio-origin meeting without a saved audio file path.');
      }
    }

    final hasTranscript = _hasText(meeting.transcriptText);
    final hasManualNotes = _hasText(meeting.summary) || _hasText(meeting.minutesMarkdown);
    if (!hasTranscript && !hasManualNotes) {
      throw StateError(
        'Cannot finalize meeting without a transcript or manual notes.',
      );
    }
  }

  Future<void> _logTransition({
    required MeetingEntity before,
    required MeetingEntity after,
    String? actorName,
  }) {
    switch (after.reviewState) {
      case MeetingReviewState.finalized:
        return auditLogService.logFinalize(
          recordType: 'meeting',
          recordId: after.id,
          before: _meetingSnapshot(before),
          after: _meetingSnapshot(after),
          sourceCaptureId: after.sourceCaptureId,
          actorName: actorName,
        );
      case MeetingReviewState.reopened:
        return auditLogService.logReopen(
          recordType: 'meeting',
          recordId: after.id,
          before: _meetingSnapshot(before),
          after: _meetingSnapshot(after),
          sourceCaptureId: after.sourceCaptureId,
          actorName: actorName,
        );
      case MeetingReviewState.archived:
        return auditLogService.logArchive(
          recordType: 'meeting',
          recordId: after.id,
          before: _meetingSnapshot(before),
          after: _meetingSnapshot(after),
          sourceCaptureId: after.sourceCaptureId,
          actorName: actorName,
        );
      default:
        return auditLogService.logUpdate(
          recordType: 'meeting',
          recordId: after.id,
          before: _meetingSnapshot(before),
          after: _meetingSnapshot(after),
          sourceCaptureId: after.sourceCaptureId,
          actorName: actorName,
        );
    }
  }

  MeetingEntity _copyMeeting(
    MeetingEntity source, {
    required MeetingReviewState reviewState,
    required bool needsReview,
    required DateTime updatedAt,
    required DateTime? archivedAt,
  }) {
    return MeetingEntity(
      id: source.id,
      title: source.title,
      meetingDateTime: source.meetingDateTime,
      meetingTimezone: source.meetingTimezone,
      locationText: source.locationText,
      summary: source.summary,
      minutesMarkdown: source.minutesMarkdown,
      transcriptText: source.transcriptText,
      sourceCaptureId: source.sourceCaptureId,
      sourceHash: source.sourceHash,
      reviewState: reviewState,
      needsReview: needsReview,
      projectIds: source.projectIds,
      taskCandidates: source.taskCandidates,
      createdAt: source.createdAt,
      updatedAt: updatedAt,
      archivedAt: archivedAt,
    );
  }

  Map<String, Object?> _meetingSnapshot(MeetingEntity meeting) {
    return <String, Object?>{
      'id': meeting.id,
      'review_state': meeting.reviewState.storageValue,
      'needs_review': meeting.needsReview,
      'transcript_present': _hasText(meeting.transcriptText),
      'summary_present': _hasText(meeting.summary),
      'minutes_present': _hasText(meeting.minutesMarkdown),
      'archived_at': meeting.archivedAt,
      'updated_at': meeting.updatedAt,
    };
  }

  bool _needsReviewForState(MeetingReviewState state) {
    switch (state) {
      case MeetingReviewState.finalized:
      case MeetingReviewState.archived:
      case MeetingReviewState.cancelled:
        return false;
      default:
        return true;
    }
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}