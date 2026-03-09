class ReportRunEntity {
  const ReportRunEntity({
    required this.id,
    required this.reportType,
    required this.outputFormat,
    required this.createdAt,
    this.filterJson,
    this.outputPath,
  });

  final String id;
  final String reportType;
  final String? filterJson;
  final String outputFormat;
  final String? outputPath;
  final DateTime createdAt;
}