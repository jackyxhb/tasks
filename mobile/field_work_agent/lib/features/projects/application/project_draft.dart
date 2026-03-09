class ProjectDraft {
  const ProjectDraft({
    required this.projectName,
    this.clientOem,
    this.siteLocation,
    this.siteContactName,
    this.siteContactPhone,
    this.coordinatorName,
    this.projectManagerName,
    this.status,
    this.notes,
  });

  final String projectName;
  final String? clientOem;
  final String? siteLocation;
  final String? siteContactName;
  final String? siteContactPhone;
  final String? coordinatorName;
  final String? projectManagerName;
  final String? status;
  final String? notes;
}