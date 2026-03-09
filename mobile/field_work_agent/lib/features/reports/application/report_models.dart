class ReportFilter {
  const ReportFilter({
    this.projectId,
    this.fromDate,
    this.toDate,
    this.includeArchived = false,
  });

  final String? projectId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool includeArchived;
}

enum ReportOutputFormat {
  inApp,
  json,
  csv,
  pdf,
}

extension ReportOutputFormatCodec on ReportOutputFormat {
  String get storageValue {
    switch (this) {
      case ReportOutputFormat.inApp:
        return 'in_app';
      case ReportOutputFormat.json:
        return 'json';
      case ReportOutputFormat.csv:
        return 'csv';
      case ReportOutputFormat.pdf:
        return 'pdf';
    }
  }

  String get fileExtension {
    switch (this) {
      case ReportOutputFormat.inApp:
        return 'txt';
      case ReportOutputFormat.json:
        return 'json';
      case ReportOutputFormat.csv:
        return 'csv';
      case ReportOutputFormat.pdf:
        return 'pdf';
    }
  }
}

class GeneratedReport {
  const GeneratedReport({
    required this.reportType,
    required this.summary,
    required this.payload,
    this.outputPath,
  });

  final String reportType;
  final String summary;
  final Map<String, Object?> payload;
  final String? outputPath;
}