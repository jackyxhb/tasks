import '../../../core/audit/audit_log_service.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/meeting_task_candidate_entity.dart';
import '../../../domain/enums/meeting_review_state.dart';
import '../../../domain/enums/task_candidate_state.dart';
import 'meeting_extraction_payload.dart';
import 'meeting_extraction_validator.dart';
import 'meeting_review_transition_policy.dart';

class MeetingExtractionApplicationResult {
  const MeetingExtractionApplicationResult({
    required this.meeting,
    required this.validationIssues,
    this.payload,
  });

  final MeetingEntity meeting;
  final MeetingExtractionPayload? payload;
  final List<MeetingExtractionValidationIssue> validationIssues;

  bool get isSuccess => payload != null && validationIssues.isEmpty;
}

class MeetingExtractionService {
  MeetingExtractionService({
    required this.meetingRepository,
    required this.auditLogService,
    MeetingReviewTransitionPolicy? transitionPolicy,
    MeetingExtractionValidator? extractionValidator,
  })  : _transitionPolicy = transitionPolicy ?? const MeetingReviewTransitionPolicy(),
        _extractionValidator = extractionValidator ?? const MeetingExtractionValidator();

  final MeetingRepository meetingRepository;
  final AuditLogService auditLogService;
  final MeetingReviewTransitionPolicy _transitionPolicy;
  final MeetingExtractionValidator _extractionValidator;

