import 'package:flutter/material.dart';

import '../../../app/app_runtime.dart';
import '../../../app/app_sections.dart';
import '../../../app/section_primitives.dart';
import '../../../domain/entities/project_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/enums/task_priority.dart';
import '../../../domain/enums/task_status.dart';
import '../../../domain/enums/task_type.dart';
import '../application/task_models.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    required this.data,
    required this.controller,
    this.onDataChanged,
  });

  final AppShellData data;
  final AppShellController controller;
  final ValueChanged<AppShellData>? onDataChanged;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final todayTasks = _todayTasks(widget.data);
    final provisionalTasks = widget.data.tasks
        .where((task) => task.isProvisional && task.archivedAt == null)
        .toList(growable: false);

    return FeatureSectionScaffold(
      title: 'Task Board',
      summary:
          'Browse today, upcoming, all, and provisional tasks with source traceability and fast status changes.',
      accent: AppSection.tasks.accent,
      actions: const <ActionData>[
        ActionData(label: 'New Task', icon: Icons.add_task_rounded),
        ActionData(label: 'Today', icon: Icons.today_rounded),
        ActionData(label: 'Provisional', icon: Icons.pending_actions_rounded),
      ],
      metrics: <MetricData>[
        MetricData(
          title: 'Today',
          value: '${todayTasks.length}',
          detail: 'Immediate scheduled work.',
          color: const Color(0xFF2F6B63),
        ),
        MetricData(
          title: 'Upcoming',
          value: '${_upcomingTasks(widget.data).length}',
          detail: 'Later scheduled tasks with assigned owners.',
          color: const Color(0xFF4D5F8C),
        ),
        MetricData(
          title: 'Provisional',
          value:
              '${widget.data.tasks.where((task) => task.isProvisional && task.archivedAt == null).length}',
          detail: 'Records still waiting on correction or confirmation.',
          color: const Color(0xFFC06B37),
        ),
      ],
      sections: <Widget>[
        DetailCard(
          title: 'Task Actions',
          subtitle: 'Create or adjust a local task record',
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _busy ? null : () => _openTaskEditor(),
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('New Task'),
                ),
              ],
            ),
          ],
        ),
        const FilterStrip(labels: <String>[
          'Project',
          'Worker',
          'Task Type',
          'Status',
          'Coordinator',
          'Source Channel'
        ]),
        ResponsiveGrid(
          children: <Widget>[
            DetailCard(
              title: 'Today',
              subtitle: 'Scheduled field work',
              children: _buildInteractiveTaskQueue(todayTasks),
            ),
            DetailCard(
              title: 'Provisional Tasks',
              subtitle: 'Captured but not finalized',
              children: _buildInteractiveTaskQueue(
                provisionalTasks,
                provisional: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildInteractiveTaskQueue(
    List<TaskEntity> tasks, {
    bool provisional = false,
  }) {
    if (tasks.isEmpty) {
      return <Widget>[
        QueueItem(
          title: provisional ? 'No provisional tasks' : 'No tasks in this bucket',
          caption: provisional
              ? 'Nothing is waiting on final confirmation right now.'
              : 'Local task data will appear here when scheduled.',
          status: 'Empty',
        ),
      ];
    }

    return tasks.take(5).map((task) {
      final title = task.taskTitle?.trim().isNotEmpty == true
          ? task.taskTitle!
          : task.taskType.name;
      final project = widget.data.projectById(task.projectId);
      final caption = _joinParts(<String?>[
        project?.projectName ?? 'Unlinked project',
        task.workerName,
        _taskStatusLabel(task.status),
        _dateLabel(task.scheduledDate),
      ]);
      return QueueItem(
        title: title,
        caption: caption,
        status: provisional
            ? (task.needsReview ? 'Review' : 'Provisional')
            : _taskStatusLabel(task.status),
        actions: <Widget>[
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _openTaskEditor(task: task),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit'),
          ),
          TextButton.icon(
            onPressed: _busy ? null : () => _archiveTask(task.id),
            icon: const Icon(Icons.archive_rounded),
            label: const Text('Archive'),
          ),
        ],
      );
    }).toList(growable: false);
  }

  Future<void> _openTaskEditor({TaskEntity? task}) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _TaskEditorDialog(
          data: widget.data,
          task: task,
          onSubmit: (TaskDraft draft) async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () => task == null
                  ? widget.controller.createTask(draft: draft)
                  : widget.controller.updateTask(taskId: task.id, draft: draft),
              successMessage: task == null ? 'Task created.' : 'Task updated.',
            );
          },
        );
      },
    );
  }

  Future<void> _archiveTask(String taskId) async {
    await _runControllerAction(
      () => widget.controller.archiveTask(taskId: taskId),
      successMessage: 'Task archived.',
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

class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog({
    required this.data,
    required this.onSubmit,
    this.task,
  });

  final AppShellData data;
  final TaskEntity? task;
  final ValueChanged<TaskDraft> onSubmit;

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  late String? _projectId;
  late TaskType _taskType;
  late TaskStatus _status;
  late TaskPriority _priority;
  late bool _isProvisional;
  late bool _needsReview;

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _durationController;
  late final TextEditingController _locationController;
  late final TextEditingController _workerController;
  late final TextEditingController _workerPhoneController;
  late final TextEditingController _coordinatorController;
  late final TextEditingController _projectManagerController;
  late final TextEditingController _agenteeController;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _projectId = task?.projectId;
    _taskType = task?.taskType ?? TaskType.unknown;
    _status = task?.status ?? TaskStatus.planned;
    _priority = task?.priority ?? TaskPriority.medium;
    _isProvisional = task?.isProvisional ?? false;
    _needsReview = task?.needsReview ?? false;
    _titleController = TextEditingController(text: task?.taskTitle ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _dateController = TextEditingController(text: _dateInputLabel(task?.scheduledDate));
    _timeController = TextEditingController(text: task?.startTimeLocal ?? '');
    _durationController = TextEditingController(
      text: task?.durationMinutes == null ? '' : '${task!.durationMinutes}',
    );
    _locationController = TextEditingController(text: task?.locationSnapshot ?? '');
    _workerController = TextEditingController(text: task?.workerName ?? '');
    _workerPhoneController = TextEditingController(text: task?.workerPhone ?? '');
    _coordinatorController = TextEditingController(text: task?.coordinatorName ?? '');
    _projectManagerController = TextEditingController(text: task?.projectManagerName ?? '');
    _agenteeController = TextEditingController(
      text: task?.agenteeName ?? _defaultAgenteeName(widget.data),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
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
      title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String?>(
                initialValue: _projectId,
                decoration: const InputDecoration(labelText: 'Project'),
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
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _taskType = value;
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
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Scheduled Date',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timeController,
                decoration:
                    const InputDecoration(labelText: 'Start Time Local'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Duration Minutes'),
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
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: TaskStatus.values
                    .map(
                      (status) => DropdownMenuItem<TaskStatus>(
                        value: status,
                        child: Text(_taskStatusLabel(status)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (TaskStatus? value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _status = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _priority,
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
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _priority = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Provisional'),
                value: _isProvisional,
                onChanged: (bool value) {
                  setState(() {
                    _isProvisional = value;
                  });
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Needs Review'),
                value: _needsReview,
                onChanged: (bool value) {
                  setState(() {
                    _needsReview = value;
                  });
                },
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
          onPressed: _submit,
          child: Text(widget.task == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  void _submit() {
    final agenteeName = _agenteeController.text.trim();
    if (agenteeName.isEmpty) {
      return;
    }
    ProjectEntity? linkedProject;
    if (_projectId != null) {
      for (final project in widget.data.projects) {
        if (project.id == _projectId) {
          linkedProject = project;
          break;
        }
      }
    }
    widget.onSubmit(
      TaskDraft(
        projectId: _projectId,
        projectName: linkedProject?.projectName,
        taskType: _taskType,
        taskTitle: _textOrNull(_titleController.text),
        description: _textOrNull(_descriptionController.text),
        scheduledDate: _parseDateText(_dateController.text),
        startTimeLocal: _textOrNull(_timeController.text),
        durationMinutes: _parseIntText(_durationController.text),
        locationSnapshot: _textOrNull(_locationController.text),
        workerName: _textOrNull(_workerController.text),
        workerPhone: _textOrNull(_workerPhoneController.text),
        coordinatorName: _textOrNull(_coordinatorController.text),
        projectManagerName: _textOrNull(_projectManagerController.text),
        agenteeName: agenteeName,
        status: _status,
        priority: _priority,
        isProvisional: _isProvisional,
        needsReview: _needsReview,
        sourceCaptureId: widget.task?.sourceCaptureId,
      ),
    );
  }
}

List<TaskEntity> _todayTasks(AppShellData data) {
  final now = DateTime.now();
  return data.tasks
      .where((task) => task.archivedAt == null)
      .where((task) => task.scheduledDate != null)
      .where((task) {
        final local = task.scheduledDate!.toLocal();
        return local.year == now.year &&
            local.month == now.month &&
            local.day == now.day;
      })
      .toList(growable: false);
}

List<TaskEntity> _upcomingTasks(AppShellData data) {
  final now = DateTime.now();
  return data.tasks
      .where((task) => task.archivedAt == null)
      .where((task) => task.scheduledDate != null)
      .where(
        (task) => task.scheduledDate!
            .toLocal()
            .isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59)),
      )
      .toList(growable: false);
}

String _dateLabel(DateTime? value) {
  if (value == null) {
    return 'No date';
  }
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _dateInputLabel(DateTime? value) {
  return value == null ? '' : _dateLabel(value);
}

String? _textOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _parseDateText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return DateTime.tryParse(trimmed);
}

int? _parseIntText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return int.tryParse(trimmed);
}

String _joinParts(List<String?> parts) {
  return parts
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .join(' • ');
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
