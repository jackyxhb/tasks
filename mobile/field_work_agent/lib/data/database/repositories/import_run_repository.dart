import '../../../domain/entities/import_run_entity.dart';
import '../database_executor.dart';

class ImportRunRepository {
  const ImportRunRepository(this.executor);

  final DatabaseExecutor executor;

  Future<void> save(ImportRunEntity importRun) {
    return executor.execute(
      'INSERT OR REPLACE INTO imports ('
      'id, bundle_name, bundle_path, bundle_checksum, import_time, preview_summary_json, decision_summary_json, status'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        importRun.id,
        importRun.bundleName,
        importRun.bundlePath,
        importRun.bundleChecksum,
        importRun.importTime.toUtc().toIso8601String(),
        importRun.previewSummaryJson,
        importRun.decisionSummaryJson,
        importRun.status,
      ],
    );
  }
}