  Future<MeetingExtractionApplicationResult> applyExtractionJson({
    required String meetingId,
    required String extractionJson,
    String? actorName,
  }) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null) {
      throw StateError('Meeting not found: $meetingId');
    }
    if (!_hasText(meeting.transcriptText)) {
      throw StateError('Cannot extract meeting without a transcript: $meetingId');
    }

    _transitionPolicy.requireTransition(
      from: meeting.reviewState,
      to: MeetingReviewState.extracting,
    );
    final extractingMeeting = _copyMeeting(
      meeting,
      reviewState: MeetingReviewState.extracting,
      updatedAt: DateTime.now().toUtc(),
    );
    await meetingRepository.save(extractingMeeting);
    await auditLogService.logAiExtract(
      recordType: 'meeting',
      recordId: extractingMeeting.id,
      before: _meetingSnapshot(meeting),
      after: <String, Object?>{
        ..._meetingSnapshot(extractingMeeting),
        'extraction_status': 'requested',
      },
      sourceCaptureId: extractingMeeting.sourceCaptureId,
      actorName: actorName,
    );

    final validation = _extractionValidator.validateJson(extractionJson);
    if (!validation.isValid || validation.payload == null) {
      _transitionPolicy.requireTransition(
        from: extractingMeeting.reviewState,
        to: MeetingReviewState.extractionFailed,
      );
      final failedMeeting = _copyMeeting(
        extractingMeeting,
        reviewState: MeetingReviewState.extractionFailed,
        updatedAt: DateTime.now().toUtc(),
      );
      await meetingRepository.save(failedMeeting);
      await auditLogService.logAiExtract(
        recordType: 'meeting',
        recordId: failedMeeting.id,
        before: _meetingSnapshot(extractingMeeting),
        after: <String, Object?>{
          ..._meetingSnapshot(failedMeeting),
          'extraction_status': 'validation_failed',
          'validation_issues': validation.issues
              .map((issue) => issue.toJson())
              .toList(growable: false),
        },
        sourceCaptureId: failedMeeting.sourceCaptureId,
        actorName: actorName,
      );
      return MeetingExtractionApplicationResult(
        meeting: failedMeeting,
        validationIssues: validation.issues,
      );
    }

    final payload = validation.payload!;
    final updatedMeeting = _copyMeeting(
      extractingMeeting,
      title: payload.meeting.title,
      locationText: payload.meeting.meetingLocationText,
      summary: payload.meeting.summary,
      minutesMarkdown: _minutesMarkdownFromPayload(payload) ?? extractingMeeting.minutesMarkdown,
      transcriptText: payload.transcription.cleanedTranscript ??
          payload.transcription.rawTranscript ??
          extractingMeeting.transcriptText,
      taskCandidates: payload.taskCandidates
          .map(
            (candidate) => MeetingTaskCandidateEntity(
              id: candidate.id,
              taskType: candidate.taskType,
              state: TaskCandidateState.newCandidate,
              confidence: candidate.confidence,
              sourceSnippet: candidate.sourceSnippet,
              taskTitle: candidate.taskTitle,
              description: candidate.description,
              projectName: candidate.projectName,
              workerName: candidate.workerName,
              workerPhone: candidate.workerPhone,
              coordinatorName: candidate.coordinatorName,
              projectManagerName: candidate.projectManagerName,
              scheduledDateText: candidate.scheduledDateText,
              startTimeText: candidate.startTimeText,
              durationText: candidate.durationText,
              locationText: candidate.locationText,
              ambiguities: candidate.ambiguities,
            ),
          )
          .toList(growable: false),
      reviewState: MeetingReviewState.reviewRequired,
      updatedAt: DateTime.now().toUtc(),
    );
    await meetingRepository.save(updatedMeeting);
    await auditLogService.logAiExtract(
      recordType: 'meeting',
      recordId: updatedMeeting.id,
      before: _meetingSnapshot(extractingMeeting),
      after: <String, Object?>{
        ..._meetingSnapshot(updatedMeeting),
        'extraction_status': 'validated',
        'request_id': payload.requestId,
        'provider_name': payload.provider.name,
        'provider_model': payload.provider.model,
        'project_candidate_count': payload.projectCandidates.length,
        'task_candidate_count': payload.taskCandidates.length,
        'warning_count': payload.warnings.length,
      },
      sourceCaptureId: updatedMeeting.sourceCaptureId,
      actorName: actorName,
    );

    return MeetingExtractionApplicationResult(
      meeting: updatedMeeting,
      payload: payload,
      validationIssues: const <MeetingExtractionValidationIssue>[],
    );
  }

  MeetingEntity _copyMeeting(
    MeetingEntity source, {
    String? title,
    String? locationText,
    String? summary,
    String? minutesMarkdown,
    String? transcriptText,
    List<MeetingTaskCandidateEntity>? taskCandidates,
    MeetingReviewState? reviewState,
    DateTime? updatedAt,
  }) {
    return MeetingEntity(
      id: source.id,
      title: _firstNonEmpty(title, source.title),
      meetingDateTime: source.meetingDateTime,
      meetingTimezone: source.meetingTimezone,
      locationText: _firstNonEmpty(locationText, source.locationText),
      summary: _firstNonEmpty(summary, source.summary),
      minutesMarkdown: _firstNonEmpty(minutesMarkdown, source.minutesMarkdown),
      transcriptText: _firstNonEmpty(transcriptText, source.transcriptText),
      sourceCaptureId: source.sourceCaptureId,
      sourceHash: source.sourceHash,
      reviewState: reviewState ?? source.reviewState,
      needsReview: true,
      projectIds: source.projectIds,
      taskCandidates: taskCandidates ?? source.taskCandidates,
      createdAt: source.createdAt,
      updatedAt: updatedAt ?? source.updatedAt,
      archivedAt: source.archivedAt,
    );
  }

  Map<String, Object?> _meetingSnapshot(MeetingEntity meeting) {
    return <String, Object?>{
      'id': meeting.id,
      'title': meeting.title,
      'location_text': meeting.locationText,
      'summary': meeting.summary,
      'minutes_markdown': meeting.minutesMarkdown,
      'transcript_text': meeting.transcriptText,
      'review_state': meeting.reviewState.storageValue,
      'needs_review': meeting.needsReview,
      'updated_at': meeting.updatedAt,
    };
  }

  String? _minutesMarkdownFromPayload(MeetingExtractionPayload payload) {
    final buffer = StringBuffer();

    void writeSection(String heading, List<String> lines) {
      if (lines.isEmpty) {
        return;
      }
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.writeln(heading);
      for (final line in lines) {
        buffer.writeln('- $line');
      }
    }

    writeSection(
      'Minutes',
      payload.meeting.minutesItems.map((item) => item.text).toList(growable: false),
    );
    writeSection(
      'Decisions',
      payload.meeting.decisionItems.map((item) => item.text).toList(growable: false),
    );
    writeSection(
      'Open Questions',
      payload.meeting.openQuestions.map((item) => item.text).toList(growable: false),
    );

    final markdown = buffer.toString().trim();
    return markdown.isEmpty ? null : markdown;
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