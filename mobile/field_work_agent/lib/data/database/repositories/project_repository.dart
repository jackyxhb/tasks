import '../../../domain/entities/project_entity.dart';
import '../../../core/utils/text_normalizer.dart';
import '../database_executor.dart';
import '../database_value_codec.dart';

class ProjectRepository {
  const ProjectRepository(this.executor);

  final DatabaseExecutor executor;

  Future<void> save(ProjectEntity project) {
    return executor.execute(
      'INSERT OR REPLACE INTO projects ('
      'id, project_name, project_name_normalized, client_oem, site_location, '
      'site_location_normalized, site_contact_name, site_contact_phone, '
      'coordinator_name, project_manager_name, status, notes, created_at, '
      'updated_at, archived_at'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      <Object?>[
        project.id,
        project.projectName,
        project.projectNameNormalized,
        project.clientOem,
        project.siteLocation,
        project.siteLocationNormalized,
        project.siteContactName,
        project.siteContactPhone,
        project.coordinatorName,
        project.projectManagerName,
        project.status,
        project.notes,
        project.createdAt.toUtc().toIso8601String(),
        project.updatedAt.toUtc().toIso8601String(),
        project.archivedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  Future<ProjectEntity?> findById(String id) async {
    final rows = await executor.query(
      'SELECT * FROM projects WHERE id = ? LIMIT 1',
      <Object?>[id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  Future<List<ProjectEntity>> listAll() async {
    final rows = await executor.query(
      'SELECT * FROM projects ORDER BY updated_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<ProjectEntity?> findByNormalizedName(String projectName) async {
    final normalizedName = TextNormalizer.normalize(projectName);
    final rows = await executor.query(
      'SELECT * FROM projects WHERE project_name_normalized = ? LIMIT 1',
      <Object?>[normalizedName],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  ProjectEntity _fromRow(DatabaseRow row) {
    return ProjectEntity(
      id: DatabaseValueCodec.string(row['id']),
      projectName: DatabaseValueCodec.string(row['project_name']),
      projectNameNormalized: DatabaseValueCodec.string(
        row['project_name_normalized'],
      ),
      clientOem: DatabaseValueCodec.stringOrNull(row['client_oem']),
      siteLocation: DatabaseValueCodec.stringOrNull(row['site_location']),
      siteLocationNormalized: DatabaseValueCodec.stringOrNull(
        row['site_location_normalized'],
      ),
      siteContactName: DatabaseValueCodec.stringOrNull(
        row['site_contact_name'],
      ),
      siteContactPhone: DatabaseValueCodec.stringOrNull(
        row['site_contact_phone'],
      ),
      coordinatorName: DatabaseValueCodec.stringOrNull(
        row['coordinator_name'],
      ),
      projectManagerName: DatabaseValueCodec.stringOrNull(
        row['project_manager_name'],
      ),
      status: DatabaseValueCodec.stringOrNull(row['status']),
      notes: DatabaseValueCodec.stringOrNull(row['notes']),
      createdAt: DatabaseValueCodec.dateTime(row['created_at']),
      updatedAt: DatabaseValueCodec.dateTime(row['updated_at']),
      archivedAt: DatabaseValueCodec.dateTimeOrNull(row['archived_at']),
    );
  }
}