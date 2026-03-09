import '../../../domain/entities/person_entity.dart';
import '../../../domain/enums/project_relation_type.dart';

class PersonDraft {
  const PersonDraft({
    required this.name,
    this.phone,
    this.roleHint,
    this.company,
    this.notes,
  });

  final String name;
  final String? phone;
  final String? roleHint;
  final String? company;
  final String? notes;
}

class ProjectPersonLink {
  const ProjectPersonLink({
    required this.person,
    required this.relationType,
  });

  final PersonEntity person;
  final ProjectRelationType relationType;
}