import '../../../core/audit/audit_log_service.dart';
import '../../../data/database/repositories/meeting_repository.dart';
import '../../../data/database/repositories/project_repository.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/meeting_task_candidate_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/enums/task_candidate_state.dart';
import '../../../domain/enums/task_priority.dart';
import '../../../domain/enums/task_status.dart';
import '../../tasks/application/task_crud_service.dart';
import '../../tasks/application/task_models.dart';

class MeetingTaskCandidateResolutionResult {
  const MeetingTaskCandidateResolutionResult({
    required this.meeting,
    required this.candidate,
    this.task,
  });

  final MeetingEntity meeting;
  final MeetingTaskCandidateEntity candidate;
  final TaskEntity? task;
}

class MeetingTaskCandidateResolutionService {
  const MeetingTaskCandidateResolutionService({
    required this.meetingRepository,
    required this.projectRepository,
    required this.taskCrudService,
    required this.auditLogService,
  });

  final MeetingRepository meetingRepository;
  final ProjectRepository projectRepository;
  final TaskCrudService taskCrudService;
  final AuditLogService auditLogService;

  Future<MeetingTaskCandidateResolutionResult> acceptAsNewTask({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) {
    return _resolveWithCreatedTask(
      meetingId: meetingId,
      candidateId: candidateId,
      agenteeName: agenteeName,
      targetState: TaskCandidateState.acceptedAsNewTask,
      isProvisional: false,
      needsReview: false,
      actorName: actorName,
    );
  }

  Future<MeetingTaskCandidateResolutionResult> saveAsProvisionalTask({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) {
    return _resolveWithCreatedTask(
      meetingId: meetingId,
      candidateId: candidateId,
      agenteeName: agenteeName,
      targetState: TaskCandidateState.savedAsProvisionalTask,
      isProvisional: true,
      needsReview: true,
      actorName: actorName,
    );
  }

  Future<MeetingTaskCandidateResolutionResult> mergeIntoExistingTask({
    required String meetingId,
    required String candidateId,
    required String taskId,
    String? actorName,
  }) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null) {
      throw StateError('Meeting not found: $meetingId');
    }
    final existingTask = await taskCrudService.requireDetail(taskId);
    final candidate = _requireCandidate(meeting, candidateId);
    final updatedMeeting = await _updateCandidateState(
      meeting: meeting,
      candidateId: candidate.id,
      state: TaskCandidateState.mergedIntoExistingTask,
      linkedTaskId: existingTask.id,
      actorName: actorName,
    );
    final updatedCandidate = _requireCandidate(updatedMeeting, candidate.id);
    return MeetingTaskCandidateResolutionResult(
      meeting: updatedMeeting,
      candidate: updatedCandidate,
      task: existingTask,
    );
  }

