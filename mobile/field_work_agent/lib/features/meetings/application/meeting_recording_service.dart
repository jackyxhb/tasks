import 'dart:io';

import '../../../core/audit/audit_log_service.dart';
import '../../../core/storage/local_file_storage_service.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../data/database/repositories/raw_capture_repository.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/raw_capture_entity.dart';
import '../../../domain/enums/meeting_review_state.dart';
import '../../../domain/enums/raw_capture_channel.dart';
import '../../capture/application/raw_capture_intake_service.dart';
import 'meeting_recording_session.dart';
import 'meeting_review_transition_policy.dart';

typedef MeetingIdFactory = String Function();
typedef MeetingClock = DateTime Function();

class MeetingRecordingService {
  MeetingRecordingService({
    required this.meetingRepository,
    required this.rawCaptureRepository,
    required this.rawCaptureIntakeService,
    required this.fileStorageService,
    required this.auditLogService,
    MeetingReviewTransitionPolicy? transitionPolicy,
    MeetingIdFactory? meetingIdFactory,
    MeetingClock? clock,
  })  : _meetingIdFactory = meetingIdFactory ?? _defaultMeetingIdFactory,
        _transitionPolicy = transitionPolicy ?? const MeetingReviewTransitionPolicy(),
        _clock = clock ?? _defaultClock;

  final MeetingRepository meetingRepository;
  final RawCaptureRepository rawCaptureRepository;
  final RawCaptureIntakeService rawCaptureIntakeService;
  final LocalFileStorageService fileStorageService;
  final AuditLogService auditLogService;
  final MeetingReviewTransitionPolicy _transitionPolicy;
  final MeetingIdFactory _meetingIdFactory;
  final MeetingClock _clock;

  Future<MeetingRecordingSession> startRecording({
    String? title,
    String? captureTimezone,
    String? capturedByAgenteeName,
    List<String> projectIds = const <String>[],
    String? actorName,
  }) async {
    final startedAt = _clock().toUtc();
    final fileReference = await fileStorageService.prepareFile(
      directory: LocalStorageDirectory.audio,
      fileName: 'meeting_${startedAt.microsecondsSinceEpoch}.m4a',
    );

    final rawCapture = await rawCaptureIntakeService.createAudioCapture(
      audioFilePath: fileReference.relativePath,
      captureTimezone: captureTimezone,
      capturedByAgenteeName: capturedByAgenteeName,
      actorName: actorName,
    );

    final meeting = MeetingEntity(
      id: _meetingIdFactory(),
      title: _trimOrNull(title),
      meetingDateTime: startedAt,
      meetingTimezone: _trimOrNull(captureTimezone),
      locationText: null,
      summary: null,
      minutesMarkdown: null,
      transcriptText: null,
      sourceCaptureId: rawCapture.id,
      sourceHash: rawCapture.sourceHash,
      reviewState: MeetingReviewState.draftRecording,
      needsReview: true,
      projectIds: projectIds,
      createdAt: startedAt,
      updatedAt: startedAt,
    );

    await meetingRepository.save(meeting);
    await auditLogService.logCreate(
      recordType: 'meeting',
      recordId: meeting.id,
      sourceCaptureId: rawCapture.id,
      after: _meetingSnapshot(meeting),
      actorName: actorName,
    );

    return MeetingRecordingSession(
      meeting: meeting,
      rawCapture: rawCapture,
      audioRelativePath: fileReference.relativePath,
      isPaused: false,
      startedAt: startedAt,
    );
  }

  Future<MeetingRecordingSession> pauseRecording(
    MeetingRecordingSession session, {
    String? actorName,
  }) async {
    if (session.isPaused || session.stoppedAt != null) {
      return session;
    }

    final updatedMeeting = _copyMeeting(
      session.meeting,
      updatedAt: _clock().toUtc(),
    );
    await meetingRepository.save(updatedMeeting);
    await auditLogService.logUpdate(
      recordType: 'meeting',
      recordId: updatedMeeting.id,
      before: _meetingSnapshot(session.meeting),
      after: <String, Object?>{
        ..._meetingSnapshot(updatedMeeting),
        'recording_state': 'paused',
      },
      sourceCaptureId: updatedMeeting.sourceCaptureId,
      actorName: actorName,
    );

    return MeetingRecordingSession(
      meeting: updatedMeeting,
      rawCapture: session.rawCapture,
      audioRelativePath: session.audioRelativePath,
      isPaused: true,
      startedAt: session.startedAt,
    );
  }

