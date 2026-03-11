import 'package:flutter/material.dart';

import '../../../app/app_runtime.dart';
import '../../../app/app_sections.dart';
import '../../../app/section_primitives.dart';
import '../../../domain/entities/meeting_entity.dart';
import '../../../domain/entities/meeting_task_candidate_entity.dart';
import '../../../domain/entities/raw_capture_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/enums/meeting_review_state.dart';
import '../application/meeting_review_models.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({
    super.key,
    required this.data,
    required this.controller,
    this.onDataChanged,
  });

  final AppShellData data;
  final AppShellController controller;
  final ValueChanged<AppShellData>? onDataChanged;

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final candidateItems = _meetingCandidates(widget.data);
    final pendingAiMeetings = _pendingAiMeetings(widget.data);
    final manualFallbackMeetings = _manualFallbackMeetings(widget.data);

    return FeatureSectionScaffold(
      title: 'Meeting Review Board',
      summary:
          'Audio-first intake, transcript review, linked projects, and task candidate resolution stay together so meetings do not flatten directly into final tasks.',
      accent: AppSection.meetings.accent,
      actions: const <ActionData>[
        ActionData(label: 'Record Meeting', icon: Icons.mic_rounded),
        ActionData(label: 'Finalize Minutes', icon: Icons.fact_check_rounded),
        ActionData(
          label: 'Export Minutes',
          icon: Icons.file_download_done_rounded,
        ),
      ],
      metrics: <MetricData>[
        MetricData(
          title: 'Draft Meetings',
          value:
              '${widget.data.meetings.where((meeting) => meeting.reviewState == MeetingReviewState.draftRecording || meeting.reviewState == MeetingReviewState.recordedPendingTranscription).length}',
          detail: 'New recordings with local audio already stored.',
          color: const Color(0xFF7A5D42),
        ),
        MetricData(
          title: 'AI Pending',
          value: '${pendingAiMeetings.length}',
          detail:
              'Meetings waiting on transcription or extraction, while remaining safe to continue manually.',
          color: const Color(0xFF3E7B7D),
        ),
        MetricData(
          title: 'Manual Fallback',
          value: '${manualFallbackMeetings.length}',
          detail:
              'Meetings moved out of AI flow but still editable and reviewable locally.',
          color: const Color(0xFFC06B37),
        ),
        MetricData(
          title: 'Review Required',
          value:
              '${widget.data.meetings.where((meeting) => _reviewStateNeedsAction(meeting.reviewState)).length}',
          detail: 'Meetings blocked behind transcript or candidate review.',
          color: const Color(0xFF4D5F8C),
        ),
        MetricData(
          title: 'Task Candidates',
          value: '${candidateItems.length}',
          detail: 'Extracted items waiting for accept, reject, or merge.',
          color: const Color(0xFF4D5F8C),
        ),
      ],
      sections: <Widget>[
        ResponsiveGrid(
          children: <Widget>[
            DetailCard(
              title: 'Meeting Lifecycle Queue',
              subtitle:
                  'Pending AI, failed AI, and manual-only meetings stay editable',
              children: _buildInteractiveMeetingLifecycleQueue(),
            ),
            DetailCard(
              title: 'Extracted Task Candidates',
              subtitle: 'Review before promotion',
              children: _buildInteractiveMeetingCandidateQueue(candidateItems),
            ),
          ],
        ),
        DetailCard(
          title: 'Manual Review Path',
          subtitle: 'Keep moving when AI is unavailable or not trusted',
          children: _buildManualFallbackRows(widget.data),
        ),
      ],
    );
  }

  List<Widget> _buildInteractiveMeetingLifecycleQueue() {
    final activeMeetings = widget.data.meetings
        .where((meeting) => meeting.archivedAt == null)
        .where(
          (meeting) =>
              _reviewStateNeedsAction(meeting.reviewState) ||
              _isPendingAiState(meeting.reviewState),
        )
        .take(5)
        .toList(growable: false);

    if (activeMeetings.isEmpty) {
      return const <Widget>[
        QueueItem(
          title: 'No active meeting review items',
          caption:
              'Pending AI, failed AI, and manual review meetings will surface here automatically.',
          status: 'Clear',
        ),
      ];
    }

    return activeMeetings.map((meeting) {
      final capture = _findCaptureForMeeting(widget.data, meeting);
      return QueueItem(
        title: meeting.title?.trim().isNotEmpty == true
            ? meeting.title!
            : 'Untitled meeting',
        caption: _meetingLifecycleCaption(meeting, capture),
        status: _meetingStatusLabel(meeting.reviewState),
        actions: <Widget>[
          FilledButton.icon(
            onPressed: _busy ? null : () => _openMeetingReview(meeting),
            icon: const Icon(Icons.rate_review_rounded),
            label: const Text('Review Meeting'),
          ),
        ],
      );
    }).toList(growable: false);
  }

  List<Widget> _buildInteractiveMeetingCandidateQueue(
    List<MeetingTaskCandidateEntity> candidates,
  ) {
    if (candidates.isEmpty) {
      return const <Widget>[
        QueueItem(
          title: 'No task candidates yet',
          caption:
              'Candidates will appear here after extraction and before task promotion.',
          status: 'Empty',
        )
      ];
    }

    return candidates.take(3).map((candidate) {
      final meeting = _meetingForCandidate(widget.data, candidate.id);
      final caption =
          'Confidence ${candidate.confidence.toStringAsFixed(2)} • ${candidate.projectName ?? 'No project yet'}';
      return QueueItem(
        title: candidate.taskTitle?.trim().isNotEmpty == true
            ? candidate.taskTitle!
            : candidate.taskType.name,
        caption: caption,
        status: candidate.state.name,
        actions: meeting == null
            ? const <Widget>[]
            : <Widget>[
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _openMeetingReview(meeting),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Meeting'),
                ),
              ],
      );
    }).toList(growable: false);
  }

  Future<void> _openMeetingReview(MeetingEntity meeting) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _MeetingReviewDialog(
          data: widget.data,
          meeting: meeting,
          busy: _busy,
          onSaveDraft: (MeetingReviewDraft draft) async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.updateMeetingDraft(
                meetingId: meeting.id,
                draft: draft,
              ),
              successMessage: 'Meeting notes saved.',
            );
          },
          onBeginReview: () async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.beginMeetingReview(meetingId: meeting.id),
              successMessage: 'Meeting moved into review.',
            );
          },
          onMoveToManual: (String reason, MeetingReviewDraft draft) async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.moveMeetingToManualReview(
                meetingId: meeting.id,
                reason: reason,
                draft: draft,
              ),
              successMessage: 'Meeting moved to manual review.',
            );
          },
          onBeginCandidateResolution: () async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.beginMeetingTaskCandidateResolution(
                meetingId: meeting.id,
              ),
              successMessage: 'Meeting moved to candidate resolution.',
            );
          },
          onFinalize: () async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.finalizeMeeting(meetingId: meeting.id),
              successMessage: 'Meeting finalized.',
            );
          },
          onAcceptCandidate: (String candidateId, String agenteeName) async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.acceptMeetingCandidateAsNewTask(
                meetingId: meeting.id,
                candidateId: candidateId,
                agenteeName: agenteeName,
              ),
              successMessage: 'Candidate promoted to a task.',
            );
          },
          onSaveCandidateProvisional:
              (String candidateId, String agenteeName) async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.saveMeetingCandidateAsProvisional(
                meetingId: meeting.id,
                candidateId: candidateId,
                agenteeName: agenteeName,
              ),
              successMessage: 'Candidate saved as provisional task.',
            );
          },
          onMergeCandidate: (String candidateId, String taskId) async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.mergeMeetingCandidateIntoTask(
                meetingId: meeting.id,
                candidateId: candidateId,
                taskId: taskId,
              ),
              successMessage: 'Candidate merged into an existing task.',
            );
          },
          onUpdateCandidate:
              (String candidateId, MeetingTaskCandidateDraft draft) async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.updateMeetingCandidate(
                meetingId: meeting.id,
                candidateId: candidateId,
                draft: draft,
              ),
              successMessage: 'Candidate changes saved.',
            );
          },
          onRejectCandidate: (String candidateId) async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.rejectMeetingCandidate(
                meetingId: meeting.id,
                candidateId: candidateId,
              ),
              successMessage: 'Candidate rejected.',
            );
          },
        );
      },
    );
  }

  Future<void> _runControllerAction(
    Future<AppShellData> Function() action, {
    required String successMessage,
  }) async {
    setState(() {
      _busy = true;
    });
    try {
      final updatedData = await action();
      widget.onDataChanged?.call(updatedData);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }
}

