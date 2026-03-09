import '../../../core/audit/audit_log_service.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../data/database/repositories/raw_capture_repository.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/raw_capture_entity.dart';
import '../../../domain/enums/meeting_review_state.dart';
import '../../../domain/enums/raw_capture_parse_status.dart';
import 'meeting_review_transition_policy.dart';
import 'transcription_provider.dart';
import 'transcription_result.dart';

class MeetingTranscriptService {
  const MeetingTranscriptService({
    required this.meetingRepository,
    required this.rawCaptureRepository,
    required this.auditLogService,
    MeetingReviewTransitionPolicy? transitionPolicy,
  }) : _transitionPolicy = transitionPolicy ?? const MeetingReviewTransitionPolicy();

  final MeetingRepository meetingRepository;
  final RawCaptureRepository rawCaptureRepository;
  final AuditLogService auditLogService;
  final MeetingReviewTransitionPolicy _transitionPolicy;

  Future<MeetingEntity> transcribeMeeting({
    required String meetingId,
    required TranscriptionProvider provider,
    String? actorName,
  }) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null || meeting.sourceCaptureId == null) {
      throw StateError('Meeting is missing a linked raw capture: $meetingId');
    }
    final rawCapture = await rawCaptureRepository.findById(meeting.sourceCaptureId!);
    if (rawCapture == null || rawCapture.audioFilePath == null) {
      throw StateError('Raw capture is missing an audio file path: ${meeting.sourceCaptureId}');
    }

    _transitionPolicy.requireTransition(
      from: meeting.reviewState,
      to: MeetingReviewState.transcribing,
    );
    final transcribingMeeting = _copyMeeting(
      meeting,
      reviewState: MeetingReviewState.transcribing,
      updatedAt: DateTime.now().toUtc(),
    );
    await meetingRepository.save(transcribingMeeting);
    await auditLogService.logUpdate(
      recordType: 'meeting',
      recordId: transcribingMeeting.id,
      before: _meetingSnapshot(meeting),
      after: <String, Object?>{
        ..._meetingSnapshot(transcribingMeeting),
        'transcription_status': 'requested',
      },
      sourceCaptureId: transcribingMeeting.sourceCaptureId,
      actorName: actorName,
    );

    try {
      final result = await provider.transcribe(
        audioFilePath: rawCapture.audioFilePath!,
      );
      final updatedCapture = _copyCapture(
        rawCapture,
        transcriptText: result.rawTranscript,
        transcriptionProvider: result.providerName,
        transcriptionModel: result.providerModel,
        transcriptionError: null,
        parseStatus: RawCaptureParseStatus.parsed,
        parseVersion: result.parseVersion,
      );
      _transitionPolicy.requireTransition(
        from: transcribingMeeting.reviewState,
        to: MeetingReviewState.transcribedPendingExtraction,
      );
      final updatedMeeting = _copyMeeting(
        transcribingMeeting,
        transcriptText: result.cleanedTranscript ?? result.rawTranscript,
        reviewState: MeetingReviewState.transcribedPendingExtraction,
        updatedAt: DateTime.now().toUtc(),
      );

      await rawCaptureRepository.save(updatedCapture);
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
    } catch (error) {
      final failure = error is TranscriptionFailure
          ? error
          : TranscriptionFailure(
              providerName: 'unknown',
              providerModel: 'unknown',
              message: error.toString(),
            );
      final failedCapture = _copyCapture(
        rawCapture,
        transcriptionProvider: failure.providerName,
        transcriptionModel: failure.providerModel,
        transcriptionError: failure.message,
        parseStatus: RawCaptureParseStatus.failed,
        parseVersion: failure.parseVersion,
      );
      _transitionPolicy.requireTransition(
        from: transcribingMeeting.reviewState,
        to: MeetingReviewState.transcriptionFailed,
      );
      final failedMeeting = _copyMeeting(
        transcribingMeeting,
        reviewState: MeetingReviewState.transcriptionFailed,
        updatedAt: DateTime.now().toUtc(),
      );

      await rawCaptureRepository.save(failedCapture);
      await meetingRepository.save(failedMeeting);
      await auditLogService.logUpdate(
        recordType: 'meeting',
        recordId: failedMeeting.id,
        before: _meetingSnapshot(meeting),
        after: _meetingSnapshot(failedMeeting),
        sourceCaptureId: failedMeeting.sourceCaptureId,
        actorName: actorName,
      );
      return failedMeeting;
    }
  }

  RawCaptureEntity _copyCapture(
    RawCaptureEntity source, {
    String? transcriptText,
    String? transcriptionProvider,
    String? transcriptionModel,
    String? transcriptionError,
    RawCaptureParseStatus? parseStatus,
    String? parseVersion,
  }) {
    return RawCaptureEntity(
      id: source.id,
      channel: source.channel,
      rawText: source.rawText,
      transcriptText: transcriptText ?? source.transcriptText,
      transcriptionProvider: transcriptionProvider ?? source.transcriptionProvider,
      transcriptionModel: transcriptionModel ?? source.transcriptionModel,
      transcriptionError: transcriptionError ?? source.transcriptionError,
      audioFilePath: source.audioFilePath,
      attachmentGroupId: source.attachmentGroupId,
      captureTime: source.captureTime,
      captureTimezone: source.captureTimezone,
      capturedByAgenteeName: source.capturedByAgenteeName,
      classificationType: source.classificationType,
      classificationConfidence: source.classificationConfidence,
      parseStatus: parseStatus ?? source.parseStatus,
      parseVersion: parseVersion ?? source.parseVersion,
      sourceHash: source.sourceHash,
      createdAt: source.createdAt,
    );
  }

  MeetingEntity _copyMeeting(
    MeetingEntity source, {
    String? transcriptText,
    MeetingReviewState? reviewState,
    DateTime? updatedAt,
  }) {
    return MeetingEntity(
      id: source.id,
      title: source.title,
      meetingDateTime: source.meetingDateTime,
      meetingTimezone: source.meetingTimezone,
      locationText: source.locationText,
      summary: source.summary,
      minutesMarkdown: source.minutesMarkdown,
      transcriptText: transcriptText ?? source.transcriptText,
      sourceCaptureId: source.sourceCaptureId,
      sourceHash: source.sourceHash,
      reviewState: reviewState ?? source.reviewState,
      needsReview: source.needsReview,
      projectIds: source.projectIds,
      taskCandidates: source.taskCandidates,
      createdAt: source.createdAt,
      updatedAt: updatedAt ?? source.updatedAt,
      archivedAt: source.archivedAt,
    );
  }

  Map<String, Object?> _meetingSnapshot(MeetingEntity meeting) {
    return <String, Object?>{
      'id': meeting.id,
      'transcript_text': meeting.transcriptText,
      'review_state': meeting.reviewState.storageValue,
      'updated_at': meeting.updatedAt,
    };
  }
}