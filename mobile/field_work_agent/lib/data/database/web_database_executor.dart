import '../../data/database/database_executor.dart';

class WebDatabaseExecutor implements DatabaseExecutor {
  WebDatabaseExecutor();

  final Map<String, List<Map<String, Object?>>> _tables = {};
  bool _isClosed = false;

  void _ensureTable(String tableName) {
    _tables.putIfAbsent(tableName, () => []);
  }

  @override
  Future<void> execute(String sql,
      [List<Object?> parameters = const []]) async {
    if (_isClosed) throw StateError('Database is closed');

    final normalized = sql.trim().toLowerCase();

    if (normalized.startsWith('create table')) {
      final tableMatch =
          RegExp(r'create table if not exists (\w+)').firstMatch(normalized);
      if (tableMatch != null) {
        _ensureTable(tableMatch.group(1)!);
      }
      return;
    }

    if (normalized.startsWith('insert into')) {
      final tableMatch = RegExp(r'insert into (\w+)').firstMatch(normalized);
      if (tableMatch != null) {
        _ensureTable(tableMatch.group(1)!);
        final row = _paramsToRow(parameters);
        _tables[tableMatch.group(1)!]!.add(row);
      }
      return;
    }

    if (normalized.startsWith('update')) {
      final tableMatch = RegExp(r'update (\w+)').firstMatch(normalized);
      if (tableMatch != null) {
        _ensureTable(tableMatch.group(1)!);
        final setMatch = RegExp(r'set (\w+)').firstMatch(normalized);
        final whereMatch = RegExp(r'where (\w+)').firstMatch(normalized);
        if (setMatch != null && whereMatch != null) {
          final column = setMatch.group(1)!;
          final whereColumn = whereMatch.group(1)!;
          for (final row in _tables[tableMatch.group(1)!]!) {
            if (row[whereColumn]?.toString() == parameters.first?.toString()) {
              row[column] = parameters.length > 1 ? parameters[1] : null;
            }
          }
        }
      }
      return;
    }

    if (normalized.startsWith('delete from')) {
      final tableMatch = RegExp(r'delete from (\w+)').firstMatch(normalized);
      if (tableMatch != null) {
        _ensureTable(tableMatch.group(1)!);
        final whereMatch = RegExp(r'where (\w+)').firstMatch(normalized);
        if (whereMatch != null && parameters.isNotEmpty) {
          final whereColumn = whereMatch.group(1)!;
          _tables[tableMatch.group(1)!]!.removeWhere(
            (row) =>
                row[whereColumn]?.toString() == parameters.first?.toString(),
          );
        }
      }
      return;
    }
  }

  Map<String, Object?> _paramsToRow(List<Object?> params) {
    final row = <String, Object?>{};
    for (var i = 0; i < params.length; i++) {
      row['col_$i'] = params[i];
    }
    return row;
  }

  @override
  Future<List<DatabaseRow>> query(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    if (_isClosed) throw StateError('Database is closed');

    final normalized = sql.trim().toLowerCase();

    if (normalized.startsWith('select')) {
      final fromMatch = RegExp(r'from (\w+)').firstMatch(normalized);
      if (fromMatch != null) {
        _ensureTable(fromMatch.group(1)!);
        var results = _tables[fromMatch.group(1)!]!.toList();

        final whereMatch = RegExp(r'where (\w+)').firstMatch(normalized);
        if (whereMatch != null && parameters.isNotEmpty) {
          final whereColumn = whereMatch.group(1)!;
          results = results
              .where((row) =>
                  row[whereColumn]?.toString() == parameters.first?.toString())
              .toList();
        }

        final orderMatch = RegExp(r'order by (\w+)').firstMatch(normalized);
        if (orderMatch != null) {
          final orderColumn = orderMatch.group(1)!;
          results.sort((a, b) => (a[orderColumn] ?? '')
              .toString()
              .compareTo((b[orderColumn] ?? '').toString()));
        }

        return results;
      }
    }

    return [];
  }

  @override
  Future<T> transaction<T>(
      Future<T> Function(DatabaseExecutor txn) action) async {
    return action(this);
  }

  @override
  Future<void> close() async {
    _isClosed = true;
    _tables.clear();
  }
}

class WebDatabaseOpener implements DatabaseOpener {
  @override
  Future<DatabaseExecutor> open() async {
    return WebDatabaseExecutor();
  }
}
