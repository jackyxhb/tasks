import 'dart:io';

import 'database_executor.dart';
import 'database_migration.dart';

class DatabaseMigrator {
  DatabaseMigrator({
    required this.executor,
    required this.migrationsDirectoryPath,
  });

  final DatabaseExecutor executor;
  final String migrationsDirectoryPath;

  Future<void> migrate() async {
    await _ensureSchemaVersionsTable();

    final appliedVersions = await _loadAppliedVersions();
    final pendingMigrations = await _loadMigrations();

    for (final migration in pendingMigrations) {
      if (appliedVersions.contains(migration.version)) {
        continue;
      }

      await executor.transaction((txn) async {
        await txn.execute(migration.sql);
        await txn.execute(
          'INSERT INTO schema_versions(version, applied_at) VALUES (?, ?)',
          <Object?>[migration.version, DateTime.now().toUtc().toIso8601String()],
        );
      });
    }
  }

  Future<void> _ensureSchemaVersionsTable() {
    return executor.execute(
      'CREATE TABLE IF NOT EXISTS schema_versions ('
      'version INTEGER PRIMARY KEY NOT NULL, '
      'applied_at TEXT NOT NULL'
      ')',
    );
  }

  Future<Set<int>> _loadAppliedVersions() async {
    final rows = await executor.query(
      'SELECT version FROM schema_versions ORDER BY version ASC',
    );
    return rows.map((row) => row['version'] as int).toSet();
  }

  Future<List<DatabaseMigration>> _loadMigrations() async {
    final directory = Directory(migrationsDirectoryPath);
    if (!directory.existsSync()) {
      throw StateError(
        'Migration directory does not exist: $migrationsDirectoryPath',
      );
    }

    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.sql'))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));

    if (files.isEmpty) {
      throw StateError(
        'At least one SQL migration is required in $migrationsDirectoryPath',
      );
    }

    return <DatabaseMigration>[
      for (final file in files)
        DatabaseMigration(
          version: _versionFromFileName(file.uri.pathSegments.last),
          name: file.uri.pathSegments.last,
          sql: await file.readAsString(),
        ),
    ];
  }

  int _versionFromFileName(String fileName) {
    final match = RegExp(r'^(\d+)').firstMatch(fileName);
    if (match == null) {
      throw StateError(
        'Migration file names must start with a numeric version: $fileName',
      );
    }
    return int.parse(match.group(1)!);
  }
}