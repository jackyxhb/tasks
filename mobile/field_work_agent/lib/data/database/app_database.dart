import '../../domain/entities/audit_log_entity.dart';
import '../../domain/entities/meeting_entity.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/entities/raw_capture_entity.dart';
import '../../domain/entities/task_entity.dart';
import 'database_executor.dart';
import 'database_migrator.dart';
import 'repositories/audit_log_repository.dart';
import 'repositories/meeting_repository.dart';
import 'repositories/project_repository.dart';
import 'repositories/raw_capture_repository.dart';
import 'repositories/task_repository.dart';

class AppDatabase {
  AppDatabase._(this.executor)
      : projects = ProjectRepository(executor),
        tasks = TaskRepository(executor),
        meetings = MeetingRepository(executor),
        rawCaptures = RawCaptureRepository(executor),
        auditLogs = AuditLogRepository(executor);

  final DatabaseExecutor executor;

  final ProjectRepository projects;
  final TaskRepository tasks;
  final MeetingRepository meetings;
  final RawCaptureRepository rawCaptures;
  final AuditLogRepository auditLogs;

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
  TaskRepository tasks,
  MeetingRepository meetings,
  RawCaptureRepository rawCaptures,
  AuditLogRepository auditLogs,
});

extension AppDatabaseRepositories on AppDatabase {
  CoreRecordRepositories get repositories => (
        projects: projects,
        tasks: tasks,
        meetings: meetings,
        rawCaptures: rawCaptures,
        auditLogs: auditLogs,
      );
}