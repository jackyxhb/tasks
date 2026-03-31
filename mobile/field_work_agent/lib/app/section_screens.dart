import 'package:flutter/material.dart';

import '../domain/entities/meeting_entity.dart';
import '../domain/entities/raw_capture_entity.dart';
import '../domain/entities/task_entity.dart';
import '../features/capture/presentation/inbox_screen.dart';
import '../features/capture/presentation/text_capture_input_dialog.dart';
import '../features/exchange/presentation/exchange_screens.dart';
import '../features/meetings/presentation/meetings_screen.dart';
import '../domain/enums/meeting_review_state.dart';
import '../domain/enums/raw_capture_parse_status.dart';
import '../features/projects/presentation/projects_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import 'app_sections.dart';
import 'app_shell_controller.dart';
import 'section_primitives.dart';

class SectionBody extends StatelessWidget {
  const SectionBody({
    super.key,
    required this.section,
    required this.data,
    this.controller = const StaticAppShellController(AppShellData.empty()),
    this.onDataChanged,
    this.onNavigate,
  });

  final AppSection section;
  final AppShellData data;
  final AppShellController controller;
  final ValueChanged<AppShellData>? onDataChanged;
  final ValueChanged<AppSection>? onNavigate;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case AppSection.home:
        return HomeDashboard(
          data: data,
          controller: controller,
          onDataChanged: onDataChanged,
          onNavigate: onNavigate,
        );
      case AppSection.inbox:
        return InboxScreen(
          data: data,
          controller: controller,
          onDataChanged: onDataChanged,
        );
      case AppSection.projects:
        return ProjectsScreen(
          data: data,
          controller: controller,
          onDataChanged: onDataChanged,
        );
      case AppSection.tasks:
        return TasksScreen(
          data: data,
          controller: controller,
          onDataChanged: onDataChanged,
        );
      case AppSection.meetings:
        return MeetingsScreen(
          data: data,
          controller: controller,
          onDataChanged: onDataChanged,
        );
      case AppSection.search:
        return SearchScreen(controller: controller);
      case AppSection.reports:
        return ReportsScreen(
          data: data,
          controller: controller,
          onDataChanged: onDataChanged,
        );
      case AppSection.importSection:
        return ImportScreen(
          data: data,
          controller: controller,
          onDataChanged: onDataChanged,
        );
      case AppSection.exportSection:
        return ExportScreen(
          data: data,
          controller: controller,
          onDataChanged: onDataChanged,
        );
      case AppSection.settings:
        return const SettingsScreen();
      case AppSection.archive:
        return ArchiveScreen(data: data);
    }
  }
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({
    super.key,
    required this.data,
    required this.controller,
    this.onDataChanged,
    this.onNavigate,
  });

  final AppShellData data;
  final AppShellController controller;
  final ValueChanged<AppShellData>? onDataChanged;
  final ValueChanged<AppSection>? onNavigate;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  bool _busy = false;

  Future<void> _showTextCaptureDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => const TextCaptureInputDialog(),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _busy = true);
      try {
        final updated = await widget.controller.createRawTextCapture(
          textContent: result,
        );
        widget.onDataChanged?.call(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Text captured and added to Inbox.')),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayTasks = _todayTasks(widget.data);
    final recentMeetings = _recentMeetings(widget.data);
    final exchangeFeed = _recentExchangeFeed(widget.data);

    return FeatureSectionScaffold(
      title: 'Daily operations at a glance',
      summary:
          'Prioritize pending review first, then move into today\'s work, recent meetings, and bundle exchange history.',
      accent: AppSection.home.accent,
      actions: <ActionData>[
        ActionData(
          label: 'Paste Text',
          icon: Icons.content_paste_go_rounded,
          onPressed: _busy ? null : () => _showTextCaptureDialog(context),
        ),
        ActionData(
          label: 'Record Meeting',
          icon: Icons.mic_rounded,
          onPressed: widget.onNavigate == null
              ? null
              : () => widget.onNavigate!(AppSection.meetings),
        ),
        ActionData(
          label: 'New Task',
          icon: Icons.task_alt_rounded,
          onPressed: widget.onNavigate == null
              ? null
              : () => widget.onNavigate!(AppSection.tasks),
        ),
        ActionData(
          label: 'New Project',
          icon: Icons.apartment_rounded,
          onPressed: widget.onNavigate == null
              ? null
              : () => widget.onNavigate!(AppSection.projects),
        ),
        ActionData(
          label: 'Import Bundle',
          icon: Icons.download_rounded,
          onPressed: widget.onNavigate == null
              ? null
              : () => widget.onNavigate!(AppSection.importSection),
        ),
        ActionData(
          label: 'Search',
          icon: Icons.manage_search_rounded,
          onPressed: widget.onNavigate == null
              ? null
              : () => widget.onNavigate!(AppSection.search),
        ),
      ],
      metrics: <MetricData>[
        MetricData(
            title: 'Inbox Pending',
            value: '${_pendingCaptures(widget.data).length}',
            detail:
                'Low-confidence items and duplicate warnings surfaced first.',
            color: const Color(0xFFC06B37)),
        MetricData(
            title: 'Today Tasks',
            value: '${todayTasks.length}',
            detail: 'Planned and in-progress field work for the current day.',
            color: const Color(0xFF2F6B63)),
        MetricData(
            title: 'Recent Meetings',
            value: '${recentMeetings.length}',
            detail: 'Draft, review-required, and finalized meeting records.',
            color: const Color(0xFF4D5F8C)),
        MetricData(
            title: 'Exports / Imports',
            value:
                '${widget.data.importRuns.length + widget.data.exportRuns.length}',
            detail: 'Recent bundle exchange and report generation activity.',
            color: const Color(0xFF6D4B73)),
      ],
      sections: <Widget>[
        ResponsiveGrid(
          children: <Widget>[
            DetailCard(
              title: 'Upcoming Tasks',
              subtitle: 'Today and next up',
              children: _buildTaskRows(todayTasks),
            ),
            DetailCard(
              title: 'Recent Meetings',
              subtitle: 'Review-first follow-up',
              children: _buildMeetingRows(recentMeetings),
            ),
            DetailCard(
              title: 'Exchange + Reports',
              subtitle: 'Portable local output',
              children: _buildExchangeRows(exchangeFeed),
            ),
          ],
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureSectionScaffold(
      title: 'Local App Settings',
      summary:
          'Configure local preferences, AI provider behavior, diagnostics, and storage reminders without introducing remote state assumptions.',
      accent: AppSection.settings.accent,
      actions: const <ActionData>[
        ActionData(label: 'Diagnostics', icon: Icons.health_and_safety_rounded),
        ActionData(label: 'Backup Reminder', icon: Icons.backup_rounded),
        ActionData(label: 'AI Provider', icon: Icons.tune_rounded),
      ],
      metrics: const <MetricData>[
        MetricData(
            title: 'Operator',
            value: '1',
            detail: 'One agentee per local install.',
            color: Color(0xFF556270)),
        MetricData(
            title: 'External Calls',
            value: 'Optional',
            detail: 'Only for explicit LLM or STT features.',
            color: Color(0xFF3E7B7D)),
      ],
      sections: const <Widget>[
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                SettingRow(
                    title: 'AI extraction enabled',
                    subtitle:
                        'Only on explicit request for meeting or capture review.',
                    value: true),
                SettingRow(
                    title: 'Save raw sources before parse',
                    subtitle:
                        'Always preserve original text and audio locally.',
                    value: true),
                SettingRow(
                    title: 'Bundle checksum verification',
                    subtitle:
                        'Validate import and export manifests before final apply.',
                    value: true),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key, required this.data});

  final AppShellData data;

  @override
  Widget build(BuildContext context) {
    return FeatureSectionScaffold(
      title: 'Archive Browser',
      summary:
          'Soft-archived records stay searchable and reopenable instead of being removed from the local history.',
      accent: AppSection.archive.accent,
      actions: const <ActionData>[
        ActionData(label: 'Reopen', icon: Icons.unarchive_rounded),
        ActionData(label: 'Search Archive', icon: Icons.search_rounded),
      ],
      metrics: <MetricData>[
        MetricData(
            title: 'Archived Projects',
            value:
                '${data.projects.where((project) => project.archivedAt != null).length}',
            detail: 'Closed or completed project records.',
            color: const Color(0xFF7A6B5A)),
        MetricData(
            title: 'Archived Tasks',
            value:
                '${data.tasks.where((task) => task.archivedAt != null).length}',
            detail: 'Historical work kept for traceability.',
            color: const Color(0xFF556270)),
      ],
      sections: <Widget>[
        DetailCard(
          title: 'Archived Records',
          subtitle: 'Still discoverable locally',
          children: _buildArchiveQueue(data),
        ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF214E45),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FilterStrip extends StatelessWidget {
  const FilterStrip({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: labels
          .map(
            (label) => Chip(
              label: Text(label),
              backgroundColor: Colors.white,
              side: BorderSide.none,
            ),
          )
          .toList(growable: false),
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.value});

  final String title;
  final String subtitle;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
        ),
        trailing: IgnorePointer(
          child: Switch(value: value, onChanged: (_) {}),
        ),
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const spacing = 16.0;
        final columns = constraints.maxWidth >= 1280
            ? 3
            : constraints.maxWidth >= 760
                ? 2
                : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

List<TaskEntity> _todayTasks(AppShellData data) {
  final now = DateTime.now();
  return data.tasks
      .where((task) =>
          task.archivedAt == null &&
          task.scheduledDate != null &&
          DateUtils.isSameDay(task.scheduledDate!.toLocal(), now))
      .toList(growable: false);
}

List<MeetingEntity> _recentMeetings(AppShellData data) {
  return data.meetings
      .where((meeting) => meeting.archivedAt == null)
      .take(3)
      .toList(growable: false);
}

List<RawCaptureEntity> _pendingCaptures(AppShellData data) {
  return data.rawCaptures
      .where((capture) => capture.parseStatus != RawCaptureParseStatus.reviewed)
      .take(5)
      .toList(growable: false);
}

List<Widget> _buildTaskRows(List<TaskEntity> tasks) {
  if (tasks.isEmpty) {
    return const <Widget>[
      InfoRow(
          label: 'No tasks',
          value: 'No local tasks are scheduled for today yet.')
    ];
  }
  return tasks.take(3).map((task) {
    final label = task.startTimeLocal ?? _dateLabel(task.scheduledDate);
    final title = task.taskTitle?.trim().isNotEmpty == true
        ? task.taskTitle!
        : task.taskType.name;
    final detail = _joinParts(
        <String?>[task.locationSnapshot, task.workerName, task.status.name]);
    return InfoRow(
        label: label, value: '$title${detail.isEmpty ? '' : ' • $detail'}');
  }).toList(growable: false);
}

List<Widget> _buildMeetingRows(List meetings) {
  if (meetings.isEmpty) {
    return const <Widget>[
      InfoRow(
          label: 'No meetings',
          value: 'No meeting records have been captured locally yet.')
    ];
  }
  return meetings.take(3).map<Widget>((meeting) {
    final title = meeting.title?.trim().isNotEmpty == true
        ? meeting.title!
        : 'Untitled meeting';
    final label = _meetingStatusLabel(meeting.reviewState);
    final detail =
        '${meeting.projectIds.length} linked projects • ${meeting.taskCandidates.length} task candidates';
    return InfoRow(label: label, value: '$title • $detail');
  }).toList(growable: false);
}

List<Widget> _buildExchangeRows(List<String> feed) {
  if (feed.isEmpty) {
    return const <Widget>[
      InfoRow(
          label: 'No exchange',
          value: 'No import, export, or report history is available yet.')
    ];
  }
  return feed
      .take(3)
      .map((line) => InfoRow(
          label: line.split(':').first,
          value: line.split(': ').skip(1).join(': ')))
      .toList(growable: false);
}

List<String> _recentExchangeFeed(AppShellData data) {
  final lines = <String>[];
  for (final exportRun in data.exportRuns.take(2)) {
    lines.add('Export: ${exportRun.bundleName}');
  }
  for (final importRun in data.importRuns.take(1)) {
    lines.add('Import: ${importRun.bundleName}');
  }
  for (final reportRun in data.reportRuns.take(1)) {
    lines.add('Report: ${reportRun.reportType} as ${reportRun.outputFormat}');
  }
  return lines;
}

List<Widget> _buildArchiveQueue(AppShellData data) {
  final items = <Widget>[];
  for (final project
      in data.projects.where((project) => project.archivedAt != null).take(1)) {
    items.add(QueueItem(
        title: project.projectName,
        caption: 'Project archived ${_dateLabel(project.archivedAt)}',
        status: 'Project'));
  }
  for (final task
      in data.tasks.where((task) => task.archivedAt != null).take(1)) {
    final title = task.taskTitle?.trim().isNotEmpty == true
        ? task.taskTitle!
        : task.taskType.name;
    items.add(QueueItem(
        title: title,
        caption: 'Task archived ${_dateLabel(task.archivedAt)}',
        status: 'Task'));
  }
  for (final meeting
      in data.meetings.where((meeting) => meeting.archivedAt != null).take(1)) {
    items.add(QueueItem(
        title: meeting.title ?? 'Untitled meeting',
        caption: 'Meeting archived ${_dateLabel(meeting.archivedAt)}',
        status: 'Meeting'));
  }
  if (items.isEmpty) {
    return const <Widget>[
      QueueItem(
          title: 'Archive is empty',
          caption:
              'Soft-archived records will remain searchable here once archived.',
          status: 'Empty')
    ];
  }
  return items;
}

String _dateLabel(DateTime? value) {
  if (value == null) {
    return 'No date';
  }
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String _joinParts(List<String?> parts) {
  return parts
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .join(' • ');
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