class _MeetingReviewDialog extends StatefulWidget {
  const _MeetingReviewDialog({
    required this.data,
    required this.meeting,
    required this.busy,
    required this.onSaveDraft,
    required this.onBeginReview,
    required this.onMoveToManual,
    required this.onBeginCandidateResolution,
    required this.onFinalize,
    required this.onAcceptCandidate,
    required this.onSaveCandidateProvisional,
    required this.onMergeCandidate,
    required this.onUpdateCandidate,
    required this.onRejectCandidate,
  });

  final AppShellData data;
  final MeetingEntity meeting;
  final bool busy;
  final Future<void> Function(MeetingReviewDraft draft) onSaveDraft;
  final Future<void> Function() onBeginReview;
  final Future<void> Function(String reason, MeetingReviewDraft draft)
      onMoveToManual;
  final Future<void> Function() onBeginCandidateResolution;
  final Future<void> Function() onFinalize;
  final Future<void> Function(String candidateId, String agenteeName)
      onAcceptCandidate;
  final Future<void> Function(String candidateId, String agenteeName)
      onSaveCandidateProvisional;
  final Future<void> Function(String candidateId, String taskId)
      onMergeCandidate;
  final Future<void> Function(String candidateId, MeetingTaskCandidateDraft draft)
      onUpdateCandidate;
  final Future<void> Function(String candidateId) onRejectCandidate;

