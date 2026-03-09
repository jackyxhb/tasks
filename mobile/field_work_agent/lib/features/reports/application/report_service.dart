import 'dart:convert';
import 'dart:io';

import '../../../core/audit/audit_log_service.dart';
import '../../../core/storage/local_file_storage_service.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../data/database/repositories/project_repository.dart';
import '../../../data/database/repositories/report_run_repository.dart';
import '../../../data/database/repositories/task_repository.dart';
import '../../../domain/entities/report_run_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/enums/meeting_review_state.dart';
import '../../../domain/enums/task_priority.dart';
import '../../../domain/enums/task_status.dart';
import '../../../domain/enums/task_type.dart';
import 'report_models.dart';

typedef ReportRunIdFactory = String Function();

class ReportService {
  ReportService({
    required this.projectRepository,
    required this.taskRepository,
    required this.meetingRepository,
    required this.reportRunRepository,
    required this.fileStorageService,
    required this.auditLogService,
    ReportRunIdFactory? reportRunIdFactory,
  }) : _reportRunIdFactory = reportRunIdFactory ?? _defaultReportRunIdFactory;

  final ProjectRepository projectRepository;
  final TaskRepository taskRepository;
  final MeetingRepository meetingRepository;
  final ReportRunRepository reportRunRepository;
  final LocalFileStorageService fileStorageService;
  final AuditLogService auditLogService;
  final ReportRunIdFactory _reportRunIdFactory;

