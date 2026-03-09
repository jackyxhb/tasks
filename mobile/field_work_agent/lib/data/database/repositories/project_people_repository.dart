import '../../../domain/enums/project_relation_type.dart';
import '../database_executor.dart';

class ProjectPeopleRepository {
  const ProjectPeopleRepository(this.executor);

  final DatabaseExecutor executor;

  Future<void> link({
    required String projectId,
    required String personId,
    required ProjectRelationType relationType,
  }) {
    return executor.execute(
      'INSERT OR REPLACE INTO project_people (project_id, person_id, relation_type) VALUES (?, ?, ?)',
      <Object?>[projectId, personId, relationType.storageValue],
    );
  }

  Future<List<({String personId, ProjectRelationType relationType})>> listForProject(
    String projectId,
  ) async {
    final rows = await executor.query(
      'SELECT person_id, relation_type FROM project_people WHERE project_id = ? ORDER BY relation_type ASC, person_id ASC',
      <Object?>[projectId],
    );
    return rows
        .map(
          (row) => (
            personId: row['person_id'] as String,
            relationType: projectRelationTypeFromStorage(row['relation_type'] as String),
          ),
        )
        .toList(growable: false);
  }
}