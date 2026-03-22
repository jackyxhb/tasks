import 'package:flutter/material.dart';

import '../../../app/app_runtime.dart';
import '../../../app/app_sections.dart';
import '../../../app/section_primitives.dart';
import '../../../app/ui_components.dart';
import '../../../domain/entities/project_entity.dart';
import '../../../domain/enums/task_status.dart';
import '../application/project_draft.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({
    super.key,
    required this.data,
    required this.controller,
    this.onDataChanged,
  });

  final AppShellData data;
  final AppShellController controller;
  final ValueChanged<AppShellData>? onDataChanged;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final activeProjects = widget.data.projects
        .where((project) => project.archivedAt == null)
        .toList(growable: false);

    return FeatureSectionScaffold(
      title: 'Projects At A Glance',
      summary:
          'Browse active and archived projects with OEM, coordinator, project manager, and open-task context close to the surface.',
      accent: AppSection.projects.accent,
      actions: const <ActionData>[
        ActionData(label: 'Add Project', icon: Icons.add_business_rounded),
        ActionData(label: 'Filter OEM', icon: Icons.filter_alt_rounded),
        ActionData(label: 'Recent Activity', icon: Icons.history_rounded),
      ],
      metrics: <MetricData>[
        MetricData(
          title: 'Active Projects',
          value:
              '${widget.data.projects.where((project) => project.archivedAt == null).length}',
          detail: 'Local projects with current field work or follow-up.',
          color: const Color(0xFF4D5F8C),
        ),
        MetricData(
          title: 'Open Tasks',
          value: '${_openTasks(widget.data).length}',
          detail: 'Tasks linked across active project records.',
          color: const Color(0xFF2F6B63),
        ),
        MetricData(
          title: 'Archived',
          value:
              '${widget.data.projects.where((project) => project.archivedAt != null).length}',
          detail: 'Soft-archived projects kept searchable locally.',
          color: const Color(0xFF7A6B5A),
        ),
      ],
      sections: <Widget>[
        DetailCard(
          title: 'Project Actions',
          subtitle: 'Create or adjust a local project record',
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _busy ? null : () => _openProjectEditor(),
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text('Add Project'),
                ),
              ],
            ),
          ],
        ),
        const FilterStrip(labels: <String>[
          'OEM',
          'Coordinator',
          'Project Manager',
          'Open Tasks',
          'Recent Activity',
          'Archived'
        ]),
        ResponsiveGrid(children: _buildInteractiveProjectCards(activeProjects)),
      ],
    );
  }

  List<Widget> _buildInteractiveProjectCards(List<ProjectEntity> projects) {
    if (projects.isEmpty) {
      return const <Widget>[
        DetailCard(
          title: 'No projects yet',
          subtitle:
              'Local project records will appear here once created or imported.',
          children: <Widget>[
            InfoRow(
              label: 'Next step',
              value: 'Create a project or review a raw capture to promote one.',
            ),
          ],
        ),
      ];
    }

    return projects.map((project) {
      final openTaskCount = widget.data.tasks
          .where(
            (task) =>
                task.projectId == project.id &&
                task.archivedAt == null &&
                task.status != TaskStatus.completed &&
                task.status != TaskStatus.cancelled,
          )
          .length;

      return DetailCard(
        title: project.projectName,
        subtitle:
            'OEM: ${project.clientOem ?? 'Unknown'} • Open tasks: $openTaskCount • Last activity: ${_dateLabel(project.updatedAt)}',
        children: <Widget>[
          InfoRow(
            label: 'Location',
            value: project.siteLocation ?? 'No site location recorded',
          ),
          InfoRow(
            label: 'Coordinator',
            value: project.coordinatorName ?? 'Not set',
          ),
          InfoRow(
            label: 'Project manager',
            value: project.projectManagerName ?? 'Not set',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _openProjectEditor(project),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _archiveProject(project.id),
                icon: const Icon(Icons.archive_rounded),
                label: const Text('Archive'),
              ),
            ],
          ),
        ],
      );
    }).toList(growable: false);
  }

  Future<void> _openProjectEditor([ProjectEntity? project]) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ProjectEditorDialog(
          project: project,
          onSubmit: (ProjectDraft draft) async {
            Navigator.of(dialogContext).pop();
            await _runControllerAction(
              () {
                if (project == null) {
                  return widget.controller.createProject(draft: draft);
                }
                return widget.controller.updateProject(
                  projectId: project.id,
                  draft: draft,
                );
              },
              successMessage:
                  project == null ? 'Project created.' : 'Project updated.',
            );
          },
        );
      },
    );
  }

  Future<void> _archiveProject(String projectId) async {
    final confirmed = await ConfirmActionDialog.show(
      context: context,
      title: 'Archive this project?',
      message:
          'The project and its tasks will be moved to archive. You can reopen it later.',
      confirmLabel: 'Archive',
      cancelLabel: 'Cancel',
      isDestructive: true,
      confirmIcon: Icons.archive_rounded,
    );
    if (!confirmed) return;

    await _runControllerAction(
      () => widget.controller.archiveProject(projectId: projectId),
      successMessage: 'Project archived.',
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

class _ProjectEditorDialog extends StatefulWidget {
  const _ProjectEditorDialog({
    required this.project,
    required this.onSubmit,
  });

  final ProjectEntity? project;
  final Future<void> Function(ProjectDraft draft) onSubmit;

  @override
  State<_ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<_ProjectEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _clientOemController;
  late final TextEditingController _siteLocationController;
  late final TextEditingController _siteContactNameController;
  late final TextEditingController _siteContactPhoneController;
  late final TextEditingController _coordinatorController;
  late final TextEditingController _projectManagerController;
  late final TextEditingController _statusController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    _nameController = TextEditingController(text: project?.projectName ?? '');
    _clientOemController =
        TextEditingController(text: project?.clientOem ?? '');
    _siteLocationController =
        TextEditingController(text: project?.siteLocation ?? '');
    _siteContactNameController =
        TextEditingController(text: project?.siteContactName ?? '');
    _siteContactPhoneController =
        TextEditingController(text: project?.siteContactPhone ?? '');
    _coordinatorController =
        TextEditingController(text: project?.coordinatorName ?? '');
    _projectManagerController =
        TextEditingController(text: project?.projectManagerName ?? '');
    _statusController = TextEditingController(text: project?.status ?? '');
    _notesController = TextEditingController(text: project?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientOemController.dispose();
    _siteLocationController.dispose();
    _siteContactNameController.dispose();
    _siteContactPhoneController.dispose();
    _coordinatorController.dispose();
    _projectManagerController.dispose();
    _statusController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.project == null ? 'Add Project' : 'Edit Project'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _clientOemController,
                decoration: const InputDecoration(labelText: 'Client OEM'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _siteLocationController,
                decoration: const InputDecoration(labelText: 'Site Location'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _siteContactNameController,
                decoration:
                    const InputDecoration(labelText: 'Site Contact Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _siteContactPhoneController,
                decoration:
                    const InputDecoration(labelText: 'Site Contact Phone'),
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
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Notes'),
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
          child: Text(widget.project == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return Future<void>.value();
    }

    return widget.onSubmit(
      ProjectDraft(
        projectName: name,
        clientOem: _textOrNull(_clientOemController.text),
        siteLocation: _textOrNull(_siteLocationController.text),
        siteContactName: _textOrNull(_siteContactNameController.text),
        siteContactPhone: _textOrNull(_siteContactPhoneController.text),
        coordinatorName: _textOrNull(_coordinatorController.text),
        projectManagerName: _textOrNull(_projectManagerController.text),
        status: _textOrNull(_statusController.text),
        notes: _textOrNull(_notesController.text),
      ),
    );
  }
}

List<dynamic> _openTasks(AppShellData data) {
  return data.tasks
      .where(
        (task) =>
            task.archivedAt == null &&
            task.status != TaskStatus.completed &&
            task.status != TaskStatus.cancelled,
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

String? _textOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
