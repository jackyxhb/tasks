import 'database_executor.dart';
import 'database_migrator.dart';
import 'repositories/audit_log_repository.dart';
import 'repositories/attachment_repository.dart';
import 'repositories/export_run_repository.dart';
import 'repositories/import_run_repository.dart';
import 'repositories/meeting_repository.dart';
import 'repositories/person_repository.dart';
import 'repositories/project_repository.dart';
import 'repositories/project_people_repository.dart';
import 'repositories/raw_capture_repository.dart';
import 'repositories/report_run_repository.dart';
import 'repositories/task_repository.dart';

class AppDatabase {
  AppDatabase._(this.executor)
      : projects = ProjectRepository(executor),
        attachments = AttachmentRepository(executor),
        people = PersonRepository(executor),
        importRuns = ImportRunRepository(executor),
        exportRuns = ExportRunRepository(executor),
        projectPeople = ProjectPeopleRepository(executor),
        tasks = TaskRepository(executor),
        meetings = MeetingRepository(executor),
        rawCaptures = RawCaptureRepository(executor),
        auditLogs = AuditLogRepository(executor),
        reportRuns = ReportRunRepository(executor);

  final DatabaseExecutor executor;

  final ProjectRepository projects;
  final AttachmentRepository attachments;
  final PersonRepository people;
  final ImportRunRepository importRuns;
  final ExportRunRepository exportRuns;
  final ProjectPeopleRepository projectPeople;
  final TaskRepository tasks;
  final MeetingRepository meetings;
  final RawCaptureRepository rawCaptures;
  final AuditLogRepository auditLogs;
  final ReportRunRepository reportRuns;

  Future<void> close() {
    return executor.close();
  }

  static Future<AppDatabase> initialize({
    required DatabaseOpener opener,
    required String migrationsDirectoryPath,
  }) async {
    final executor = await opener.open();
    final migrator = DatabaseMigrator(
      executor: executor,
      migrationsDirectoryPath: migrationsDirectoryPath,
    );
    await migrator.migrate();
    return AppDatabase._(executor);
  }
}

typedef CoreRecordRepositories = ({
  ProjectRepository projects,
  AttachmentRepository attachments,
  PersonRepository people,
  ImportRunRepository importRuns,
  ExportRunRepository exportRuns,
  ProjectPeopleRepository projectPeople,
  TaskRepository tasks,
  MeetingRepository meetings,
  RawCaptureRepository rawCaptures,
  AuditLogRepository auditLogs,
  ReportRunRepository reportRuns,
});

extension AppDatabaseRepositories on AppDatabase {
  CoreRecordRepositories get repositories => (
        projects: projects,
  attachments: attachments,
        people: people,
  importRuns: importRuns,
  exportRuns: exportRuns,
        projectPeople: projectPeople,
        tasks: tasks,
        meetings: meetings,
        rawCaptures: rawCaptures,
        auditLogs: auditLogs,
        reportRuns: reportRuns,
      );
}