import '../../../core/utils/text_normalizer.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../data/database/repositories/project_repository.dart';
import '../../../data/database/repositories/task_repository.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/project_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../projects/application/project_draft.dart';
import '../../tasks/application/task_dedup_key_factory.dart';
import '../../tasks/application/task_models.dart';
import 'dedup_candidate.dart';

class DedupService {
  DedupService({
    required this.projectRepository,
    required this.taskRepository,
    required this.meetingRepository,
    TaskDedupKeyFactory? taskDedupKeyFactory,
  }) : _taskDedupKeyFactory = taskDedupKeyFactory ?? const TaskDedupKeyFactory();

  final ProjectRepository projectRepository;
  final TaskRepository taskRepository;
  final MeetingRepository meetingRepository;
  final TaskDedupKeyFactory _taskDedupKeyFactory;

  Future<List<DedupCandidate>> findTaskDuplicates(TaskDraft draft) async {
    final candidates = <DedupCandidate>[];
    final dedupKey = _taskDedupKeyFactory.build(draft);
    final tasks = await taskRepository.listAll();

    for (final task in tasks) {
      if (task.archivedAt != null) {
        continue;
      }
      final reasons = <String>[];
      var score = 0.0;

      if (dedupKey != null && task.dedupKey == dedupKey) {
        reasons.add('matching_task_dedup_key');
        score += 1.0;
      }

      final normalizedTitle = TextNormalizer.normalizeNullable(draft.taskTitle);
      if (normalizedTitle != null && task.taskTitleNormalized == normalizedTitle) {
        reasons.add('matching_task_title');
        score += 0.25;
      }

      final normalizedWorker = TextNormalizer.normalizeNullable(draft.workerName);
      if (normalizedWorker != null && TextNormalizer.normalizeNullable(task.workerName) == normalizedWorker) {
        reasons.add('matching_worker');
        score += 0.15;
      }

      if (draft.scheduledDate != null && task.scheduledDate != null) {
        final draftDate = _dateKey(draft.scheduledDate!.toUtc());
        final taskDate = _dateKey(task.scheduledDate!.toUtc());
        if (draftDate == taskDate) {
          reasons.add('matching_scheduled_date');
          score += 0.2;
        }
      }

      if (reasons.isNotEmpty) {
        candidates.add(
          DedupCandidate(
            recordType: 'task',
            recordId: task.id,
            score: score.clamp(0, 1).toDouble(),
            reasons: reasons,
          ),
        );
      }
    }

    return _sorted(candidates);
  }

  Future<List<DedupCandidate>> findProjectDuplicates(ProjectDraft draft) async {
    final projects = await projectRepository.listAll();
    final normalizedProjectName = TextNormalizer.normalize(draft.projectName);
    final normalizedLocation = TextNormalizer.normalizeNullable(draft.siteLocation);
    final candidates = <DedupCandidate>[];

    for (final project in projects) {
      if (project.archivedAt != null) {
        continue;
      }

      final reasons = <String>[];
      var score = 0.0;

      if (project.projectNameNormalized == normalizedProjectName) {
        reasons.add('matching_project_name');
        score += 0.7;
      }
      if (normalizedLocation != null && project.siteLocationNormalized == normalizedLocation) {
        reasons.add('matching_site_location');
        score += 0.2;
      }
      if (_trimOrNull(draft.clientOem) != null && project.clientOem == _trimOrNull(draft.clientOem)) {
        reasons.add('matching_client_oem');
        score += 0.1;
      }

      if (reasons.isNotEmpty) {
        candidates.add(
          DedupCandidate(
            recordType: 'project',
            recordId: project.id,
            score: score.clamp(0, 1).toDouble(),
            reasons: reasons,
          ),
        );
      }
    }

    return _sorted(candidates);
  }

  Future<List<DedupCandidate>> findMeetingDuplicates(MeetingEntity meeting) async {
    final meetings = await meetingRepository.listAll();
    final candidates = <DedupCandidate>[];
    final normalizedTitle = TextNormalizer.normalizeNullable(meeting.title);
    final normalizedSummary = TextNormalizer.normalizeNullable(meeting.summary);

    for (final existing in meetings) {
      if (existing.id == meeting.id || existing.archivedAt != null) {
        continue;
      }

      final reasons = <String>[];
      var score = 0.0;

      if (meeting.sourceHash != null && meeting.sourceHash == existing.sourceHash) {
        reasons.add('matching_source_hash');
        score += 0.8;
      }
      if (normalizedTitle != null && TextNormalizer.normalizeNullable(existing.title) == normalizedTitle) {
        reasons.add('matching_title');
        score += 0.1;
      }
      if (normalizedSummary != null && TextNormalizer.normalizeNullable(existing.summary) == normalizedSummary) {
        reasons.add('matching_summary');
        score += 0.05;
      }
      if (meeting.meetingDateTime != null && existing.meetingDateTime != null) {
        final deltaMinutes = meeting.meetingDateTime!
            .toUtc()
            .difference(existing.meetingDateTime!.toUtc())
            .inMinutes
            .abs();
        if (deltaMinutes <= 30) {
          reasons.add('nearby_meeting_time');
          score += 0.15;
        }
      }

      if (reasons.isNotEmpty) {
        candidates.add(
          DedupCandidate(
            recordType: 'meeting',
            recordId: existing.id,
            score: score.clamp(0, 1).toDouble(),
            reasons: reasons,
          ),
        );
      }
    }

    return _sorted(candidates);
  }

  List<DedupCandidate> _sorted(List<DedupCandidate> candidates) {
    candidates.sort((left, right) => right.score.compareTo(left.score));
    return candidates;
  }

  String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String? _trimOrNull(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}