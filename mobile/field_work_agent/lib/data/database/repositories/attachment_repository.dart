import '../../../domain/entities/attachment_entity.dart';
import '../database_executor.dart';
import '../database_value_codec.dart';

class AttachmentRepository {
  const AttachmentRepository(this.executor);

  final DatabaseExecutor executor;

  Future<List<AttachmentEntity>> listAll() async {
    final rows = await executor.query(
      'SELECT * FROM attachments ORDER BY created_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<List<AttachmentEntity>> listForOwners(Set<String> ownerRecordIds) async {
    if (ownerRecordIds.isEmpty) {
      return const <AttachmentEntity>[];
    }
    final placeholders = List<String>.filled(ownerRecordIds.length, '?').join(', ');
    final rows = await executor.query(
      'SELECT * FROM attachments WHERE owner_record_id IN ($placeholders) ORDER BY created_at DESC',
      ownerRecordIds.toList(growable: false),
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  AttachmentEntity _fromRow(DatabaseRow row) {
    return AttachmentEntity(
      id: DatabaseValueCodec.string(row['id']),
      ownerRecordType: DatabaseValueCodec.string(row['owner_record_type']),
      ownerRecordId: DatabaseValueCodec.string(row['owner_record_id']),
      filePath: DatabaseValueCodec.string(row['file_path']),
      mimeType: DatabaseValueCodec.stringOrNull(row['mime_type']),
      fileSize: DatabaseValueCodec.intOrNull(row['file_size']),
      checksum: DatabaseValueCodec.stringOrNull(row['checksum']),
      createdAt: DatabaseValueCodec.dateTime(row['created_at']),
    );
  }
}