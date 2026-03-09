import 'dart:convert';

import '../../../domain/entities/import_export_bundle_entity.dart';

class BundleValidationIssue {
  const BundleValidationIssue({required this.path, required this.message});

  final String path;
  final String message;
}

class BundleValidationResult {
  const BundleValidationResult({required this.bundle, required this.issues});

  final ImportExportBundleEntity? bundle;
  final List<BundleValidationIssue> issues;

  bool get isValid => bundle != null && issues.isEmpty;
}

class ImportExportBundleValidator {
  const ImportExportBundleValidator();

  BundleValidationResult validateJson(String jsonPayload) {
    final issues = <BundleValidationIssue>[];
    Object? decoded;
    try {
      decoded = jsonDecode(jsonPayload);
    } on FormatException catch (error) {
      issues.add(BundleValidationIssue(path: r'$', message: 'Invalid JSON: ${error.message}'));
      return BundleValidationResult(bundle: null, issues: issues);
    }

    final root = decoded is Map ? decoded.cast<String, Object?>() : null;
    if (root == null) {
      issues.add(const BundleValidationIssue(path: r'$', message: 'Expected a JSON object.'));
      return BundleValidationResult(bundle: null, issues: issues);
    }

    final schemaVersion = _requireString(root['schema_version'], 'schema_version', issues);
    final bundleId = _requireString(root['bundle_id'], 'bundle_id', issues);
    final exportedAt = _requireString(root['exported_at'], 'exported_at', issues);
    final sourceApp = _requireObject(root['source_app'], 'source_app', issues);
    final scope = _requireObject(root['scope'], 'scope', issues);
    final records = _requireObject(root['records'], 'records', issues);
    final attachmentsManifest = _requireList(root['attachments_manifest'], 'attachments_manifest', issues);

    if (schemaVersion == null || bundleId == null || exportedAt == null || sourceApp == null || scope == null || records == null || attachmentsManifest == null) {
      return BundleValidationResult(bundle: null, issues: issues);
    }

    final sourceName = _requireString(sourceApp['name'], 'source_app.name', issues);
    final sourceVersion = _requireString(sourceApp['version'], 'source_app.version', issues);
    final scopeType = _requireString(scope['type'], 'scope.type', issues);
    final projects = _requireList(records['projects'], 'records.projects', issues);
    final tasks = _requireList(records['tasks'], 'records.tasks', issues);
    final meetings = _requireList(records['meetings'], 'records.meetings', issues);
    final people = _requireList(records['people'], 'records.people', issues);

    if (sourceName == null || sourceVersion == null || scopeType == null || projects == null || tasks == null || meetings == null || people == null) {
      return BundleValidationResult(bundle: null, issues: issues);
    }

    final attachmentEntries = attachmentsManifest
        .whereType<Map>()
        .map((entry) => entry.cast<String, Object?>())
        .map(
          (entry) => AttachmentManifestEntry(
            attachmentId: _requireString(entry['attachment_id'], 'attachments_manifest[].attachment_id', issues) ?? '',
            ownerRecordType: _requireString(entry['owner_record_type'], 'attachments_manifest[].owner_record_type', issues) ?? '',
            ownerRecordId: _requireString(entry['owner_record_id'], 'attachments_manifest[].owner_record_id', issues) ?? '',
            relativePath: _requireString(entry['relative_path'], 'attachments_manifest[].relative_path', issues) ?? '',
            checksum: _requireString(entry['checksum'], 'attachments_manifest[].checksum', issues) ?? '',
            mimeType: entry['mime_type'] as String?,
          ),
        )
        .toList(growable: false);

    return BundleValidationResult(
      bundle: ImportExportBundleEntity(
        schemaVersion: schemaVersion,
        bundleId: bundleId,
        exportedAt: DateTime.parse(exportedAt).toUtc(),
        sourceAppName: sourceName,
        sourceAppVersion: sourceVersion,
        scope: ExportScope(type: scopeType, value: scope['value']),
        projects: projects.whereType<Map>().map((entry) => entry.cast<String, Object?>()).toList(growable: false),
        tasks: tasks.whereType<Map>().map((entry) => entry.cast<String, Object?>()).toList(growable: false),
        meetings: meetings.whereType<Map>().map((entry) => entry.cast<String, Object?>()).toList(growable: false),
        people: people.whereType<Map>().map((entry) => entry.cast<String, Object?>()).toList(growable: false),
        attachmentsManifest: attachmentEntries,
      ),
      issues: issues,
    );
  }

  Map<String, Object?>? _requireObject(Object? value, String path, List<BundleValidationIssue> issues) {
    if (value is Map) {
      return value.cast<String, Object?>();
    }
    issues.add(BundleValidationIssue(path: path, message: 'Expected an object.'));
    return null;
  }

  List<Object?>? _requireList(Object? value, String path, List<BundleValidationIssue> issues) {
    if (value is List) {
      return value.cast<Object?>();
    }
    issues.add(BundleValidationIssue(path: path, message: 'Expected an array.'));
    return null;
  }

  String? _requireString(Object? value, String path, List<BundleValidationIssue> issues) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    issues.add(BundleValidationIssue(path: path, message: 'Expected a non-empty string.'));
    return null;
  }
}