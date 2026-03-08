class AttachmentManifestEntry {
  const AttachmentManifestEntry({
    required this.attachmentId,
    required this.ownerRecordType,
    required this.ownerRecordId,
    required this.relativePath,
    required this.checksum,
    this.mimeType,
  });

  final String attachmentId;
  final String ownerRecordType;
  final String ownerRecordId;
  final String relativePath;
  final String checksum;
  final String? mimeType;
}

class ExportScope {
  const ExportScope({
    required this.type,
    this.value,
  });

  final String type;
  final Object? value;
}

class ImportExportBundleEntity {
  const ImportExportBundleEntity({
    required this.schemaVersion,
    required this.bundleId,
    required this.exportedAt,
    required this.sourceAppName,
    required this.sourceAppVersion,
    required this.scope,
    required this.projects,
    required this.tasks,
    required this.meetings,
    required this.people,
    required this.attachmentsManifest,
  });

  final String schemaVersion;
  final String bundleId;
  final DateTime exportedAt;
  final String sourceAppName;
  final String sourceAppVersion;
  final ExportScope scope;
  final List<Map<String, Object?>> projects;
  final List<Map<String, Object?>> tasks;
  final List<Map<String, Object?>> meetings;
  final List<Map<String, Object?>> people;
  final List<AttachmentManifestEntry> attachmentsManifest;
}