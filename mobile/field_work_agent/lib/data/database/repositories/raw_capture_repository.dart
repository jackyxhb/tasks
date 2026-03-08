import '../../../domain/entities/raw_capture_entity.dart';
import '../../../domain/enums/raw_capture_channel.dart';
import '../../../domain/enums/raw_capture_parse_status.dart';
import '../database_executor.dart';
import '../database_value_codec.dart';

class RawCaptureRepository {
  const RawCaptureRepository(this.executor);

  final DatabaseExecutor executor;

  Future<void> save(RawCaptureEntity capture) {
    return executor.execute(
      'INSERT OR REPLACE INTO raw_captures ('
      'id, channel, raw_text, transcript_text, audio_file_path, '
      'attachment_group_id, capture_time, capture_timezone, '
      'captured_by_agentee_name, classification_type, '
      'classification_confidence, parse_status, parse_version, source_hash, '
      'created_at'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        capture.id,
        capture.channel.storageValue,
        capture.rawText,
        capture.transcriptText,
        capture.audioFilePath,
        capture.attachmentGroupId,
        capture.captureTime.toUtc().toIso8601String(),
        capture.captureTimezone,
        capture.capturedByAgenteeName,
        capture.classificationType,
        capture.classificationConfidence,
        capture.parseStatus.storageValue,
        capture.parseVersion,
        capture.sourceHash,
        capture.createdAt.toUtc().toIso8601String(),
      ],
    );
  }

  Future<RawCaptureEntity?> findById(String id) async {
    final rows = await executor.query(
      'SELECT * FROM raw_captures WHERE id = ? LIMIT 1',
      <Object?>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  Future<List<RawCaptureEntity>> listAll() async {
    final rows = await executor.query(
      'SELECT * FROM raw_captures ORDER BY capture_time DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  RawCaptureEntity _fromRow(DatabaseRow row) {
    return RawCaptureEntity(
      id: DatabaseValueCodec.string(row['id']),
      channel: rawCaptureChannelFromStorage(
        DatabaseValueCodec.string(row['channel']),
      ),
      rawText: DatabaseValueCodec.stringOrNull(row['raw_text']),
      transcriptText: DatabaseValueCodec.stringOrNull(row['transcript_text']),
      audioFilePath: DatabaseValueCodec.stringOrNull(row['audio_file_path']),
      attachmentGroupId: DatabaseValueCodec.stringOrNull(
        row['attachment_group_id'],
      ),
      captureTime: DatabaseValueCodec.dateTime(row['capture_time']),
      captureTimezone: DatabaseValueCodec.stringOrNull(row['capture_timezone']),
      capturedByAgenteeName: DatabaseValueCodec.stringOrNull(
        row['captured_by_agentee_name'],
      ),
      classificationType: DatabaseValueCodec.string(row['classification_type']),
      classificationConfidence: DatabaseValueCodec.doubleOrNull(
        row['classification_confidence'],
      ),
      parseStatus: rawCaptureParseStatusFromStorage(
        DatabaseValueCodec.string(row['parse_status']),
      ),
      parseVersion: DatabaseValueCodec.stringOrNull(row['parse_version']),
      sourceHash: DatabaseValueCodec.stringOrNull(row['source_hash']),
      createdAt: DatabaseValueCodec.dateTime(row['created_at']),
    );
  }
}