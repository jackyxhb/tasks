import 'dart:io';

import 'database_executor.dart';
import 'database_migration.dart';

class DatabaseMigrator {
  DatabaseMigrator({
    required this.executor,
    required this.migrationsDirectoryPath,
  });

  static const List<String> _requiredCoreTables = <String>[
    'projects',
    'tasks',
    'meetings',
    'raw_captures',
  ];

  final DatabaseExecutor executor;
  final String migrationsDirectoryPath;

  Future<void> migrate() async {
    await _ensureSchemaVersionsTable();

    final appliedVersions = await _loadAppliedVersions();
    final effectiveAppliedVersions = await _repairIfCoreSchemaMissing(
      appliedVersions,
    );
    final pendingMigrations = await _loadMigrations();

    for (final migration in pendingMigrations) {
      if (effectiveAppliedVersions.contains(migration.version)) {
        continue;
      }

      await executor.transaction((txn) async {
        for (final statement in _splitStatements(migration.sql)) {
          await txn.execute(statement);
        }
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

  Future<Set<int>> _repairIfCoreSchemaMissing(Set<int> appliedVersions) async {
    if (appliedVersions.isEmpty) {
      return appliedVersions;
    }

    for (final tableName in _requiredCoreTables) {
      if (!await _tableExists(tableName)) {
        await executor.execute('DELETE FROM schema_versions');
        return <int>{};
      }
    }

    return appliedVersions;
  }

  Future<bool> _tableExists(String tableName) async {
    final rows = await executor.query(
      'SELECT name FROM sqlite_master WHERE type = ? AND name = ? LIMIT 1',
      <Object?>['table', tableName],
    );
    return rows.isNotEmpty;
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

  List<String> _splitStatements(String sql) {
    final statements = <String>[];
    final buffer = StringBuffer();
    var inSingleQuote = false;
    var inDoubleQuote = false;
    var inLineComment = false;
    var inBlockComment = false;
    var inTriggerBody = false;

    for (var index = 0; index < sql.length; index += 1) {
      final current = sql[index];
      final next = index + 1 < sql.length ? sql[index + 1] : '';

      if (inLineComment) {
        if (current == '\n') {
          inLineComment = false;
          buffer.write(current);
        }
        continue;
      }

      if (inBlockComment) {
        if (current == '*' && next == '/') {
          inBlockComment = false;
          index += 1;
        }
        continue;
      }

      if (!inSingleQuote && !inDoubleQuote) {
        if (current == '-' && next == '-') {
          inLineComment = true;
          index += 1;
          continue;
        }
        if (current == '/' && next == '*') {
          inBlockComment = true;
          index += 1;
          continue;
        }
      }

      if (current == "'" && !inDoubleQuote) {
        final escaped = next == "'";
        buffer.write(current);
        if (escaped) {
          buffer.write(next);
          index += 1;
        } else {
          inSingleQuote = !inSingleQuote;
        }
        continue;
      }

      if (current == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        buffer.write(current);
        continue;
      }

      buffer.write(current);

      if (inSingleQuote || inDoubleQuote) {
        continue;
      }

      final normalized = buffer.toString().trim().toUpperCase();
      if (!inTriggerBody && normalized.startsWith('CREATE TRIGGER ')) {
        inTriggerBody = true;
      }

      if (current != ';') {
        continue;
      }

      if (inTriggerBody) {
        final trimmedUpper = buffer.toString().trimRight().toUpperCase();
        if (trimmedUpper.endsWith('END;')) {
          inTriggerBody = false;
        } else {
          continue;
        }
      }

      final statement = buffer.toString().trim();
      if (statement.isNotEmpty) {
        statements.add(statement);
      }
      buffer.clear();
    }

    final trailing = buffer.toString().trim();
    if (trailing.isNotEmpty) {
      statements.add(trailing);
    }

    return statements;
  }
}