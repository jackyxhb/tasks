class ProjectEntity {
  const ProjectEntity({
    required this.id,
    required this.projectName,
    required this.projectNameNormalized,
    required this.createdAt,
    required this.updatedAt,
    this.clientOem,
    this.siteLocation,
    this.siteLocationNormalized,
    this.siteContactName,
    this.siteContactPhone,
    this.coordinatorName,
    this.projectManagerName,
    this.status,
    this.notes,
    this.archivedAt,
  });

  final String id;
  final String projectName;
  final String projectNameNormalized;
  final String? clientOem;
  final String? siteLocation;
  final String? siteLocationNormalized;
  final String? siteContactName;
  final String? siteContactPhone;
  final String? coordinatorName;
  final String? projectManagerName;
  final String? status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}