import 'package:flutter/material.dart';

import '../../../app/app_runtime.dart';
import '../../../app/app_sections.dart';
import '../../../app/section_primitives.dart';
import '../../../domain/entities/report_run_entity.dart';
import '../application/report_models.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.data,
    required this.controller,
    this.onDataChanged,
  });

  final AppShellData data;
  final AppShellController controller;
  final ValueChanged<AppShellData>? onDataChanged;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReportType = 'daily';
  ReportOutputFormat _outputFormat = ReportOutputFormat.inApp;
  late final TextEditingController _dateController;
  late final TextEditingController _projectController;
  GeneratedReport? _report;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: DateTime.now().toUtc().toIso8601String().split('T').first,
    );
    _projectController = TextEditingController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureSectionScaffold(
      title: 'Report Templates',
      summary:
          'Generate deterministic local reports with editable filters before emitting in-app, CSV, or JSON outputs.',
      accent: AppSection.reports.accent,
      actions: const <ActionData>[
        ActionData(label: 'Daily Task List', icon: Icons.today_rounded),
        ActionData(
          label: 'Meeting Minutes Pack',
          icon: Icons.library_books_rounded,
        ),
        ActionData(
          label: 'Project Summary',
          icon: Icons.summarize_rounded,
        ),
      ],
      metrics: <MetricData>[
        const MetricData(
          title: 'Templates',
          value: '3',
          detail: 'Daily task list, project summary, meeting minutes pack.',
          color: Color(0xFF6D4B73),
        ),
        MetricData(
          title: 'Runs Logged',
          value: '${widget.data.reportRuns.length}',
          detail: 'Tracked local report generation history.',
          color: const Color(0xFF3E7B7D),
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
                  initialValue: _selectedReportType,
                  decoration: const InputDecoration(labelText: 'Report Type'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'daily',
                      child: Text('Daily Task List'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'project',
                      child: Text('Project Summary'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'minutes',
                      child: Text('Meeting Minutes Pack'),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedReportType = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReportOutputFormat>(
                  initialValue: _outputFormat,
                  decoration: const InputDecoration(labelText: 'Output Format'),
                  items: ReportOutputFormat.values
                      .map(
                        (format) => DropdownMenuItem<ReportOutputFormat>(
                          value: format,
                          child: Text(format.storageValue),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (ReportOutputFormat? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _outputFormat = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _projectController,
                  decoration: const InputDecoration(
                    labelText: 'Project Id For Project/Minutes Reports',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _generateReport,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Generate Report'),
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
        if (_report != null)
          DetailCard(
            title: 'Last Generated Report',
            subtitle: _report!.reportType,
            children: <Widget>[
              InfoRow(label: 'Summary', value: _report!.summary),
              if (_report!.outputPath != null)
                InfoRow(label: 'Output Path', value: _report!.outputPath!),
            ],
          ),
        DetailCard(
          title: 'Recent Runs',
          subtitle: 'Local history',
          children: _buildReportQueue(widget.data),
        ),
      ],
    );
  }

  Future<void> _generateReport() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final GeneratedReport report;
      if (_selectedReportType == 'project') {
        if (_projectController.text.trim().isEmpty) {
          throw StateError(
            'Project id is required for project summary reports.',
          );
        }
        report = await widget.controller.generateProjectSummaryReport(
          projectId: _projectController.text.trim(),
          outputFormat: _outputFormat,
        );
      } else if (_selectedReportType == 'minutes') {
        report = await widget.controller.generateMeetingMinutesPackReport(
          filter: ReportFilter(
            projectId: _projectController.text.trim().isEmpty
                ? null
                : _projectController.text.trim(),
          ),
          outputFormat: _outputFormat,
        );
      } else {
        final parsedDate = DateTime.tryParse(_dateController.text.trim());
        if (parsedDate == null) {
          throw StateError('A valid date is required for daily task reports.');
        }
        report = await widget.controller.generateDailyTaskListReport(
          date: parsedDate,
          outputFormat: _outputFormat,
        );
      }
      final updatedData = await widget.controller.load();
      widget.onDataChanged?.call(updatedData);
      if (!mounted) {
        return;
      }
      setState(() {
        _report = report;
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

List<Widget> _buildReportQueue(AppShellData data) {
  if (data.reportRuns.isEmpty) {
    return const <Widget>[
      QueueItem(
        title: 'No report runs yet',
        caption:
            'Generated report history will appear here after local output is created.',
        status: 'Empty',
      ),
    ];
  }
  return data.reportRuns.take(3).map((ReportRunEntity run) {
    return QueueItem(
      title: run.reportType,
      caption:
          'Format: ${run.outputFormat} • Created ${_dateLabel(run.createdAt)}',
      status: run.outputFormat.toUpperCase(),
    );
  }).toList(growable: false);
}

String _dateLabel(DateTime timestamp) {
  final local = timestamp.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
