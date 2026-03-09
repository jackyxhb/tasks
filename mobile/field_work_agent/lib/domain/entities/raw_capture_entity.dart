import '../enums/raw_capture_channel.dart';
import '../enums/raw_capture_parse_status.dart';

class RawCaptureEntity {
  const RawCaptureEntity({
    required this.id,
    required this.channel,
    required this.captureTime,
    required this.classificationType,
    required this.parseStatus,
    required this.createdAt,
    this.rawText,
    this.transcriptText,
    this.transcriptionProvider,
    this.transcriptionModel,
    this.transcriptionError,
    this.audioFilePath,
    this.attachmentGroupId,
    this.captureTimezone,
    this.capturedByAgenteeName,
    this.classificationConfidence,
    this.parseVersion,
    this.sourceHash,
  });

  final String id;
  final RawCaptureChannel channel;
  final String? rawText;
  final String? transcriptText;
  final String? transcriptionProvider;
  final String? transcriptionModel;
  final String? transcriptionError;
  final String? audioFilePath;
  final String? attachmentGroupId;
  final DateTime captureTime;
  final String? captureTimezone;
  final String? capturedByAgenteeName;
  final String classificationType;
  final double? classificationConfidence;
  final RawCaptureParseStatus parseStatus;
  final String? parseVersion;
  final String? sourceHash;
  final DateTime createdAt;
}