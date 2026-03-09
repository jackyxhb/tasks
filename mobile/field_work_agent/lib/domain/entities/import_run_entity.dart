class ImportRunEntity {
  const ImportRunEntity({
    required this.id,
    required this.bundleName,
    required this.bundlePath,
    required this.importTime,
    required this.status,
    this.bundleChecksum,
    this.previewSummaryJson,
    this.decisionSummaryJson,
  });

  final String id;
  final String bundleName;
  final String bundlePath;
  final String? bundleChecksum;
  final DateTime importTime;
  final String? previewSummaryJson;
  final String? decisionSummaryJson;
  final String status;
}