  Future<MeetingTaskCandidateResolutionResult> rejectCandidate({
    required String meetingId,
    required String candidateId,
    String? actorName,
  }) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null) {
      throw StateError('Meeting not found: $meetingId');
    }
    final candidate = _requireCandidate(meeting, candidateId);
    final updatedMeeting = await _updateCandidateState(
      meeting: meeting,
      candidateId: candidate.id,
      state: TaskCandidateState.rejected,
      linkedTaskId: null,
      actorName: actorName,
    );
    return MeetingTaskCandidateResolutionResult(
      meeting: updatedMeeting,
      candidate: _requireCandidate(updatedMeeting, candidate.id),
    );
  }

  Future<MeetingTaskCandidateResolutionResult> _resolveWithCreatedTask({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    required TaskCandidateState targetState,
    required bool isProvisional,
    required bool needsReview,
    String? actorName,
  }) async {
    final meeting = await meetingRepository.findById(meetingId);
    if (meeting == null) {
      throw StateError('Meeting not found: $meetingId');
    }
    final candidate = _requireCandidate(meeting, candidateId);
    final task = await taskCrudService.create(
      _taskDraftFromCandidate(
        meeting: meeting,
        candidate: candidate,
        agenteeName: agenteeName,
        isProvisional: isProvisional,
        needsReview: needsReview,
      ),
      actorName: actorName,
    );
    final updatedMeeting = await _updateCandidateState(
      meeting: meeting,
      candidateId: candidate.id,
      state: targetState,
      linkedTaskId: task.id,
      actorName: actorName,
    );
    final updatedCandidate = _requireCandidate(updatedMeeting, candidate.id);
    return MeetingTaskCandidateResolutionResult(
      meeting: updatedMeeting,
      candidate: updatedCandidate,
      task: task,
    );
  }

  Future<MeetingEntity> _updateCandidateState({
    required MeetingEntity meeting,
    required String candidateId,
    required TaskCandidateState state,
    required String? linkedTaskId,
    String? actorName,
  }) async {
    final updatedCandidates = meeting.taskCandidates.map((candidate) {
      if (candidate.id != candidateId) {
        return candidate;
      }
      return MeetingTaskCandidateEntity(
        id: candidate.id,
        taskType: candidate.taskType,
        state: state,
        confidence: candidate.confidence,
        sourceSnippet: candidate.sourceSnippet,
        taskTitle: candidate.taskTitle,
        description: candidate.description,
        projectName: candidate.projectName,
        workerName: candidate.workerName,
        workerPhone: candidate.workerPhone,
        coordinatorName: candidate.coordinatorName,
        projectManagerName: candidate.projectManagerName,
        scheduledDateText: candidate.scheduledDateText,
        startTimeText: candidate.startTimeText,
        durationText: candidate.durationText,
        locationText: candidate.locationText,
        ambiguities: candidate.ambiguities,
        linkedTaskId: linkedTaskId,
      );
    }).toList(growable: false);

    final updatedMeeting = MeetingEntity(
      id: meeting.id,
      title: meeting.title,
      meetingDateTime: meeting.meetingDateTime,
      meetingTimezone: meeting.meetingTimezone,
      locationText: meeting.locationText,
      summary: meeting.summary,
      minutesMarkdown: meeting.minutesMarkdown,
      transcriptText: meeting.transcriptText,
      sourceCaptureId: meeting.sourceCaptureId,
      sourceHash: meeting.sourceHash,
      reviewState: meeting.reviewState,
      needsReview: meeting.needsReview,
      projectIds: meeting.projectIds,
      taskCandidates: updatedCandidates,
      createdAt: meeting.createdAt,
      updatedAt: DateTime.now().toUtc(),
      archivedAt: meeting.archivedAt,
    );

    await meetingRepository.save(updatedMeeting);
    await auditLogService.logUpdate(
      recordType: 'meeting',
      recordId: updatedMeeting.id,
      before: _meetingSnapshot(meeting),
      after: _meetingSnapshot(updatedMeeting),
      sourceCaptureId: updatedMeeting.sourceCaptureId,
      actorName: actorName,
    );
    return updatedMeeting;
  }

  TaskDraft _taskDraftFromCandidate({
    required MeetingEntity meeting,
    required MeetingTaskCandidateEntity candidate,
    required String agenteeName,
    required bool isProvisional,
    required bool needsReview,
  }) {
    return TaskDraft(
      projectId: null,
      projectName: candidate.projectName,
      taskType: candidate.taskType,
      taskTitle: candidate.taskTitle,
      description: candidate.description,
      scheduledDate: _parseDate(candidate.scheduledDateText),
      startTimeLocal: candidate.startTimeText,
      durationMinutes: null,
      locationSnapshot: candidate.locationText ?? meeting.locationText,
      workerName: candidate.workerName,
      workerPhone: candidate.workerPhone,
      coordinatorName: candidate.coordinatorName,
      projectManagerName: candidate.projectManagerName,
      agenteeName: agenteeName,
      status: _statusFromCandidate(candidate),
      priority: _priorityFromCandidate(candidate),
      sourceCaptureId: meeting.sourceCaptureId,
      isProvisional: isProvisional,
      needsReview: needsReview,
    );
  }

  MeetingTaskCandidateEntity _requireCandidate(MeetingEntity meeting, String candidateId) {
    for (final candidate in meeting.taskCandidates) {
      if (candidate.id == candidateId) {
        return candidate;
      }
    }
    throw StateError('Meeting task candidate not found: $candidateId');
  }

  TaskStatus _statusFromCandidate(MeetingTaskCandidateEntity candidate) {
    return TaskStatus.planned;
  }

  TaskPriority _priorityFromCandidate(MeetingTaskCandidateEntity candidate) {
    final title = candidate.taskTitle?.toLowerCase() ?? '';
    if (title.contains('urgent') || title.contains('critical')) {
      return TaskPriority.high;
    }
    return TaskPriority.medium;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.trim())?.toUtc();
  }

  Map<String, Object?> _meetingSnapshot(MeetingEntity meeting) {
    return <String, Object?>{
      'id': meeting.id,
      'task_candidates': meeting.taskCandidates
          .map(
            (candidate) => <String, Object?>{
              'id': candidate.id,
              'state': candidate.state.storageValue,
              'linked_task_id': candidate.linkedTaskId,
            },
          )
          .toList(growable: false),
      'updated_at': meeting.updatedAt,
    };
  }
}