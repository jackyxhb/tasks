import 'package:flutter/material.dart';

import '../../../app/app_runtime.dart';
import '../../../app/app_sections.dart';
import '../../../app/section_primitives.dart';
import '../../../domain/entities/export_run_entity.dart';
import '../../../domain/entities/import_export_bundle_entity.dart';
import '../../../domain/entities/import_run_entity.dart';
import '../application/exchange_models.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({
    super.key,
    required this.data,
    required this.controller,
    this.onDataChanged,
  });

  final AppShellData data;
  final AppShellController controller;
  final ValueChanged<AppShellData>? onDataChanged;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late final TextEditingController _pathController;
  ImportPreviewResult? _preview;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: 'imports/sample-bundle.json');
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureSectionScaffold(
      title: 'Import Preview',
      summary:
          'Nothing is written before bundle parsing, duplicate review, and explicit confirmation.',
      accent: AppSection.importSection.accent,
      actions: const <ActionData>[
        ActionData(label: 'Pick Bundle', icon: Icons.folder_open_rounded),
        ActionData(label: 'Preview Manifest', icon: Icons.preview_rounded),
        ActionData(
          label: 'Apply Import',
          icon: Icons.playlist_add_check_circle_rounded,
        ),
      ],
      metrics: <MetricData>[
        MetricData(
          title: 'Imports',
          value: '${widget.data.importRuns.length}',
          detail: 'Recent local bundle previews and applies.',
          color: const Color(0xFF3E7B7D),
        ),
        MetricData(
          title: 'Duplicates',
          value: '${_preview?.duplicateIds.length ?? 0}',
          detail: 'Likely overlaps that need merge or create decisions.',
          color: const Color(0xFFC06B37),
        ),
      ],
      sections: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    labelText: 'Relative Import Path',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _busy ? null : _previewBundle,
                      icon: const Icon(Icons.preview_rounded),
                      label: const Text('Preview Import'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy || _preview == null ? null : _applyBundle,
                      icon: const Icon(Icons.playlist_add_check_circle_rounded),
                      label: const Text('Apply Import'),
                    ),
                  ],
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_preview != null)
          DetailCard(
            title: 'Preview Summary',
            subtitle: _preview!.bundle.bundleId,
            children: <Widget>[
              InfoRow(label: 'Projects', value: '${_preview!.projectCount}'),
              InfoRow(label: 'Tasks', value: '${_preview!.taskCount}'),
              InfoRow(label: 'Meetings', value: '${_preview!.meetingCount}'),
              InfoRow(label: 'People', value: '${_preview!.peopleCount}'),
              InfoRow(
                label: 'Duplicates',
                value: _preview!.duplicateIds.isEmpty
                    ? 'None'
                    : _preview!.duplicateIds.join(', '),
              ),
            ],
          ),
        DetailCard(
          title: 'Duplicate Candidates',
          subtitle: 'Review queue',
          children: _buildImportQueue(widget.data),
        ),
      ],
    );
  }

  Future<void> _previewBundle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await widget.controller.previewImportBundle(
        relativeImportPath: _pathController.text.trim(),
      );
      final updatedData = await widget.controller.load();
      widget.onDataChanged?.call(updatedData);
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = preview;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _applyBundle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updatedData = await widget.controller.applyImportBundle(
        relativeImportPath: _pathController.text.trim(),
      );
      widget.onDataChanged?.call(updatedData);
      if (!mounted) {
        return;
      }
      setState(() {
        _preview = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }
}

class ExportScreen extends StatefulWidget {
  const ExportScreen({
    super.key,
    required this.data,
    required this.controller,
    this.onDataChanged,
  });