  Future<GeneratedReport> generateDailyTaskList({
    required DateTime date,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    final tasks = (await taskRepository.listAll()).where((task) {
      if (task.scheduledDate == null) {
        return false;
      }
      return _dateKey(task.scheduledDate!) == _dateKey(date);
    }).toList(growable: false);

    final payload = <String, Object?>{
      'date': _dateKey(date),
      'task_count': tasks.length,
      'tasks': tasks.map(_taskRow).toList(growable: false),
    };
    final summary = 'Daily task list for ${_dateKey(date)} with ${tasks.length} tasks.';
    return _finalizeReport(
      reportType: 'daily_task_list',
      filterPayload: <String, Object?>{'date': _dateKey(date)},
      payload: payload,
      summary: summary,
      outputFormat: outputFormat,
      actorName: actorName,
    );
  }

  Future<GeneratedReport> generateProjectSummary({
    required String projectId,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    final project = await projectRepository.findById(projectId);
    if (project == null) {
      throw StateError('Project not found: $projectId');
    }

    final tasks = (await taskRepository.listAll())
        .where((task) => task.projectId == projectId)
        .toList(growable: false);
    final meetings = (await meetingRepository.listAll())
        .where((meeting) => meeting.projectIds.contains(projectId))
        .toList(growable: false);

    final payload = <String, Object?>{
      'project': <String, Object?>{
        'id': project.id,
        'project_name': project.projectName,
        'client_oem': project.clientOem,
        'site_location': project.siteLocation,
        'status': project.status,
      },
      'task_count': tasks.length,
      'meeting_count': meetings.length,
      'completed_task_count': tasks.where((task) => task.status == TaskStatus.completed).length,
      'tasks': tasks.map(_taskRow).toList(growable: false),
      'meetings': meetings
          .map(
            (meeting) => <String, Object?>{
              'id': meeting.id,
              'title': meeting.title,
              'meeting_datetime': meeting.meetingDateTime?.toUtc().toIso8601String(),
              'summary': meeting.summary,
              'review_state': meeting.reviewState.storageValue,
            },
          )
          .toList(growable: false),
    };
    final summary = 'Project summary for ${project.projectName}: ${tasks.length} tasks and ${meetings.length} meetings.';
    return _finalizeReport(
      reportType: 'project_summary',
      filterPayload: <String, Object?>{'project_id': projectId},
      payload: payload,
      summary: summary,
      outputFormat: outputFormat,
      actorName: actorName,
    );
  }

  Future<GeneratedReport> generateMeetingMinutesPack({
    required ReportFilter filter,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    final meetings = (await meetingRepository.listAll()).where((meeting) {
      if (!filter.includeArchived && meeting.archivedAt != null) {
        return false;
      }
      if (filter.projectId != null && !meeting.projectIds.contains(filter.projectId)) {
        return false;
      }
      if (filter.fromDate != null) {
        final meetingDate = meeting.meetingDateTime;
        if (meetingDate == null || meetingDate.isBefore(filter.fromDate!)) {
          return false;
        }
      }
      if (filter.toDate != null) {
        final meetingDate = meeting.meetingDateTime;
        if (meetingDate == null || meetingDate.isAfter(filter.toDate!)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);

    final payload = <String, Object?>{
      'meeting_count': meetings.length,
      'meetings': meetings
          .map(
            (meeting) => <String, Object?>{
              'id': meeting.id,
              'title': meeting.title,
              'meeting_datetime': meeting.meetingDateTime?.toUtc().toIso8601String(),
              'summary': meeting.summary,
              'minutes_markdown': meeting.minutesMarkdown,
              'project_ids': meeting.projectIds,
            },
          )
          .toList(growable: false),
    };
    final summary = 'Meeting minutes pack with ${meetings.length} meetings.';
    return _finalizeReport(
      reportType: 'meeting_minutes_pack',
      filterPayload: <String, Object?>{
        'project_id': filter.projectId,
        'from_date': filter.fromDate?.toUtc().toIso8601String(),
        'to_date': filter.toDate?.toUtc().toIso8601String(),
        'include_archived': filter.includeArchived,
      },
      payload: payload,
      summary: summary,
      outputFormat: outputFormat,
      actorName: actorName,
    );
  }

  Future<GeneratedReport> _finalizeReport({
    required String reportType,
    required Map<String, Object?> filterPayload,
    required Map<String, Object?> payload,
    required String summary,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    if (outputFormat == ReportOutputFormat.pdf) {
      throw UnsupportedError('PDF output is not implemented in this slice.');
    }

    String? outputPath;
    if (outputFormat != ReportOutputFormat.inApp) {
      final reference = await fileStorageService.prepareFile(
        directory: LocalStorageDirectory.reports,
        fileName: '${reportType}_${DateTime.now().toUtc().microsecondsSinceEpoch}.${outputFormat.fileExtension}',
      );
      final outputFile = File(reference.absolutePath);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsString(
        outputFormat == ReportOutputFormat.json ? _toJson(payload) : _toCsv(reportType, payload),
      );
      outputPath = reference.relativePath;
    }

    final reportRun = ReportRunEntity(
      id: _reportRunIdFactory(),
      reportType: reportType,
      filterJson: jsonEncode(filterPayload),
      outputFormat: outputFormat.storageValue,
      outputPath: outputPath,
      createdAt: DateTime.now().toUtc(),
    );
    await reportRunRepository.save(reportRun);
    await auditLogService.logExportCreate(
      recordType: 'report_run',
      recordId: reportRun.id,
      after: <String, Object?>{
        'report_type': reportRun.reportType,
        'output_format': reportRun.outputFormat,
        'output_path': reportRun.outputPath,
      },
      actorName: actorName,
    );

    return GeneratedReport(
      reportType: reportType,
      summary: summary,
      payload: payload,
      outputPath: outputPath,
    );
  }

  Map<String, Object?> _taskRow(TaskEntity task) {
    return <String, Object?>{
      'id': task.id,
      'task_title': task.taskTitle,
      'task_type': task.taskType.storageValue,
      'scheduled_date': task.scheduledDate?.toUtc().toIso8601String(),
      'worker_name': task.workerName,
      'status': task.status.storageValue,
      'priority': task.priority.storageValue,
      'project_id': task.projectId,
      'is_provisional': task.isProvisional,
      'needs_review': task.needsReview,
    };
  }

  String _toJson(Map<String, Object?> payload) {
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _toCsv(String reportType, Map<String, Object?> payload) {
    switch (reportType) {
      case 'daily_task_list':
      case 'project_summary':
        final tasks = (payload['tasks'] as List<Object?>? ?? const <Object?>[])
            .whereType<Map<String, Object?>>()
            .toList(growable: false);
        final buffer = StringBuffer('id,task_title,task_type,scheduled_date,worker_name,status,priority,project_id,is_provisional,needs_review\n');
        for (final task in tasks) {
          buffer.writeln(_csvRow(<Object?>[
            task['id'],
            task['task_title'],
            task['task_type'],
            task['scheduled_date'],
            task['worker_name'],
            task['status'],
            task['priority'],
            task['project_id'],
            task['is_provisional'],
            task['needs_review'],
          ]));
        }
        return buffer.toString();
      case 'meeting_minutes_pack':
        final meetings = (payload['meetings'] as List<Object?>? ?? const <Object?>[])
            .whereType<Map<String, Object?>>()
            .toList(growable: false);
        final buffer = StringBuffer('id,title,meeting_datetime,summary,minutes_markdown,project_ids\n');
        for (final meeting in meetings) {
          buffer.writeln(_csvRow(<Object?>[
            meeting['id'],
            meeting['title'],
            meeting['meeting_datetime'],
            meeting['summary'],
            meeting['minutes_markdown'],
            (meeting['project_ids'] as List<Object?>?)?.join('|'),
          ]));
        }
        return buffer.toString();
      default:
        return _csvRow(<Object?>['summary']) + '\n' + _csvRow(<Object?>[payload.toString()]);
    }
  }

  String _csvRow(List<Object?> values) {
    return values
        .map((value) => '"${(value ?? '').toString().replaceAll('"', '""')}"')
        .join(',');
  }

  String _dateKey(DateTime value) {
    final utc = value.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _defaultReportRunIdFactory() {
    return 'report_run_${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }
}