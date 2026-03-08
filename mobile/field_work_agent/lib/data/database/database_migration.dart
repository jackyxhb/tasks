class DatabaseMigration {
  const DatabaseMigration({
    required this.version,
    required this.name,
    required this.sql,
  });

  final int version;
  final String name;
  final String sql;
}