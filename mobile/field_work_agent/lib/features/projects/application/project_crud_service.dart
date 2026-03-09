import '../../../core/audit/audit_log_service.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../data/database/repositories/project_repository.dart';
import '../../../domain/entities/project_entity.dart';
import 'project_draft.dart';

typedef ProjectIdFactory = String Function();
typedef ProjectClock = DateTime Function();

class ProjectCrudService {
  ProjectCrudService({
    required this.repository,
    required this.auditLogService,
    ProjectIdFactory? idFactory,
    ProjectClock? clock,
  })  : _idFactory = idFactory ?? _defaultIdFactory,
        _clock = clock ?? _defaultClock;

  final ProjectRepository repository;
  final AuditLogService auditLogService;
  final ProjectIdFactory _idFactory;
  final ProjectClock _clock;

  Future<ProjectEntity> create(ProjectDraft draft, {String? actorName}) async {
    final now = _clock().toUtc();
    final project = ProjectEntity(
      id: _idFactory(),
      projectName: draft.projectName.trim(),
      projectNameNormalized: TextNormalizer.normalize(draft.projectName),
      clientOem: _trimOrNull(draft.clientOem),
      siteLocation: _trimOrNull(draft.siteLocation),
      siteLocationNormalized: TextNormalizer.normalizeNullable(draft.siteLocation),
      siteContactName: _trimOrNull(draft.siteContactName),
      siteContactPhone: _trimOrNull(draft.siteContactPhone),
      coordinatorName: _trimOrNull(draft.coordinatorName),
      projectManagerName: _trimOrNull(draft.projectManagerName),
      status: _trimOrNull(draft.status),
      notes: _trimOrNull(draft.notes),
      createdAt: now,
      updatedAt: now,
    );

    await repository.save(project);
    await auditLogService.logCreate(
      recordType: 'project',
      recordId: project.id,
      after: _snapshot(project),
      actorName: actorName,
    );
    return project;
  }

  Future<ProjectEntity> update(
    String projectId,
    ProjectDraft draft, {
    String? actorName,
  }) async {
    final existing = await requireDetail(projectId);
    final updated = ProjectEntity(
      id: existing.id,
      projectName: draft.projectName.trim(),
      projectNameNormalized: TextNormalizer.normalize(draft.projectName),
      clientOem: _trimOrNull(draft.clientOem),
      siteLocation: _trimOrNull(draft.siteLocation),
      siteLocationNormalized: TextNormalizer.normalizeNullable(draft.siteLocation),
      siteContactName: _trimOrNull(draft.siteContactName),
      siteContactPhone: _trimOrNull(draft.siteContactPhone),
      coordinatorName: _trimOrNull(draft.coordinatorName),
      projectManagerName: _trimOrNull(draft.projectManagerName),
      status: _trimOrNull(draft.status),
      notes: _trimOrNull(draft.notes),
      createdAt: existing.createdAt,
      updatedAt: _clock().toUtc(),
      archivedAt: existing.archivedAt,
    );

    await repository.save(updated);
    await auditLogService.logUpdate(
      recordType: 'project',
      recordId: updated.id,
      before: _snapshot(existing),
      after: _snapshot(updated),
      actorName: actorName,
    );
    return updated;
  }

  Future<ProjectEntity> archive(String projectId, {String? actorName}) async {
    final existing = await requireDetail(projectId);
    final archived = ProjectEntity(
      id: existing.id,
      projectName: existing.projectName,
      projectNameNormalized: existing.projectNameNormalized,
      clientOem: existing.clientOem,
      siteLocation: existing.siteLocation,
      siteLocationNormalized: existing.siteLocationNormalized,
      siteContactName: existing.siteContactName,
      siteContactPhone: existing.siteContactPhone,
      coordinatorName: existing.coordinatorName,
      projectManagerName: existing.projectManagerName,
      status: existing.status,
      notes: existing.notes,
      createdAt: existing.createdAt,
      updatedAt: _clock().toUtc(),
      archivedAt: _clock().toUtc(),
    );

    await repository.save(archived);
    await auditLogService.logArchive(
      recordType: 'project',
      recordId: archived.id,
      before: _snapshot(existing),
      after: _snapshot(archived),
      actorName: actorName,
    );
    return archived;
  }

  Future<List<ProjectEntity>> browse({bool includeArchived = false}) async {
    final projects = await repository.listAll();
    if (includeArchived) {
      return projects;
    }
    return projects.where((project) => project.archivedAt == null).toList(growable: false);
  }

  Future<ProjectEntity?> detail(String projectId) {
    return repository.findById(projectId);
  }

  Future<ProjectEntity> requireDetail(String projectId) async {
    final project = await detail(projectId);
    if (project == null) {
      throw StateError('Project not found: $projectId');
    }
    return project;
  }

  Map<String, Object?> _snapshot(ProjectEntity project) {
    return <String, Object?>{
      'id': project.id,
      'project_name': project.projectName,
      'project_name_normalized': project.projectNameNormalized,
      'client_oem': project.clientOem,
      'site_location': project.siteLocation,
      'site_location_normalized': project.siteLocationNormalized,
      'site_contact_name': project.siteContactName,
      'site_contact_phone': project.siteContactPhone,
      'coordinator_name': project.coordinatorName,
      'project_manager_name': project.projectManagerName,
      'status': project.status,
      'notes': project.notes,
      'created_at': project.createdAt,
      'updated_at': project.updatedAt,
      'archived_at': project.archivedAt,
    };
  }

  String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _defaultIdFactory() {
    return 'project_${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  static DateTime _defaultClock() => DateTime.now();
}