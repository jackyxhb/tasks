class AuditLogEntity {
  const AuditLogEntity({
    required this.id,
    required this.recordType,
    required this.recordId,
    required this.actionType,
    required this.createdAt,
    this.beforeJson,
    this.afterJson,
    this.sourceCaptureId,
    this.actorName,
  });

  final String id;
  final String recordType;
  final String recordId;
  final String actionType;
  final String? beforeJson;
  final String? afterJson;
  final String? sourceCaptureId;
  final String? actorName;
  final DateTime createdAt;
}