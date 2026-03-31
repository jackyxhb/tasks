import 'package:flutter/material.dart';

import '../../../app/app_runtime.dart';
import '../../../app/app_sections.dart';
import '../../../app/section_primitives.dart';
import '../../../domain/entities/raw_capture_entity.dart';
import '../../../domain/enums/raw_capture_parse_status.dart';
import '../../../domain/enums/task_priority.dart';
import '../../../domain/enums/task_status.dart';
import '../../../domain/enums/task_type.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({
    super.key,
    required this.data,
    required this.controller,
    this.onDataChanged,
  });

  final AppShellData data;
  final AppShellController controller;
  final ValueChanged<AppShellData>? onDataChanged;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final pendingCaptures = _pendingCaptures(widget.data);

    return FeatureSectionScaffold(
      title: 'Inbox Review Queue',
      summary:
          'Newest captures first, with duplicate risk and confidence visible before anything is finalized.',
      accent: AppSection.inbox.accent,
      actions: const <ActionData>[
        ActionData(label: 'Review', icon: Icons.rate_review_rounded),
        ActionData(label: 'Merge', icon: Icons.merge_rounded),
        ActionData(label: 'Create New', icon: Icons.add_circle_outline_rounded),
        ActionData(label: 'Mark Later', icon: Icons.schedule_rounded),
      ],
      metrics: <MetricData>[
        MetricData(
          title: 'Unreviewed',
          value: '${pendingCaptures.length}',
          detail: 'Raw captures waiting for correction or promotion.',
          color: const Color(0xFFC06B37),
        ),
        MetricData(
          title: 'Low Confidence',
          value:
              '${pendingCaptures.where((capture) => (capture.classificationConfidence ?? 1) < 0.7).length}',
          detail: 'Items that should stay visible until manually checked.',
          color: const Color(0xFFB34A3C),
        ),
        MetricData(
          title: 'Duplicate Risks',
          value: '${_duplicateRiskCount(widget.data)}',
          detail: 'Likely overlaps with recent projects or task records.',
          color: const Color(0xFF5A5E9A),
        ),
      ],
      sections: <Widget>[
        DetailCard(
          title: 'Unreviewed Captures',
          subtitle: 'Source channel, confidence, and project guess',
          children: _buildInteractiveCaptureQueue(pendingCaptures),
        ),
        const ResponsiveGrid(
          children: <Widget>[
            DetailCard(
              title: 'Review Rules',
              subtitle: 'Guardrails before final save',
              children: <Widget>[
                InfoRow(
                  label: 'Project link',
                  value:
                      'Accept, replace, or leave unresolved without blocking provisional save.',
                ),
                InfoRow(
                  label: 'Confidence',
                  value:
                      'Show field-level uncertainty before finalizing records.',
                ),
                InfoRow(
                  label: 'Duplicates',
                  value: 'Offer merge instead of silent overwrite.',
                ),
              ],
            ),
            DetailCard(
              title: 'Suggested Next Actions',
              subtitle: 'Fast correction loop',
              children: <Widget>[
                InfoRow(
                  label: '1',
                  value:
                      'Review all meeting captures with confidence below 0.70 first.',
                ),
                InfoRow(
                  label: '2',
                  value:
                      'Merge duplicate task requests before creating new records.',
                ),
                InfoRow(
                  label: '3',
                  value:
                      'Save ambiguous items as provisional instead of blocking intake.',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildInteractiveCaptureQueue(List<RawCaptureEntity> pendingCaptures) {
    if (pendingCaptures.isEmpty) {
      return const <Widget>[
        QueueItem(
          title: 'Inbox is clear',
          caption: 'All local captures are reviewed or finalized.',
          status: 'Clear',
        ),
      ];
    }

    return pendingCaptures.map((capture) {
      final confidence = capture.classificationConfidence == null
          ? 'n/a'
          : capture.classificationConfidence!.toStringAsFixed(2);
      final title = _captureTitle(capture);
      final caption =
          'Detected type: ${capture.classificationType} • Confidence $confidence • Captured ${_dateLabel(capture.captureTime)}';
      final status = capture.parseStatus == RawCaptureParseStatus.failed
          ? 'Failed'
          : (capture.classificationConfidence ?? 1) < 0.7
              ? 'Low confidence'
              : 'Review';

      return QueueItem(
        title: title,
        caption: caption,
        status: status,
        actions: <Widget>[
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _markCaptureReviewed(capture.id),
            icon: const Icon(Icons.done_all_rounded),
            label: const Text('Mark Reviewed'),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : () => _openCaptureReview(capture),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Review Task'),
          ),
        ],
      );
    }).toList(growable: false);
  }

  Future<void> _markCaptureReviewed(String captureId) async {
    await _runControllerAction(
      () => widget.controller.markCaptureReviewed(captureId: captureId),
      successMessage: 'Capture marked as reviewed.',
    );
  }

  Future<void> _openCaptureReview(RawCaptureEntity capture) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _CaptureReviewDialog(
          capture: capture,
          data: widget.data,
          onSubmit: (CaptureTaskReviewDraft draft) async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => widget.controller.createTaskFromCapture(draft: draft),
              successMessage: 'Task created from inbox review.',
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

class _CaptureReviewDialog extends StatefulWidget {
  const _CaptureReviewDialog({
    required this.capture,
    required this.data,
    required this.onSubmit,
  });

  final RawCaptureEntity capture;
  final AppShellData data;
  final Future<void> Function(CaptureTaskReviewDraft draft) onSubmit;

  @override
  State<_CaptureReviewDialog> createState() => _CaptureReviewDialogState();
}

class _CaptureReviewDialogState extends State<_CaptureReviewDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _locationController;
  late final TextEditingController _workerController;
  late final TextEditingController _workerPhoneController;
  late final TextEditingController _coordinatorController;
  late final TextEditingController _projectManagerController;
  late final TextEditingController _agenteeController;
  late String _classificationType;
  late TaskType _taskType;
  late TaskStatus _taskStatus;
  late TaskPriority _taskPriority;
  String? _projectId;
  bool _isProvisional = true;
  bool _needsReview = true;

  @override
  void initState() {
    super.initState();
    _classificationType =
        _normalizedClassificationType(widget.capture.classificationType);
    _taskType = TaskType.unknown;
    _taskStatus = TaskStatus.planned;
    _taskPriority = TaskPriority.medium;
    _titleController = TextEditingController(text: _captureTitle(widget.capture));
    _descriptionController = TextEditingController(
      text: widget.capture.rawText ?? widget.capture.transcriptText ?? '',
    );
    _dateController = TextEditingController();
    _startTimeController = TextEditingController();
    _locationController = TextEditingController();
    _workerController = TextEditingController();
    _workerPhoneController = TextEditingController();
    _coordinatorController = TextEditingController();
    _projectManagerController = TextEditingController();
    _agenteeController = TextEditingController(
      text: _defaultAgenteeName(widget.data),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _locationController.dispose();
    _workerController.dispose();
    _workerPhoneController.dispose();
    _coordinatorController.dispose();
    _projectManagerController.dispose();
    _agenteeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Review Capture'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DropdownButtonFormField<String>(
                initialValue: _classificationType,
                decoration:
                    const InputDecoration(labelText: 'Classification Type'),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'task', child: Text('Task')),
                  DropdownMenuItem<String>(
                    value: 'project',
                    child: Text('Project'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'meeting',
                    child: Text('Meeting'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'unknown',
                    child: Text('Unknown'),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _classificationType = value ?? 'unknown';
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _projectId,
                decoration: const InputDecoration(labelText: 'Linked Project'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No linked project'),
                  ),
                  ...widget.data.projects
                      .where((project) => project.archivedAt == null)
                      .map(
                        (project) => DropdownMenuItem<String?>(
                          value: project.id,
                          child: Text(project.projectName),
                        ),
                      ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _projectId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskType>(
                initialValue: _taskType,
                decoration: const InputDecoration(labelText: 'Task Type'),
                items: TaskType.values
                    .map(
                      (taskType) => DropdownMenuItem<TaskType>(
                        value: taskType,
                        child: Text(_taskTypeLabel(taskType)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (TaskType? value) {
                  setState(() {
                    _taskType = value ?? TaskType.unknown;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Scheduled Date (YYYY-MM-DD)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _startTimeController,
                decoration: const InputDecoration(labelText: 'Start Time'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _workerController,
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
                decoration: const InputDecoration(labelText: 'Coordinator'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _projectManagerController,
                decoration: const InputDecoration(labelText: 'Project Manager'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _agenteeController,
                decoration: const InputDecoration(labelText: 'Agentee Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskStatus>(
                initialValue: _taskStatus,
                decoration: const InputDecoration(labelText: 'Task Status'),
                items: TaskStatus.values
                    .map(
                      (status) => DropdownMenuItem<TaskStatus>(
                        value: status,
                        child: Text(_taskStatusLabel(status)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (TaskStatus? value) {
                  setState(() {
                    _taskStatus = value ?? TaskStatus.planned;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _taskPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: TaskPriority.values
                    .map(
                      (priority) => DropdownMenuItem<TaskPriority>(
                        value: priority,
                        child: Text(_taskPriorityLabel(priority)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (TaskPriority? value) {
                  setState(() {
                    _taskPriority = value ?? TaskPriority.medium;
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isProvisional,
                onChanged: (bool value) {
                  setState(() {
                    _isProvisional = value;
                  });
                },
                title: const Text('Save as provisional'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _needsReview,
                onChanged: (bool value) {
                  setState(() {
                    _needsReview = value;
                  });
                },
                title: const Text('Keep task review flag'),
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
          onPressed: _classificationType == 'task' ? _submit : null,
          child: const Text('Create Task'),
        ),
      ],
    );
  }

  Future<void> _submit() {
    return widget.onSubmit(
      CaptureTaskReviewDraft(
        captureId: widget.capture.id,
        classificationType: _classificationType,
        classificationConfidence:
            widget.capture.classificationConfidence ?? 0.85,
        projectId: _projectId,
        taskType: _taskType,
        taskTitle: _titleController.text,
        description: _descriptionController.text,
        scheduledDateText: _dateController.text,
        startTimeLocal: _startTimeController.text,
        locationSnapshot: _locationController.text,
        workerName: _workerController.text,
        workerPhone: _workerPhoneController.text,
        coordinatorName: _coordinatorController.text,
        projectManagerName: _projectManagerController.text,
        agenteeName: _agenteeController.text.trim().isEmpty
            ? _defaultAgenteeName(widget.data)
            : _agenteeController.text.trim(),
        status: _taskStatus,
        priority: _taskPriority,
        isProvisional: _isProvisional,
        needsReview: _needsReview,
      ),
    );
  }
}

List<RawCaptureEntity> _pendingCaptures(AppShellData data) {
  return data.rawCaptures
      .where((capture) => capture.parseStatus != RawCaptureParseStatus.reviewed)
      .take(5)
      .toList(growable: false);
}

int _duplicateRiskCount(AppShellData data) {
  final frequency = <String, int>{};
  for (final capture in data.rawCaptures) {
    final hash = capture.sourceHash;
    if (hash == null || hash.isEmpty) {
      continue;
    }
    frequency[hash] = (frequency[hash] ?? 0) + 1;
  }
  return frequency.values.where((count) => count > 1).length;
}

String _captureTitle(RawCaptureEntity capture) {
  if (capture.rawText?.split('\n').first.trim().isNotEmpty == true) {
    return capture.rawText!.split('\n').first.trim();
  }
  if (capture.transcriptText?.split('\n').first.trim().isNotEmpty == true) {
    return capture.transcriptText!.split('\n').first.trim();
  }
  return 'Captured ${capture.channel.name}';
}

String _normalizedClassificationType(String value) {
  const supported = <String>{'task', 'project', 'meeting', 'mixed', 'unknown'};
  return supported.contains(value) ? value : 'unknown';
}

String _defaultAgenteeName(AppShellData data) {
  for (final task in data.tasks) {
    if (task.agenteeName.trim().isNotEmpty) {
      return task.agenteeName.trim();
    }
  }
  return 'Local Agentee';
}

String _taskTypeLabel(TaskType taskType) {
  switch (taskType) {
    case TaskType.siteSurvey:
      return 'Site Survey';
    case TaskType.installation:
      return 'Installation';
    case TaskType.tuning:
      return 'Tuning';
    case TaskType.handover:
      return 'Handover';
    case TaskType.maintenance:
      return 'Maintenance';
    case TaskType.unknown:
      return 'Unknown';
  }
}

String _taskStatusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.planned:
      return 'Planned';
    case TaskStatus.inProgress:
      return 'In Progress';
    case TaskStatus.blocked:
      return 'Blocked';
    case TaskStatus.completed:
      return 'Completed';
    case TaskStatus.cancelled:
      return 'Cancelled';
  }
}

String _taskPriorityLabel(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.low:
      return 'Low';
    case TaskPriority.medium:
      return 'Medium';
    case TaskPriority.high:
      return 'High';
    case TaskPriority.critical:
      return 'Critical';
  }
}

String _dateLabel(DateTime? timestamp) {
  if (timestamp == null) {
    return 'No date';
  }
  final local = timestamp.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
