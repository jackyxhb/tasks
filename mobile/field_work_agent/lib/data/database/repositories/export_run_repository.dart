import '../../../domain/entities/export_run_entity.dart';
import '../database_executor.dart';

class ExportRunRepository {
  const ExportRunRepository(this.executor);

  final DatabaseExecutor executor;

  Future<void> save(ExportRunEntity exportRun) {
    return executor.execute(
      'INSERT OR REPLACE INTO exports ('
      'id, bundle_name, bundle_path, bundle_checksum, export_scope_type, export_scope_value, created_at'
      ') VALUES (?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        exportRun.id,
        exportRun.bundleName,
        exportRun.bundlePath,
        exportRun.bundleChecksum,
        exportRun.exportScopeType,
        exportRun.exportScopeValue,
        exportRun.createdAt.toUtc().toIso8601String(),
      ],
    );
  }
}