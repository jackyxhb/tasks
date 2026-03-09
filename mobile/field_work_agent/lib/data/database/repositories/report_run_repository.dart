import '../../../domain/entities/report_run_entity.dart';
import '../database_executor.dart';
import '../database_value_codec.dart';

class ReportRunRepository {
  const ReportRunRepository(this.executor);

  final DatabaseExecutor executor;

  Future<void> save(ReportRunEntity reportRun) {
    return executor.execute(
      'INSERT OR REPLACE INTO report_runs ('
      'id, report_type, filter_json, output_format, output_path, created_at'
      ') VALUES (?, ?, ?, ?, ?, ?)',
      <Object?>[
        reportRun.id,
        reportRun.reportType,
        reportRun.filterJson,
        reportRun.outputFormat,
        reportRun.outputPath,
        reportRun.createdAt.toUtc().toIso8601String(),
      ],
    );
  }

  Future<List<ReportRunEntity>> listAll() async {
    final rows = await executor.query(
      'SELECT * FROM report_runs ORDER BY created_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  ReportRunEntity _fromRow(DatabaseRow row) {
    return ReportRunEntity(
      id: DatabaseValueCodec.string(row['id']),
      reportType: DatabaseValueCodec.string(row['report_type']),
      filterJson: DatabaseValueCodec.stringOrNull(row['filter_json']),
      outputFormat: DatabaseValueCodec.string(row['output_format']),
      outputPath: DatabaseValueCodec.stringOrNull(row['output_path']),
      createdAt: DatabaseValueCodec.dateTime(row['created_at']),
    );
  }
}