  Future<MeetingRecordingSession> resumeRecording(
    MeetingRecordingSession session, {
    String? actorName,
  }) async {
    if (!session.isPaused || session.stoppedAt != null) {
      return session;
    }

    final updatedMeeting = _copyMeeting(
      session.meeting,
      updatedAt: _clock().toUtc(),
    );
    await meetingRepository.save(updatedMeeting);
    await auditLogService.logUpdate(
      recordType: 'meeting',
      recordId: updatedMeeting.id,
      before: <String, Object?>{
        ..._meetingSnapshot(session.meeting),
        'recording_state': 'paused',
      },
      after: <String, Object?>{
        ..._meetingSnapshot(updatedMeeting),
        'recording_state': 'recording',
      },
      sourceCaptureId: updatedMeeting.sourceCaptureId,
      actorName: actorName,
    );

    return MeetingRecordingSession(
      meeting: updatedMeeting,
      rawCapture: session.rawCapture,
      audioRelativePath: session.audioRelativePath,
      isPaused: false,
      startedAt: session.startedAt,
    );
  }

  Future<MeetingRecordingSession> stopRecording(
    MeetingRecordingSession session, {
    String? actorName,
  }) async {
    if (session.stoppedAt != null) {
      return session;
    }

    final stoppedAt = _clock().toUtc();
    _transitionPolicy.requireTransition(
      from: session.meeting.reviewState,
      to: MeetingReviewState.recordedPendingTranscription,
    );
    final updatedMeeting = _copyMeeting(
      session.meeting,
      reviewState: MeetingReviewState.recordedPendingTranscription,
      updatedAt: stoppedAt,
    );

    final file = fileStorageService.resolveRelativePath(session.audioRelativePath);
    final updatedRawCapture = await _withResolvedChecksum(session.rawCapture, file);

    await rawCaptureRepository.save(updatedRawCapture);
    await meetingRepository.save(updatedMeeting);
    await auditLogService.logFinalize(
      recordType: 'meeting',
      recordId: updatedMeeting.id,
      before: _meetingSnapshot(session.meeting),
      after: _meetingSnapshot(updatedMeeting),
      sourceCaptureId: updatedMeeting.sourceCaptureId,
      actorName: actorName,
    );

    return MeetingRecordingSession(
      meeting: updatedMeeting,
      rawCapture: updatedRawCapture,
      audioRelativePath: session.audioRelativePath,
      isPaused: false,
      startedAt: session.startedAt,
      stoppedAt: stoppedAt,
    );
  }

  Future<MeetingRecordingSession?> restoreSession(
    String meetingId,
  ) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null || meeting.sourceCaptureId == null) {
      return null;
    }
    final rawCapture = await rawCaptureRepository.findById(meeting.sourceCaptureId!);
    if (rawCapture == null || rawCapture.audioFilePath == null) {
      return null;
    }

    final isStopped = meeting.reviewState == MeetingReviewState.recordedPendingTranscription;
    return MeetingRecordingSession(
      meeting: meeting,
      rawCapture: rawCapture,
      audioRelativePath: rawCapture.audioFilePath!,
      isPaused: false,
      startedAt: meeting.createdAt,
      stoppedAt: isStopped ? meeting.updatedAt : null,
    );
  }

  Future<RawCaptureEntity> _withResolvedChecksum(
    RawCaptureEntity capture,
    File file,
  ) async {
    if (!await file.exists()) {
      return capture;
    }

    final checksum = await fileStorageService.checksumForFile(file);
    return RawCaptureEntity(
      id: capture.id,
      channel: capture.channel,
      rawText: capture.rawText,
      transcriptText: capture.transcriptText,
      transcriptionProvider: capture.transcriptionProvider,
      transcriptionModel: capture.transcriptionModel,
      transcriptionError: capture.transcriptionError,
      audioFilePath: capture.audioFilePath,
      attachmentGroupId: capture.attachmentGroupId,
      captureTime: capture.captureTime,
      captureTimezone: capture.captureTimezone,
      capturedByAgenteeName: capture.capturedByAgenteeName,
      classificationType: capture.classificationType,
      classificationConfidence: capture.classificationConfidence,
      parseStatus: capture.parseStatus,
      parseVersion: capture.parseVersion,
      sourceHash: checksum,
      createdAt: capture.createdAt,
    );
  }

  MeetingEntity _copyMeeting(
    MeetingEntity source, {
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
      transcriptText: source.transcriptText,
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
      'title': meeting.title,
      'meeting_datetime': meeting.meetingDateTime,
      'meeting_timezone': meeting.meetingTimezone,
      'source_capture_id': meeting.sourceCaptureId,
      'source_hash': meeting.sourceHash,
      'review_state': meeting.reviewState.storageValue,
      'needs_review': meeting.needsReview,
      'project_ids': meeting.projectIds,
      'created_at': meeting.createdAt,
      'updated_at': meeting.updatedAt,
      'archived_at': meeting.archivedAt,
    };
  }

  String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _defaultMeetingIdFactory() {
    return 'meeting_${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  static DateTime _defaultClock() => DateTime.now();
}