import '../../../core/audit/audit_log_service.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../data/database/repositories/person_repository.dart';
import '../../../data/database/repositories/project_people_repository.dart';
import '../../../domain/entities/person_entity.dart';
import '../../../domain/enums/project_relation_type.dart';
import 'person_models.dart';

typedef PersonIdFactory = String Function();
typedef PersonClock = DateTime Function();

class PersonNormalizationService {
  PersonNormalizationService({
    required this.personRepository,
    required this.projectPeopleRepository,
    required this.auditLogService,
    PersonIdFactory? idFactory,
    PersonClock? clock,
  })  : _idFactory = idFactory ?? _defaultIdFactory,
        _clock = clock ?? _defaultClock;

  final PersonRepository personRepository;
  final ProjectPeopleRepository projectPeopleRepository;
  final AuditLogService auditLogService;
  final PersonIdFactory _idFactory;
  final PersonClock _clock;

  Future<PersonEntity> create(PersonDraft draft, {String? actorName}) async {
    final now = _clock().toUtc();
    final person = PersonEntity(
      id: _idFactory(),
      name: draft.name.trim(),
      nameNormalized: TextNormalizer.normalize(draft.name),
      phone: PhoneNormalizer.normalizeNullable(draft.phone),
      roleHint: _trimOrNull(draft.roleHint),
      company: _trimOrNull(draft.company),
      notes: _trimOrNull(draft.notes),
      createdAt: now,
      updatedAt: now,
    );

    await personRepository.save(person);
    await auditLogService.logCreate(
      recordType: 'person',
      recordId: person.id,
      after: _snapshot(person),
      actorName: actorName,
    );
    return person;
  }

  Future<PersonEntity> update(
    String personId,
    PersonDraft draft, {
    String? actorName,
  }) async {
    final existing = await requireDetail(personId);
    final updated = PersonEntity(
      id: existing.id,
      name: draft.name.trim(),
      nameNormalized: TextNormalizer.normalize(draft.name),
      phone: PhoneNormalizer.normalizeNullable(draft.phone),
      roleHint: _trimOrNull(draft.roleHint),
      company: _trimOrNull(draft.company),
      notes: _trimOrNull(draft.notes),
      createdAt: existing.createdAt,
      updatedAt: _clock().toUtc(),
    );

    await personRepository.save(updated);
    await auditLogService.logUpdate(
      recordType: 'person',
      recordId: updated.id,
      before: _snapshot(existing),
      after: _snapshot(updated),
      actorName: actorName,
    );
    return updated;
  }

  Future<PersonEntity?> detail(String personId) {
    return personRepository.findById(personId);
  }

  Future<PersonEntity> requireDetail(String personId) async {
    final person = await detail(personId);
    if (person == null) {
      throw StateError('Person not found: $personId');
    }
    return person;
  }

  Future<List<PersonEntity>> suggest(String? query, {int limit = 10}) {
    return personRepository.suggest(query: query, limit: limit);
  }

  Future<void> linkToProject({
    required String projectId,
    required String personId,
    required ProjectRelationType relationType,
    String? actorName,
  }) async {
    await requireDetail(personId);
    await projectPeopleRepository.link(
      projectId: projectId,
      personId: personId,
      relationType: relationType,
    );
    await auditLogService.logUpdate(
      recordType: 'project',
      recordId: projectId,
      after: <String, Object?>{
        'person_id': personId,
        'relation_type': relationType.storageValue,
      },
      actorName: actorName,
    );
  }

  Future<List<ProjectPersonLink>> listProjectPeople(String projectId) async {
    final links = await projectPeopleRepository.listForProject(projectId);
    final people = <ProjectPersonLink>[];
    for (final link in links) {
      final person = await personRepository.findById(link.personId);
      if (person != null) {
        people.add(ProjectPersonLink(person: person, relationType: link.relationType));
      }
    }
    return people;
  }

  Map<String, Object?> _snapshot(PersonEntity person) {
    return <String, Object?>{
      'id': person.id,
      'name': person.name,
      'name_normalized': person.nameNormalized,
      'phone': person.phone,
      'role_hint': person.roleHint,
      'company': person.company,
      'notes': person.notes,
      'created_at': person.createdAt,
      'updated_at': person.updatedAt,
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
    return 'person_${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  static DateTime _defaultClock() => DateTime.now();
}