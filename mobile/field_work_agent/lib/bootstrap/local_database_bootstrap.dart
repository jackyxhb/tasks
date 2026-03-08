import '../data/database/app_database.dart';
import '../data/database/database_executor.dart';

class LocalDatabaseBootstrap {
  const LocalDatabaseBootstrap._();

  static Future<AppDatabase> initialize({
    required DatabaseOpener opener,
    required String migrationsDirectoryPath,
  }) {
    return AppDatabase.initialize(
      opener: opener,
      migrationsDirectoryPath: migrationsDirectoryPath,
    );
  }
}