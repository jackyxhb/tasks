import '../../../domain/entities/audit_log_entity.dart';
import '../database_executor.dart';
import '../database_value_codec.dart';

class AuditLogRepository {
  const AuditLogRepository(this.executor);

  final DatabaseExecutor executor;

  Future<void> save(AuditLogEntity auditLog) {
    return executor.execute(
      'INSERT OR REPLACE INTO audit_logs ('
      'id, record_type, record_id, action_type, before_json, after_json, '
      'source_capture_id, actor_name, created_at'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        auditLog.id,
        auditLog.recordType,
        auditLog.recordId,
        auditLog.actionType,
        auditLog.beforeJson,
        auditLog.afterJson,
        auditLog.sourceCaptureId,
        auditLog.actorName,
        auditLog.createdAt.toUtc().toIso8601String(),
      ],
    );
  }

  Future<AuditLogEntity?> findById(String id) async {
    final rows = await executor.query(
      'SELECT * FROM audit_logs WHERE id = ? LIMIT 1',
      <Object?>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  Future<List<AuditLogEntity>> listForRecord({
    required String recordType,
    required String recordId,
  }) async {
    final rows = await executor.query(
      'SELECT * FROM audit_logs WHERE record_type = ? AND record_id = ? '
      'ORDER BY created_at DESC',
      <Object?>[recordType, recordId],
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  AuditLogEntity _fromRow(DatabaseRow row) {
    return AuditLogEntity(
      id: DatabaseValueCodec.string(row['id']),
      recordType: DatabaseValueCodec.string(row['record_type']),
      recordId: DatabaseValueCodec.string(row['record_id']),
      actionType: DatabaseValueCodec.string(row['action_type']),
      beforeJson: DatabaseValueCodec.stringOrNull(row['before_json']),
      afterJson: DatabaseValueCodec.stringOrNull(row['after_json']),
      sourceCaptureId: DatabaseValueCodec.stringOrNull(row['source_capture_id']),
      actorName: DatabaseValueCodec.stringOrNull(row['actor_name']),
      createdAt: DatabaseValueCodec.dateTime(row['created_at']),
    );
  }
}