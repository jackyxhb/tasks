import '../../../data/database/database_executor.dart';
import '../../../domain/enums/task_status.dart';
import '../../../domain/enums/task_type.dart';
import 'search_models.dart';

class SearchService {
  const SearchService({required this.executor});

  final DatabaseExecutor executor;

  Future<GroupedSearchResults> search(SearchRequest request) async {
    final trimmedQuery = request.query?.trim();

    final results = await Future.wait(<Future<List<SearchHit>>>[
      _searchProjects(trimmedQuery, request),
      _searchTasks(trimmedQuery, request),
      _searchMeetings(trimmedQuery, request),
      _searchRawCaptures(trimmedQuery, request),
      _searchPeople(trimmedQuery, request),
    ]);

    return GroupedSearchResults(
      projects: results[0],
      tasks: results[1],
      meetings: results[2],
      rawCaptures: results[3],
      people: results[4],
    );
  }

  Future<List<SearchHit>> _searchProjects(String? query, SearchRequest request) async {
    final sql = StringBuffer(
      'SELECT p.id, p.project_name, p.site_location, p.notes, p.archived_at FROM projects p WHERE 1 = 1',
    );
    final params = <Object?>[];
    if (query != null && query.isNotEmpty) {
      final normalizedQuery = '%${_normalize(query)}%';
      sql.write(
        ' AND ('
        'LOWER(p.project_name) LIKE ? OR '
        'LOWER(COALESCE(p.site_location, \'\')) LIKE ? OR '
        'LOWER(COALESCE(p.notes, \'\')) LIKE ?'
        ')',
      );
      params.addAll(<Object?>[
        normalizedQuery,
        normalizedQuery,
        normalizedQuery,
      ]);
    }
    _appendArchiveFilter(sql, params, 'p.archived_at', request.filters.includeArchived);
    _appendLike(sql, params, 'p.project_name_normalized', request.filters.projectName, normalize: true);
    _appendLike(sql, params, 'p.client_oem', request.filters.clientOem);
    _appendLike(sql, params, 'p.coordinator_name', request.filters.coordinatorName);
    _appendLike(sql, params, 'p.project_manager_name', request.filters.projectManagerName);
    sql.write(' ORDER BY p.updated_at DESC LIMIT ?');
    params.add(request.limitPerGroup);

    final rows = await executor.query(sql.toString(), params);
    return rows
        .map(
          (row) => SearchHit(
            recordType: 'project',
            recordId: row['id'] as String,
            title: (row['project_name'] as String?) ?? 'Untitled project',
            subtitle: row['site_location'] as String?,
            snippet: _snippet(
              '${row['project_name'] ?? ''}\n${row['site_location'] ?? ''}\n${row['notes'] ?? ''}',
              query,
            ),
            archived: row['archived_at'] != null,
          ),
        )
        .toList(growable: false);
  }

  Future<List<SearchHit>> _searchTasks(String? query, SearchRequest request) async {
    final sql = StringBuffer(
      'SELECT t.id, t.task_title, t.description, t.worker_name, t.location_snapshot, t.archived_at FROM tasks t WHERE 1 = 1',
    );
    final params = <Object?>[];
    if (query != null && query.isNotEmpty) {
      final normalizedQuery = '%${_normalize(query)}%';
      sql.write(
        ' AND ('
        'LOWER(COALESCE(t.task_title, \'\')) LIKE ? OR '
        'LOWER(COALESCE(t.description, \'\')) LIKE ? OR '
        'LOWER(COALESCE(t.worker_name, \'\')) LIKE ? OR '
        'LOWER(COALESCE(t.location_snapshot, \'\')) LIKE ?'
        ')',
      );
      params.addAll(<Object?>[
        normalizedQuery,
        normalizedQuery,
        normalizedQuery,
        normalizedQuery,
      ]);
    }
    _appendArchiveFilter(sql, params, 't.archived_at', request.filters.includeArchived);
    _appendLike(sql, params, 't.worker_name', request.filters.workerName);
    _appendLike(sql, params, 't.coordinator_name', request.filters.coordinatorName);
    _appendLike(sql, params, 't.project_manager_name', request.filters.projectManagerName);
    if (request.filters.taskType != null) {
      sql.write(' AND t.task_type = ?');
      params.add(request.filters.taskType!.storageValue);
    }
    if (request.filters.status != null) {
      sql.write(' AND t.status = ?');
      params.add(request.filters.status!.storageValue);
    }
    _appendDateRange(sql, params, 't.scheduled_date', request.filters.fromDate, request.filters.toDate);
    sql.write(' ORDER BY t.updated_at DESC LIMIT ?');
    params.add(request.limitPerGroup);

    final rows = await executor.query(sql.toString(), params);
    return rows
        .map(
          (row) => SearchHit(
            recordType: 'task',
            recordId: row['id'] as String,
            title: (row['task_title'] as String?) ?? 'Untitled task',
            subtitle: row['worker_name'] as String?,
            snippet: _snippet(
              '${row['task_title'] ?? ''}\n${row['description'] ?? ''}\n${row['location_snapshot'] ?? ''}',
              query,
            ),
            archived: row['archived_at'] != null,
          ),
        )
        .toList(growable: false);
  }

