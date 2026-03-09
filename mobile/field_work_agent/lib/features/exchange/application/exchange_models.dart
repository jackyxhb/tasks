import '../../../domain/entities/import_export_bundle_entity.dart';

class ExportScopeRequest {
  const ExportScopeRequest({
    required this.type,
    this.value,
  });

  final String type;
  final String? value;
}

class ImportPreviewResult {
  const ImportPreviewResult({
    required this.bundle,
    required this.projectCount,
    required this.taskCount,
    required this.meetingCount,
    required this.peopleCount,
    required this.duplicateIds,
  });

  final ImportExportBundleEntity bundle;
  final int projectCount;
  final int taskCount;
  final int meetingCount;
  final int peopleCount;
  final List<String> duplicateIds;
}