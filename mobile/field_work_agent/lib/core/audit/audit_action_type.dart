enum AuditActionType {
  create,
  update,
  merge,
  dedupReject,
  importApply,
  exportCreate,
  aiExtract,
  finalize,
  reopen,
  archive,
}

extension AuditActionTypeCodec on AuditActionType {
  String get storageValue {
    switch (this) {
      case AuditActionType.create:
        return 'create';
      case AuditActionType.update:
        return 'update';
      case AuditActionType.merge:
        return 'merge';
      case AuditActionType.dedupReject:
        return 'dedup_reject';
      case AuditActionType.importApply:
        return 'import_apply';
      case AuditActionType.exportCreate:
        return 'export_create';
      case AuditActionType.aiExtract:
        return 'ai_extract';
      case AuditActionType.finalize:
        return 'finalize';
      case AuditActionType.reopen:
        return 'reopen';
      case AuditActionType.archive:
        return 'archive';
    }
  }
}