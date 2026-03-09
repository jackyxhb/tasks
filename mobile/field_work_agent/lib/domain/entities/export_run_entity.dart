class ExportRunEntity {
  const ExportRunEntity({
    required this.id,
    required this.bundleName,
    required this.bundlePath,
    required this.exportScopeType,
    required this.createdAt,
    this.bundleChecksum,
    this.exportScopeValue,
  });

  final String id;
  final String bundleName;
  final String bundlePath;
  final String? bundleChecksum;
  final String exportScopeType;
  final String? exportScopeValue;
  final DateTime createdAt;
}