import '../../../core/audit/audit_log_service.dart';
import '../../../core/utils/content_hash.dart';
import '../../../data/database/repositories/raw_capture_repository.dart';
import '../../../domain/entities/raw_capture_entity.dart';
import '../../../domain/enums/raw_capture_channel.dart';
import '../../../domain/enums/raw_capture_parse_status.dart';

typedef RawCaptureIdFactory = String Function();
typedef RawCaptureClock = DateTime Function();

class RawCaptureIntakeService {
  RawCaptureIntakeService({
    required this.repository,
    required this.auditLogService,
    RawCaptureIdFactory? idFactory,
    RawCaptureClock? clock,
  })  : _idFactory = idFactory ?? _defaultIdFactory,
        _clock = clock ?? _defaultClock;

  final RawCaptureRepository repository;
  final AuditLogService auditLogService;
  final RawCaptureIdFactory _idFactory;
  final RawCaptureClock _clock;

  Future<RawCaptureEntity> createTextCapture({
    required RawCaptureChannel channel,
    required String rawText,
    String? captureTimezone,
    String? capturedByAgenteeName,
    String? actorName,
  }) {
    if (channel == RawCaptureChannel.audio) {
      throw StateError(
          'Audio captures must be created through createAudioCapture.');
    }
    return _create(
      channel: channel,
      rawText: rawText,
      captureTimezone: captureTimezone,
      capturedByAgenteeName: capturedByAgenteeName,
      actorName: actorName,
    );
  }

  Future<RawCaptureEntity> createManualFormCapture({
    required String rawText,
    String? captureTimezone,
    String? capturedByAgenteeName,
    String? actorName,
  }) {
    return _create(
      channel: RawCaptureChannel.manualForm,
      rawText: rawText,
      captureTimezone: captureTimezone,
      capturedByAgenteeName: capturedByAgenteeName,
      actorName: actorName,
    );
  }

  Future<RawCaptureEntity> createAudioCapture({
    required String audioFilePath,
    String? attachmentGroupId,
    String? captureTimezone,
    String? capturedByAgenteeName,
    String? actorName,
  }) {
    return _create(
      channel: RawCaptureChannel.audio,
      audioFilePath: audioFilePath,
      attachmentGroupId: attachmentGroupId,
      captureTimezone: captureTimezone,
      capturedByAgenteeName: capturedByAgenteeName,
      actorName: actorName,
    );
  }

  Future<List<RawCaptureEntity>> browse() {
    return repository.listAll();
  }

  Future<RawCaptureEntity> _create({
    required RawCaptureChannel channel,
    String? rawText,
    String? audioFilePath,
    String? attachmentGroupId,
    String? captureTimezone,
    String? capturedByAgenteeName,
    String? actorName,
  }) async {
    final captureTime = _clock().toUtc();
    final normalizedRawText = _trimOrNull(rawText);
    final normalizedAudioPath = _trimOrNull(audioFilePath);

    if (normalizedRawText == null && normalizedAudioPath == null) {
      throw StateError(
          'A raw capture requires raw text or an audio file path.');
    }

    final hashInput = normalizedRawText ?? normalizedAudioPath!;
    final capture = RawCaptureEntity(
      id: _idFactory(),
      channel: channel,
      rawText: normalizedRawText,
      transcriptText: null,
      transcriptionProvider: null,
      transcriptionModel: null,
      transcriptionError: null,
      audioFilePath: normalizedAudioPath,
      attachmentGroupId: _trimOrNull(attachmentGroupId),
      captureTime: captureTime,
      captureTimezone: _trimOrNull(captureTimezone),
      capturedByAgenteeName: _trimOrNull(capturedByAgenteeName),
      classificationType: 'unknown',
      classificationConfidence: null,
      parseStatus: RawCaptureParseStatus.newCapture,
      parseVersion: null,
      sourceHash: ContentHash.forText(hashInput),
      createdAt: captureTime,
    );

    await repository.save(capture);
    await auditLogService.logCreate(
      recordType: 'raw_capture',
      recordId: capture.id,
      after: _snapshot(capture),
      actorName: actorName,
    );
    return capture;
  }

  Map<String, Object?> _snapshot(RawCaptureEntity capture) {
    return <String, Object?>{
      'id': capture.id,
      'channel': capture.channel.storageValue,
      'raw_text': capture.rawText,
      'transcript_text': capture.transcriptText,
      'transcription_provider': capture.transcriptionProvider,
      'transcription_model': capture.transcriptionModel,
      'transcription_error': capture.transcriptionError,
      'audio_file_path': capture.audioFilePath,
      'attachment_group_id': capture.attachmentGroupId,
      'capture_time': capture.captureTime,
      'capture_timezone': capture.captureTimezone,
      'captured_by_agentee_name': capture.capturedByAgenteeName,
      'classification_type': capture.classificationType,
      'classification_confidence': capture.classificationConfidence,
      'parse_status': capture.parseStatus.storageValue,
      'parse_version': capture.parseVersion,
      'source_hash': capture.sourceHash,
      'created_at': capture.createdAt,
    };
  }

  String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _defaultIdFactory() {
    return 'capture_${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  static DateTime _defaultClock() => DateTime.now();
}
