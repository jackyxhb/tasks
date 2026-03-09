import '../../../core/audit/audit_log_service.dart';
import '../../../data/database/repositories/raw_capture_repository.dart';
import '../../../domain/entities/raw_capture_entity.dart';
import '../../../domain/enums/raw_capture_channel.dart';
import '../../../domain/enums/raw_capture_parse_status.dart';
import 'capture_classification.dart';

class CaptureClassificationService {
  const CaptureClassificationService({
    required this.repository,
    required this.auditLogService,
  });

  final RawCaptureRepository repository;
  final AuditLogService auditLogService;

  static const Set<String> supportedTypes = <String>{
    'task',
    'project',
    'meeting',
    'mixed',
    'unknown',
  };

  Future<RawCaptureEntity> applyClassification({
    required String captureId,
    required CaptureClassification classification,
    String? actorName,
  }) async {
    final existing = await repository.findById(captureId);
    if (existing == null) {
      throw StateError('Raw capture not found: $captureId');
    }

    final safeType = supportedTypes.contains(classification.type)
        ? classification.type
        : 'unknown';
    final updated = RawCaptureEntity(
      id: existing.id,
      channel: existing.channel,
      rawText: existing.rawText,
      transcriptText: existing.transcriptText,
      transcriptionProvider: existing.transcriptionProvider,
      transcriptionModel: existing.transcriptionModel,
      transcriptionError: existing.transcriptionError,
      audioFilePath: existing.audioFilePath,
      attachmentGroupId: existing.attachmentGroupId,
      captureTime: existing.captureTime,
      captureTimezone: existing.captureTimezone,
      capturedByAgenteeName: existing.capturedByAgenteeName,
      classificationType: safeType,
      classificationConfidence: classification.confidence,
      parseStatus: RawCaptureParseStatus.parsed,
      parseVersion: classification.parseVersion,
      sourceHash: existing.sourceHash,
      createdAt: existing.createdAt,
    );

    await repository.save(updated);
    await auditLogService.logUpdate(
      recordType: 'raw_capture',
      recordId: updated.id,
      before: _snapshot(existing),
      after: _snapshot(updated),
      actorName: actorName,
    );
    return updated;
  }

  Map<String, Object?> _snapshot(RawCaptureEntity capture) {
    return <String, Object?>{
      'id': capture.id,
      'channel': capture.channel.storageValue,
      'classification_type': capture.classificationType,
      'classification_confidence': capture.classificationConfidence,
      'parse_status': capture.parseStatus.storageValue,
      'parse_version': capture.parseVersion,
      'source_hash': capture.sourceHash,
    };
  }
}