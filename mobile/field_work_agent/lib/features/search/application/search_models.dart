import '../../../domain/enums/task_status.dart';
import '../../../domain/enums/task_type.dart';

class SearchFilters {
  const SearchFilters({
    this.projectName,
    this.clientOem,
    this.workerName,
    this.coordinatorName,
    this.projectManagerName,
    this.taskType,
    this.status,
    this.fromDate,
    this.toDate,
    this.includeArchived = true,
  });

  final String? projectName;
  final String? clientOem;
  final String? workerName;
  final String? coordinatorName;
  final String? projectManagerName;
  final TaskType? taskType;
  final TaskStatus? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool includeArchived;
}

class SearchRequest {
  const SearchRequest({
    this.query,
    this.filters = const SearchFilters(),
    this.limitPerGroup = 25,
  });

  final String? query;
  final SearchFilters filters;
  final int limitPerGroup;
}

class SearchHit {
  const SearchHit({
    required this.recordType,
    required this.recordId,
    required this.title,
    required this.snippet,
    this.subtitle,
    this.archived = false,
  });

  final String recordType;
  final String recordId;
  final String title;
  final String snippet;
  final String? subtitle;
  final bool archived;
}

class GroupedSearchResults {
  const GroupedSearchResults({
    required this.projects,
    required this.tasks,
    required this.meetings,
    required this.rawCaptures,
    required this.people,
  });

  final List<SearchHit> projects;
  final List<SearchHit> tasks;
  final List<SearchHit> meetings;
  final List<SearchHit> rawCaptures;
  final List<SearchHit> people;
}