  final AppShellData data;
  final AppShellController controller;
  final ValueChanged<AppShellData>? onDataChanged;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _scopeType = 'all';
  late final TextEditingController _scopeValueController;
  ImportExportBundleEntity? _bundle;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _scopeValueController = TextEditingController();
  }

  @override
  void dispose() {
    _scopeValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureSectionScaffold(
      title: 'Export Builder',
      summary:
          'Package selected local records into a canonical bundle with attachment manifest and optional secondary outputs.',
      accent: AppSection.exportSection.accent,
      actions: const <ActionData>[
        ActionData(label: 'Choose Scope', icon: Icons.select_all_rounded),
        ActionData(label: 'Manifest', icon: Icons.inventory_2_rounded),
        ActionData(label: 'Generate Bundle', icon: Icons.inventory_rounded),
      ],
      metrics: <MetricData>[
        MetricData(
          title: 'Recent Exports',
          value: '${widget.data.exportRuns.length}',
          detail: 'Current export history from the local package.',
          color: const Color(0xFF9C6B3C),
        ),
        MetricData(
          title: 'Bundle Records',
          value: _bundle == null
              ? '0'
              : '${_bundle!.projects.length + _bundle!.tasks.length + _bundle!.meetings.length + _bundle!.people.length}',
          detail: 'Current generated bundle record count.',
          color: const Color(0xFF4D5F8C),
        ),
      ],
      sections: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _scopeType,
                  decoration: const InputDecoration(labelText: 'Export Scope Type'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'all',
                      child: Text('All Local Records'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'project',
                      child: Text('Project Id Or Name'),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _scopeType = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _scopeValueController,
                  decoration: const InputDecoration(
                    labelText: 'Scope Value',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _createBundle,
                  icon: const Icon(Icons.inventory_rounded),
                  label: const Text('Generate Bundle'),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_bundle != null)
          DetailCard(
            title: 'Generated Bundle',
            subtitle: _bundle!.bundleId,
            children: <Widget>[
              InfoRow(label: 'Projects', value: '${_bundle!.projects.length}'),
              InfoRow(label: 'Tasks', value: '${_bundle!.tasks.length}'),
              InfoRow(label: 'Meetings', value: '${_bundle!.meetings.length}'),
              InfoRow(label: 'People', value: '${_bundle!.people.length}'),
              InfoRow(
                label: 'Attachments',
                value: '${_bundle!.attachmentsManifest.length}',
              ),
            ],
          ),
        DetailCard(
          title: 'Recent Exports',
          subtitle: 'Local bundle history',
          children: _buildExportQueue(widget.data),
        ),
      ],
    );
  }

  Future<void> _createBundle() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bundle = await widget.controller.createExportBundle(
        scope: ExportScopeRequest(
          type: _scopeType,
          value: _scopeValueController.text.trim().isEmpty
              ? null
              : _scopeValueController.text.trim(),
        ),
      );
      final updatedData = await widget.controller.load();
      widget.onDataChanged?.call(updatedData);
      if (!mounted) {
        return;
      }
      setState(() {
        _bundle = bundle;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }
}

List<Widget> _buildImportQueue(AppShellData data) {
  if (data.importRuns.isEmpty) {
    return const <Widget>[
      QueueItem(
        title: 'No import previews yet',
        caption:
            'Preview and apply activity will appear here after the first bundle review.',
        status: 'Empty',
      ),
    ];
  }
  return data.importRuns.take(3).map((ImportRunEntity run) {
    return QueueItem(
      title: run.bundleName,
      caption: 'Status: ${run.status} • Imported ${_dateLabel(run.importTime)}',
      status: run.status,
    );
  }).toList(growable: false);
}

List<Widget> _buildExportQueue(AppShellData data) {
  if (data.exportRuns.isEmpty) {
    return const <Widget>[
      QueueItem(
        title: 'No exports yet',
        caption:
            'Generated bundle history will appear here after the first export.',
        status: 'Empty',
      ),
    ];
  }
  return data.exportRuns.take(3).map((ExportRunEntity run) {
    return QueueItem(
      title: run.bundleName,
      caption: 'Scope: ${run.exportScopeType} • Created ${_dateLabel(run.createdAt)}',
      status: run.exportScopeType,
    );
  }).toList(growable: false);
}

String _dateLabel(DateTime timestamp) {
  final local = timestamp.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
