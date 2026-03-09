typedef DatabaseRow = Map<String, Object?>;

abstract class DatabaseExecutor {
  Future<void> execute(String sql, [List<Object?> parameters = const <Object?>[]]);

  Future<List<DatabaseRow>> query(
    String sql, [
    List<Object?> parameters = const <Object?>[],
  ]);

  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor txn) action);

  Future<void> close();
}

abstract class DatabaseOpener {
  Future<DatabaseExecutor> open();
}