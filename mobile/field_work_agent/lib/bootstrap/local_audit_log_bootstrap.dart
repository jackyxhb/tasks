import '../core/audit/audit_log_service.dart';
import '../data/database/app_database.dart';

class LocalAuditLogBootstrap {
  const LocalAuditLogBootstrap._();

  static AuditLogService initialize({
    required AppDatabase database,
  }) {
    return AuditLogService(repository: database.auditLogs);
  }
}