  Future<List<SearchHit>> _searchMeetings(String? query, SearchRequest request) async {
    final sql = StringBuffer(
      'SELECT m.id, m.title, m.summary, m.minutes_markdown, m.transcript_text, m.archived_at FROM meetings m WHERE 1 = 1',
    );
    final params = <Object?>[];
    if (query != null && query.isNotEmpty) {
      final normalizedQuery = '%${_normalize(query)}%';
      sql.write(
        ' AND ('
        'LOWER(COALESCE(m.title, \'\')) LIKE ? OR '
        'LOWER(COALESCE(m.summary, \'\')) LIKE ? OR '
        'LOWER(COALESCE(m.minutes_markdown, \'\')) LIKE ? OR '
        'LOWER(COALESCE(m.transcript_text, \'\')) LIKE ?'
        ')',
      );
      params.addAll(<Object?>[
        normalizedQuery,
        normalizedQuery,
        normalizedQuery,
        normalizedQuery,
      ]);
    }
    _appendArchiveFilter(sql, params, 'm.archived_at', request.filters.includeArchived);
    _appendDateRange(sql, params, 'm.meeting_datetime', request.filters.fromDate, request.filters.toDate);
    if (request.filters.projectName != null) {
      sql.write(' AND EXISTS ('
          'SELECT 1 FROM meeting_projects mp '
          'JOIN projects p ON p.id = mp.project_id '
          'WHERE mp.meeting_id = m.id AND p.project_name_normalized LIKE ?'
          ')');
      params.add('%${_normalize(request.filters.projectName!)}%');
    }
    sql.write(' ORDER BY m.updated_at DESC LIMIT ?');
    params.add(request.limitPerGroup);

    final rows = await executor.query(sql.toString(), params);
    return rows
        .map(
          (row) => SearchHit(
            recordType: 'meeting',
            recordId: row['id'] as String,
            title: (row['title'] as String?) ?? 'Untitled meeting',
            snippet: _snippet(
              '${row['summary'] ?? ''}\n${row['minutes_markdown'] ?? ''}\n${row['transcript_text'] ?? ''}',
              query,
            ),
            archived: row['archived_at'] != null,
          ),
        )
        .toList(growable: false);
  }

  Future<List<SearchHit>> _searchRawCaptures(String? query, SearchRequest request) async {
    if (query == null || query.isEmpty) {
      return const <SearchHit>[];
    }

    final sql = StringBuffer(
      'SELECT r.id, r.raw_text, r.transcript_text, r.channel, r.capture_time '
      'FROM raw_captures_fts f JOIN raw_captures r ON r.id = f.record_id WHERE raw_captures_fts MATCH ?',
    );
    final params = <Object?>[query];
    _appendDateRange(sql, params, 'r.capture_time', request.filters.fromDate, request.filters.toDate);
    sql.write(' ORDER BY r.capture_time DESC LIMIT ?');
    params.add(request.limitPerGroup);

    final rows = await executor.query(sql.toString(), params);
    return rows
        .map(
          (row) => SearchHit(
            recordType: 'raw_capture',
            recordId: row['id'] as String,
            title: (row['channel'] as String?) ?? 'raw_capture',
            snippet: _snippet(
              '${row['raw_text'] ?? ''}\n${row['transcript_text'] ?? ''}',
              query,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<List<SearchHit>> _searchPeople(String? query, SearchRequest request) async {
    final sql = StringBuffer(
      query != null && query.isNotEmpty
          ? 'SELECT p.id, p.name, p.phone, p.company, p.notes '
            'FROM people_fts f JOIN people p ON p.id = f.record_id WHERE people_fts MATCH ?'
          : 'SELECT p.id, p.name, p.phone, p.company, p.notes FROM people p WHERE 1 = 1',
    );
    final params = <Object?>[];
    if (query != null && query.isNotEmpty) {
      params.add(query);
    }
    _appendLike(sql, params, 'p.name_normalized', request.filters.workerName, normalize: true);
    sql.write(' ORDER BY p.updated_at DESC LIMIT ?');
    params.add(request.limitPerGroup);

    final rows = await executor.query(sql.toString(), params);
    return rows
        .map(
          (row) => SearchHit(
            recordType: 'person',
            recordId: row['id'] as String,
            title: (row['name'] as String?) ?? 'Unknown person',
            subtitle: row['phone'] as String?,
            snippet: _snippet('${row['company'] ?? ''}\n${row['notes'] ?? ''}', query),
          ),
        )
        .toList(growable: false);
  }

  void _appendArchiveFilter(StringBuffer sql, List<Object?> params, String column, bool includeArchived) {
    if (!includeArchived) {
      sql.write(' AND $column IS NULL');
    }
  }

  void _appendLike(
    StringBuffer sql,
    List<Object?> params,
    String column,
    String? value, {
    bool normalize = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return;
    }
    sql.write(' AND $column LIKE ?');
    params.add('%${normalize ? _normalize(value) : value.trim()}%');
  }

  void _appendDateRange(
    StringBuffer sql,
    List<Object?> params,
    String column,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    if (fromDate != null) {
      sql.write(' AND $column >= ?');
      params.add(fromDate.toUtc().toIso8601String());
    }
    if (toDate != null) {
      sql.write(' AND $column <= ?');
      params.add(toDate.toUtc().toIso8601String());
    }
  }

  String _snippet(String text, String? query) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return '';
    }
    if (query == null || query.trim().isEmpty) {
      return normalizedText.length <= 120 ? normalizedText : '${normalizedText.substring(0, 120)}...';
    }

    final lowerText = normalizedText.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);
    if (index < 0) {
      return normalizedText.length <= 120 ? normalizedText : '${normalizedText.substring(0, 120)}...';
    }
    final start = (index - 40).clamp(0, normalizedText.length);
    final end = (index + lowerQuery.length + 80).clamp(0, normalizedText.length);
    final prefix = start > 0 ? '...' : '';
    final suffix = end < normalizedText.length ? '...' : '';
    return '$prefix${normalizedText.substring(start, end)}$suffix';
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}