  @override
  State<_MeetingReviewDialog> createState() => _MeetingReviewDialogState();
}

class _MeetingReviewDialogState extends State<_MeetingReviewDialog> {
  late final TextEditingController _transcriptController;
  late final TextEditingController _summaryController;
  late final TextEditingController _minutesController;
  late final TextEditingController _agenteeController;
  late final TextEditingController _manualFallbackReasonController;
  late final Set<String> _projectIds;

  @override
  void initState() {
    super.initState();
    _transcriptController =
        TextEditingController(text: widget.meeting.transcriptText ?? '');
    _summaryController =
        TextEditingController(text: widget.meeting.summary ?? '');
    _minutesController =
        TextEditingController(text: widget.meeting.minutesMarkdown ?? '');
    _agenteeController =
        TextEditingController(text: _defaultAgenteeName(widget.data));
    _manualFallbackReasonController = TextEditingController(
      text: _defaultManualFallbackReason(widget.meeting.reviewState),
    );
    _projectIds = widget.meeting.projectIds.toSet();
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    _summaryController.dispose();
    _minutesController.dispose();
    _agenteeController.dispose();
    _manualFallbackReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkedProjects = widget.data.projects
        .where((project) => project.archivedAt == null)
        .toList(growable: false);

    return AlertDialog(
      title: Text(widget.meeting.title ?? 'Review Meeting'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'State: ${_meetingStatusLabel(widget.meeting.reviewState)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _transcriptController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Transcript'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _summaryController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Summary'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minutesController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Minutes Markdown'),
              ),
              const SizedBox(height: 16),
              Text(
                'Linked Projects',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: linkedProjects
                    .map(
                      (project) => FilterChip(
                        label: Text(project.projectName),
                        selected: _projectIds.contains(project.id),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _projectIds.add(project.id);
                            } else {
                              _projectIds.remove(project.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
              if (_canMoveToManual(widget.meeting.reviewState)) ...<Widget>[
                const SizedBox(height: 16),
                TextField(
                  controller: _manualFallbackReasonController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Manual Fallback Reason',
                  ),
                ),
              ],
              if (widget.meeting.taskCandidates.isNotEmpty) ...<Widget>[
                const SizedBox(height: 20),
                Text(
                  'Task Candidates',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _agenteeController,
                  decoration: const InputDecoration(
                    labelText: 'Agentee Name For Task Actions',
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.meeting.taskCandidates.map(_buildCandidateCard),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: widget.busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (_canMoveToManual(widget.meeting.reviewState))
          OutlinedButton(
            onPressed: widget.busy ? null : _moveToManual,
            child: const Text('Manual Review'),
          ),
        if (_canBeginReview(widget.meeting.reviewState))
          OutlinedButton(
            onPressed: widget.busy ? null : widget.onBeginReview,
            child: const Text('Begin Review'),
          ),
        if (_canBeginCandidateResolution(widget.meeting))
          OutlinedButton(
            onPressed: widget.busy ? null : widget.onBeginCandidateResolution,
            child: const Text('Candidate Resolution'),
          ),
        TextButton(
          onPressed: widget.busy ? null : _saveDraft,
          child: const Text('Save Notes'),
        ),
        if (_canFinalize(widget.meeting.reviewState))
          FilledButton(
            onPressed: widget.busy ? null : widget.onFinalize,
            child: const Text('Finalize'),
          ),
      ],
    );
  }

  Widget _buildCandidateCard(MeetingTaskCandidateEntity candidate) {
    final agenteeName = _agenteeController.text.trim().isEmpty
        ? _defaultAgenteeName(widget.data)
        : _agenteeController.text.trim();
    final mergeableTasks = widget.data.tasks
        .where(
          (task) =>
              task.archivedAt == null &&
              (candidate.projectName == null ||
                  candidate.projectName!.trim().isEmpty ||
                  _taskProjectName(task, widget.data) == candidate.projectName),
        )
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: QueueItem(
        title: candidate.taskTitle?.trim().isNotEmpty == true
            ? candidate.taskTitle!
            : candidate.taskType.name,
        caption: _joinParts(<String?>[
          'Confidence ${candidate.confidence.toStringAsFixed(2)}',
          candidate.projectName,
          candidate.sourceSnippet,
        ]),
        status: candidate.state.name,
        actions: widget.meeting.reviewState ==
                MeetingReviewState.taskCandidateResolution
            ? <Widget>[
                OutlinedButton(
                  onPressed: widget.busy ? null : () => _editCandidate(candidate),
                  child: const Text('Edit'),
                ),
                FilledButton.tonal(
                  onPressed: widget.busy
                      ? null
                      : () => widget.onAcceptCandidate(candidate.id, agenteeName),
                  child: const Text('Create Task'),
                ),
                if (mergeableTasks.isNotEmpty)
                  OutlinedButton(
                    onPressed: widget.busy
                        ? null
                        : () => _mergeCandidate(candidate, mergeableTasks),
                    child: const Text('Merge Task'),
                  ),
                OutlinedButton(
                  onPressed: widget.busy
                      ? null
                      : () => widget.onSaveCandidateProvisional(
                            candidate.id,
                            agenteeName,
                          ),
                  child: const Text('Save Provisional'),
                ),
                TextButton(
                  onPressed: widget.busy
                      ? null
                      : () => widget.onRejectCandidate(candidate.id),
                  child: const Text('Reject'),
                ),
              ]
            : const <Widget>[],
      ),
    );
  }

  Future<void> _editCandidate(MeetingTaskCandidateEntity candidate) async {
    final draft = await showDialog<MeetingTaskCandidateDraft>(
      context: context,
      builder: (BuildContext context) {
        return _MeetingCandidateEditorDialog(candidate: candidate);
      },
    );
    if (draft == null || !mounted) {
      return;
    }
    await widget.onUpdateCandidate(candidate.id, draft);
  }

  Future<void> _mergeCandidate(
    MeetingTaskCandidateEntity candidate,
    List<TaskEntity> mergeableTasks,
  ) async {
    final taskId = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return _MeetingCandidateMergeDialog(
          candidate: candidate,
          tasks: mergeableTasks,
          data: widget.data,
        );
      },
    );
    if (taskId == null || !mounted) {
      return;
    }
    await widget.onMergeCandidate(candidate.id, taskId);
  }

  Future<void> _saveDraft() {
    return widget.onSaveDraft(_currentDraft());
  }

  Future<void> _moveToManual() {
    return widget.onMoveToManual(
      _manualFallbackReasonController.text.trim(),
      _currentDraft(),
    );
  }

  MeetingReviewDraft _currentDraft() {
    return MeetingReviewDraft(
      transcriptText: _transcriptController.text,
      summary: _summaryController.text,
      minutesMarkdown: _minutesController.text,
      projectIds: _projectIds.toList(growable: false),
    );
  }

  String? _taskProjectName(TaskEntity task, AppShellData data) {
    final project = data.projectById(task.projectId);
    return project?.projectName;
  }

  String _defaultManualFallbackReason(MeetingReviewState state) {
    switch (state) {
      case MeetingReviewState.transcriptionFailed:
        return 'Manual fallback after transcription failure.';
      case MeetingReviewState.extractionFailed:
        return 'Manual fallback after extraction failure.';
      case MeetingReviewState.recordedPendingTranscription:
      case MeetingReviewState.transcribedPendingExtraction:
        return 'Manual fallback while AI processing is unavailable.';
      default:
        return 'Manual fallback requested by agentee.';
    }
  }
}

class _MeetingCandidateEditorDialog extends StatefulWidget {
  const _MeetingCandidateEditorDialog({required this.candidate});

