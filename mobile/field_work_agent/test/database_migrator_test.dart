import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:field_work_agent/data/database/database_executor.dart';
import 'package:field_work_agent/data/database/database_migrator.dart';

void main() {
  test('applies multi-statement migrations and repairs stale schema_versions',
      () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'database_migrator_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final migrationFile = File('${tempDirectory.path}/0001_initial.sql');
    await migrationFile.writeAsString('''
CREATE TABLE IF NOT EXISTS projects (
  id TEXT PRIMARY KEY NOT NULL
);

CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY NOT NULL
);

CREATE TABLE IF NOT EXISTS meetings (
  id TEXT PRIMARY KEY NOT NULL
);

CREATE TABLE IF NOT EXISTS raw_captures (
  id TEXT PRIMARY KEY NOT NULL
);

CREATE TRIGGER IF NOT EXISTS projects_ai AFTER INSERT ON projects BEGIN
  INSERT INTO tasks(id) VALUES (new.id);
END;
''');

    final executor = _FakeDatabaseExecutor(
      appliedVersions: <int>{1},
      existingTables: <String>{'schema_versions'},
    );

    final migrator = DatabaseMigrator(
      executor: executor,
      migrationsDirectoryPath: tempDirectory.path,
    );

    await migrator.migrate();

    expect(executor.deletedSchemaVersions, isTrue);
    expect(executor.insertedVersions, <int>[1]);
    expect(
      executor.executedSql,
      contains('CREATE TABLE IF NOT EXISTS projects (\n  id TEXT PRIMARY KEY NOT NULL\n);'),
    );
    expect(
      executor.executedSql,
      contains('CREATE TABLE IF NOT EXISTS tasks (\n  id TEXT PRIMARY KEY NOT NULL\n);'),
    );
    expect(
      executor.executedSql,
      contains(
        'CREATE TRIGGER IF NOT EXISTS projects_ai AFTER INSERT ON projects BEGIN\n  INSERT INTO tasks(id) VALUES (new.id);\nEND;',
      ),
    );
  });
}

class _FakeDatabaseExecutor implements DatabaseExecutor {
  _FakeDatabaseExecutor({
    required Set<int> appliedVersions,
    required Set<String> existingTables,
  })  : _appliedVersions = appliedVersions,
        _existingTables = existingTables;

  final Set<int> _appliedVersions;
  final Set<String> _existingTables;
  final List<String> executedSql = <String>[];
  final List<int> insertedVersions = <int>[];
  bool deletedSchemaVersions = false;

  @override
  Future<void> execute(String sql,
      [List<Object?> parameters = const <Object?>[]]) async {
    executedSql.add(sql);

    if (sql == 'DELETE FROM schema_versions') {
      deletedSchemaVersions = true;
      _appliedVersions.clear();
      return;
    }

    if (sql.startsWith('INSERT INTO schema_versions')) {
      insertedVersions.add(parameters.first! as int);
      _appliedVersions.add(parameters.first! as int);
      return;
    }

    final tableMatch = RegExp(
      r'^CREATE TABLE IF NOT EXISTS\s+([a-zA-Z_][a-zA-Z0-9_]*)',
      caseSensitive: false,
    ).firstMatch(sql.trim());
    if (tableMatch != null) {
      _existingTables.add(tableMatch.group(1)!);
    }
  }

  @override
  Future<List<DatabaseRow>> query(String sql,
      [List<Object?> parameters = const <Object?>[]]) async {
    if (sql == 'SELECT version FROM schema_versions ORDER BY version ASC') {
      return _appliedVersions
          .map((version) => <String, Object?>{'version': version})
          .toList(growable: false);
    }

    if (sql.startsWith('SELECT name FROM sqlite_master')) {
      final tableName = parameters[1] as String;
      if (_existingTables.contains(tableName)) {
        return <DatabaseRow>[
          <String, Object?>{'name': tableName},
        ];
      }
      return <DatabaseRow>[];
    }

    throw UnimplementedError('Unexpected query: $sql');
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action) {
    return action(this);
  }

  @override
  Future<void> close() async {}
}