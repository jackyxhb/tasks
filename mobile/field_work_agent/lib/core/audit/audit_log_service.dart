import 'dart:convert';

import '../../data/database/repositories/audit_log_repository.dart';
import '../../domain/entities/audit_log_entity.dart';
import 'audit_action_type.dart';

typedef AuditLogIdFactory = String Function();

class AuditLogService {
  AuditLogService({
    required this.repository,
    AuditLogIdFactory? idFactory,
  }) : _idFactory = idFactory ?? _defaultIdFactory;

  final AuditLogRepository repository;
  final AuditLogIdFactory _idFactory;

  Future<void> logCreate({
    required String recordType,
    required String recordId,
    Object? after,
    String? sourceCaptureId,
    String? actorName,
  }) {
    return logAction(
      actionType: AuditActionType.create,
      recordType: recordType,
      recordId: recordId,
      after: after,
      sourceCaptureId: sourceCaptureId,
      actorName: actorName,
    );
  }

  Future<void> logUpdate({
    required String recordType,
    required String recordId,
    Object? before,
    Object? after,
    String? sourceCaptureId,
    String? actorName,
  }) {
    return logAction(
      actionType: AuditActionType.update,
      recordType: recordType,
      recordId: recordId,
      before: before,
      after: after,
      sourceCaptureId: sourceCaptureId,
      actorName: actorName,
    );
  }

  Future<void> logMerge({
    required String recordType,
    required String recordId,
    Object? before,
    Object? after,
    String? sourceCaptureId,
    String? actorName,
  }) {
    return logAction(
      actionType: AuditActionType.merge,
      recordType: recordType,
      recordId: recordId,
      before: before,
      after: after,
      sourceCaptureId: sourceCaptureId,
      actorName: actorName,
    );
  }

  Future<void> logAiExtract({
    required String recordType,
    required String recordId,
    Object? before,
    Object? after,
    String? sourceCaptureId,
    String? actorName,
  }) {
    return logAction(
      actionType: AuditActionType.aiExtract,
      recordType: recordType,
      recordId: recordId,
      before: before,
      after: after,
      sourceCaptureId: sourceCaptureId,
      actorName: actorName,
    );
  }

  Future<void> logImportApply({
    required String recordType,
    required String recordId,
    Object? after,
    String? actorName,
  }) {
    return logAction(
      actionType: AuditActionType.importApply,
      recordType: recordType,
      recordId: recordId,
      after: after,
      actorName: actorName,
    );
  }

  Future<void> logExportCreate({
    required String recordType,
    required String recordId,
    Object? after,
    String? actorName,
  }) {
    return logAction(
      actionType: AuditActionType.exportCreate,
      recordType: recordType,
      recordId: recordId,
      after: after,
      actorName: actorName,
    );
  }

  Future<void> logFinalize({
    required String recordType,
    required String recordId,
    Object? before,
    Object? after,
    String? sourceCaptureId,
    String? actorName,
  }) {
    return logAction(
      actionType: AuditActionType.finalize,
      recordType: recordType,
      recordId: recordId,
      before: before,
      after: after,
      sourceCaptureId: sourceCaptureId,
      actorName: actorName,
    );
  }

  Future<void> logReopen({
    required String recordType,
    required String recordId,
    Object? before,
    Object? after,
    String? sourceCaptureId,
    String? actorName,
  }) {
    return logAction(
      actionType: AuditActionType.reopen,
      recordType: recordType,
      recordId: recordId,
      before: before,
      after: after,
      sourceCaptureId: sourceCaptureId,
      actorName: actorName,
    );
  }

  Future<void> logArchive({
    required String recordType,
    required String recordId,
    Object? before,
    Object? after,
    String? sourceCaptureId,
    String? actorName,
  }) {
    return logAction(
      actionType: AuditActionType.archive,
      recordType: recordType,
      recordId: recordId,
      before: before,
      after: after,
      sourceCaptureId: sourceCaptureId,
      actorName: actorName,
    );
  }

  Future<void> logAction({
    required AuditActionType actionType,
    required String recordType,
    required String recordId,
    Object? before,
    Object? after,
    String? sourceCaptureId,
    String? actorName,
  }) {
    final auditLog = AuditLogEntity(
      id: _idFactory(),
      recordType: recordType,
      recordId: recordId,
      actionType: actionType.storageValue,
      beforeJson: _encodeSnapshot(before),
      afterJson: _encodeSnapshot(after),
      sourceCaptureId: sourceCaptureId,
      actorName: actorName,
      createdAt: DateTime.now().toUtc(),
    );
    return repository.save(auditLog);
  }

  String? _encodeSnapshot(Object? snapshot) {
    if (snapshot == null) {
      return null;
    }
    return jsonEncode(snapshot, toEncodable: _toEncodable);
  }

  Object? _toEncodable(Object? value) {
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Duration) {
      return value.inMilliseconds;
    }
    return value.toString();
  }

  static String _defaultIdFactory() {
    final micros = DateTime.now().toUtc().microsecondsSinceEpoch;
    return 'audit_$micros';
  }
}