  final MeetingTaskCandidateEntity candidate;

  @override
  State<_MeetingCandidateEditorDialog> createState() =>
      _MeetingCandidateEditorDialogState();
}

class _MeetingCandidateEditorDialogState
    extends State<_MeetingCandidateEditorDialog> {
  late final TextEditingController _taskTitleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _projectNameController;
  late final TextEditingController _workerNameController;
  late final TextEditingController _workerPhoneController;
  late final TextEditingController _coordinatorController;
  late final TextEditingController _projectManagerController;
  late final TextEditingController _scheduledDateController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _durationController;
  late final TextEditingController _locationController;
  late final TextEditingController _ambiguitiesController;

  @override
  void initState() {
    super.initState();
    final candidate = widget.candidate;
    _taskTitleController = TextEditingController(text: candidate.taskTitle ?? '');
    _descriptionController = TextEditingController(text: candidate.description ?? '');
    _projectNameController = TextEditingController(text: candidate.projectName ?? '');
    _workerNameController = TextEditingController(text: candidate.workerName ?? '');
    _workerPhoneController = TextEditingController(text: candidate.workerPhone ?? '');
    _coordinatorController = TextEditingController(text: candidate.coordinatorName ?? '');
    _projectManagerController = TextEditingController(text: candidate.projectManagerName ?? '');
    _scheduledDateController = TextEditingController(text: candidate.scheduledDateText ?? '');
    _startTimeController = TextEditingController(text: candidate.startTimeText ?? '');
    _durationController = TextEditingController(text: candidate.durationText ?? '');
    _locationController = TextEditingController(text: candidate.locationText ?? '');
    _ambiguitiesController = TextEditingController(text: candidate.ambiguities.join('\n'));
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _descriptionController.dispose();
    _projectNameController.dispose();
    _workerNameController.dispose();
    _workerPhoneController.dispose();
    _coordinatorController.dispose();
    _projectManagerController.dispose();
    _scheduledDateController.dispose();
    _startTimeController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    _ambiguitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Candidate'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _taskTitleController,
                decoration: const InputDecoration(labelText: 'Candidate Task Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Candidate Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _projectNameController,
                decoration: const InputDecoration(labelText: 'Candidate Project Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _workerNameController,
                decoration: const InputDecoration(labelText: 'Worker Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _workerPhoneController,
                decoration: const InputDecoration(labelText: 'Worker Phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _coordinatorController,
                decoration: const InputDecoration(labelText: 'Coordinator Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _projectManagerController,
                decoration: const InputDecoration(labelText: 'Project Manager Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _scheduledDateController,
                decoration: const InputDecoration(labelText: 'Scheduled Date Text'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time Text'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duration Text'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location Text'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ambiguitiesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Ambiguities'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              MeetingTaskCandidateDraft(
                taskTitle: _taskTitleController.text,
                description: _descriptionController.text,
                projectName: _projectNameController.text,
                workerName: _workerNameController.text,
                workerPhone: _workerPhoneController.text,
                coordinatorName: _coordinatorController.text,
                projectManagerName: _projectManagerController.text,
                scheduledDateText: _scheduledDateController.text,
                startTimeText: _startTimeController.text,
                durationText: _durationController.text,
                locationText: _locationController.text,
                ambiguities: _ambiguitiesController.text
                    .split('\n')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList(growable: false),
              ),
            );
          },
          child: const Text('Save Candidate'),
        ),
      ],
    );
  }
}

class _MeetingCandidateMergeDialog extends StatefulWidget {
  const _MeetingCandidateMergeDialog({
    required this.candidate,
    required this.tasks,
    required this.data,
  });

  final MeetingTaskCandidateEntity candidate;
  final List<TaskEntity> tasks;
  final AppShellData data;

  @override
  State<_MeetingCandidateMergeDialog> createState() =>
      _MeetingCandidateMergeDialogState();
}

class _MeetingCandidateMergeDialogState
    extends State<_MeetingCandidateMergeDialog> {
  String? _selectedTaskId;

  @override
  void initState() {
    super.initState();
    if (widget.tasks.isNotEmpty) {
      _selectedTaskId = widget.tasks.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Merge Candidate Into Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(widget.candidate.taskTitle ?? widget.candidate.taskType.name),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedTaskId,
            items: widget.tasks
                .map(
                  (task) => DropdownMenuItem<String>(
                    value: task.id,
                    child: Text(_taskLabel(task)),
                  ),
                )
                .toList(growable: false),
            onChanged: (String? value) {
              setState(() {
                _selectedTaskId = value;
              });
            },
            decoration: const InputDecoration(labelText: 'Existing Task'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedTaskId == null
              ? null
              : () => Navigator.of(context).pop(_selectedTaskId),
          child: const Text('Merge'),
        ),
      ],
    );
  }

  String _taskLabel(TaskEntity task) {
    final project = widget.data.projectById(task.projectId);
    return _joinParts(<String?>[
      task.taskTitle,
      project?.projectName,
      task.status.name,
    ]);
  }
}

List<MeetingTaskCandidateEntity> _meetingCandidates(AppShellData data) {
  return data.meetings
      .expand((meeting) => meeting.taskCandidates)
      .take(5)
      .toList(growable: false);
}

List<MeetingEntity> _pendingAiMeetings(AppShellData data) {
  return data.meetings
      .where((meeting) =>
          _isPendingAiState(meeting.reviewState) && meeting.archivedAt == null)
      .toList(growable: false);
}

List<MeetingEntity> _manualFallbackMeetings(AppShellData data) {
  return data.meetings
      .where((meeting) =>
          meeting.reviewState == MeetingReviewState.manualReviewOnly &&
          meeting.archivedAt == null)
      .toList(growable: false);
}

bool _reviewStateNeedsAction(MeetingReviewState state) {
  return state == MeetingReviewState.reviewRequired ||
      state == MeetingReviewState.reviewInProgress ||
      state == MeetingReviewState.taskCandidateResolution ||
      state == MeetingReviewState.manualReviewOnly ||
      state == MeetingReviewState.transcriptionFailed ||
      state == MeetingReviewState.extractionFailed;
}

List<Widget> _buildManualFallbackRows(AppShellData data) {
  final manualMeetings = _manualFallbackMeetings(data);
  final failedMeetings = data.meetings
      .where((meeting) =>
          meeting.reviewState == MeetingReviewState.transcriptionFailed ||
          meeting.reviewState == MeetingReviewState.extractionFailed)
      .where((meeting) => meeting.archivedAt == null)
      .take(3)
      .toList(growable: false);

  if (manualMeetings.isEmpty && failedMeetings.isEmpty) {
    return const <Widget>[
      InfoRow(
        label: 'Fallback',
        value:
            'When AI is unavailable, move the meeting to manual review and continue editing summary, minutes, transcript, and project links locally.',
      ),
      InfoRow(
        label: 'Finalize',
        value:
            'Meetings can still be finalized after manual notes are captured, without waiting for successful extraction.',
      ),
      InfoRow(
        label: 'Retry',
        value:
            'Retry transcription or extraction later only when the operator decides it is worth it.',
      ),
    ];
  }

  final rows = <Widget>[];
  for (final meeting in failedMeetings) {
    final capture = _findCaptureForMeeting(data, meeting);
    rows.add(
      InfoRow(
        label: _meetingStatusLabel(meeting.reviewState),
        value:
            '${meeting.title ?? 'Untitled meeting'} • ${capture?.transcriptionError?.trim().isNotEmpty == true ? capture!.transcriptionError! : 'Move to manual review to continue without blocking on AI.'}',
      ),
    );
  }
  for (final meeting in manualMeetings.take(3)) {
    rows.add(
      InfoRow(
        label: 'Manual fallback',
        value:
            '${meeting.title ?? 'Untitled meeting'} • ${_manualFallbackDetail(meeting)}',
      ),
    );
  }
  return rows;
}

RawCaptureEntity? _findCaptureForMeeting(AppShellData data, MeetingEntity meeting) {
  final sourceCaptureId = meeting.sourceCaptureId;
  if (sourceCaptureId == null || sourceCaptureId.isEmpty) {
    return null;
  }
  for (final capture in data.rawCaptures) {
    if (capture.id == sourceCaptureId) {
      return capture;
    }
  }
  return null;
}

bool _canMoveToManual(MeetingReviewState state) {
  return state == MeetingReviewState.recordedPendingTranscription ||
      state == MeetingReviewState.transcriptionFailed ||
      state == MeetingReviewState.transcribedPendingExtraction ||
      state == MeetingReviewState.extractionFailed;
}

bool _canBeginReview(MeetingReviewState state) {
  return state == MeetingReviewState.reviewRequired ||
      state == MeetingReviewState.manualReviewOnly ||
      state == MeetingReviewState.reopened;
}

bool _canBeginCandidateResolution(MeetingEntity meeting) {
  return meeting.taskCandidates.isNotEmpty &&
      (meeting.reviewState == MeetingReviewState.reviewInProgress ||
          meeting.reviewState == MeetingReviewState.reviewRequired);
}

bool _canFinalize(MeetingReviewState state) {
  return state == MeetingReviewState.manualReviewOnly ||
      state == MeetingReviewState.reviewRequired ||
      state == MeetingReviewState.reviewInProgress ||
      state == MeetingReviewState.taskCandidateResolution ||
      state == MeetingReviewState.reopened;
}

bool _isPendingAiState(MeetingReviewState state) {
  return state == MeetingReviewState.recordedPendingTranscription ||
      state == MeetingReviewState.transcribing ||
      state == MeetingReviewState.transcribedPendingExtraction ||
      state == MeetingReviewState.extracting;
}

String _meetingStatusLabel(MeetingReviewState state) {
  switch (state) {
    case MeetingReviewState.recordedPendingTranscription:
    case MeetingReviewState.transcribing:
    case MeetingReviewState.transcribedPendingExtraction:
    case MeetingReviewState.extracting:
      return 'AI pending';
    case MeetingReviewState.transcriptionFailed:
      return 'Transcription failed';
    case MeetingReviewState.extractionFailed:
      return 'Extraction failed';
    case MeetingReviewState.manualReviewOnly:
      return 'Manual fallback';
    case MeetingReviewState.reviewRequired:
      return 'Review required';
    case MeetingReviewState.reviewInProgress:
      return 'In review';
    case MeetingReviewState.taskCandidateResolution:
      return 'Resolve tasks';
    case MeetingReviewState.finalized:
      return 'Finalized';
    case MeetingReviewState.reopened:
      return 'Reopened';
    case MeetingReviewState.archived:
      return 'Archived';
    case MeetingReviewState.cancelled:
      return 'Cancelled';
    case MeetingReviewState.draftRecording:
      return 'Recording';
  }
}

String _meetingLifecycleCaption(MeetingEntity meeting, RawCaptureEntity? capture) {
  final details = <String>[];

  switch (meeting.reviewState) {
    case MeetingReviewState.recordedPendingTranscription:
      details.add(
        'Audio is saved locally and ready for transcription or manual review.',
      );
      break;
    case MeetingReviewState.transcribing:
      details.add(
        'Transcription is in progress. The operator can still switch to manual review.',
      );
      break;
    case MeetingReviewState.transcribedPendingExtraction:
      details.add(
        'Transcript is ready. Start extraction later or continue with manual notes now.',
      );
      break;
    case MeetingReviewState.extracting:
      details.add(
        'Extraction is running. Manual editing remains available if the result is not usable.',
      );
      break;
    case MeetingReviewState.transcriptionFailed:
    case MeetingReviewState.extractionFailed:
      details.add(
        capture?.transcriptionError?.trim().isNotEmpty == true
            ? capture!.transcriptionError!
            : 'The last AI step failed. Move to manual review to continue locally.',
      );
      break;
    case MeetingReviewState.manualReviewOnly:
      details.add(_manualFallbackDetail(meeting));
      break;
    case MeetingReviewState.reviewRequired:
    case MeetingReviewState.reviewInProgress:
    case MeetingReviewState.taskCandidateResolution:
      details.add(
        '${meeting.taskCandidates.length} task candidates remain reviewable before final save.',
      );
      break;
    case MeetingReviewState.finalized:
      details.add('Meeting record is finalized locally.');
      break;
    case MeetingReviewState.reopened:
      details.add('Meeting was reopened for corrections.');
      break;
    case MeetingReviewState.archived:
      details.add('Meeting remains preserved in local archive.');
      break;
    case MeetingReviewState.cancelled:
      details.add('Meeting capture was cancelled.');
      break;
    case MeetingReviewState.draftRecording:
      details.add('Recording is still in progress.');
      break;
  }

  if (meeting.projectIds.isNotEmpty) {
    details.add('${meeting.projectIds.length} linked projects');
  }
  if (meeting.taskCandidates.isNotEmpty) {
    details.add('${meeting.taskCandidates.length} task candidates');
  }

  return details.join(' • ');
}

String _manualFallbackDetail(MeetingEntity meeting) {
  final items = <String>[];
  if (meeting.transcriptText?.trim().isNotEmpty == true) {
    items.add('Transcript preserved');
  }
  if (meeting.summary?.trim().isNotEmpty == true) {
    items.add('Summary editable');
  }
  if (meeting.minutesMarkdown?.trim().isNotEmpty == true) {
    items.add('Minutes editable');
  }
  if (items.isEmpty) {
    return 'No AI output is required. Add manual transcript or notes and continue review.';
  }
  return '${items.join(', ')} while staying outside the AI path.';
}

String _defaultAgenteeName(AppShellData data) {
  for (final task in data.tasks) {
    if (task.agenteeName.trim().isNotEmpty) {
      return task.agenteeName.trim();
    }
  }
  return 'Local Agentee';
}

MeetingEntity? _meetingForCandidate(AppShellData data, String candidateId) {
  for (final meeting in data.meetings) {
    for (final candidate in meeting.taskCandidates) {
      if (candidate.id == candidateId) {
        return meeting;
      }
    }
  }
  return null;
}

String _joinParts(List<String?> parts) {
  return parts
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .join(' • ');
}
