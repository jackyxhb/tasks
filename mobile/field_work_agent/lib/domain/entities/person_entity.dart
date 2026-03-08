class PersonEntity {
  const PersonEntity({
    required this.id,
    required this.name,
    required this.nameNormalized,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.roleHint,
    this.company,
    this.notes,
  });

  final String id;
  final String name;
  final String nameNormalized;
  final String? phone;
  final String? roleHint;
  final String? company;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}