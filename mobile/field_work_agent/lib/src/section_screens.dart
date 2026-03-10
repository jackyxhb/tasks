import 'package:flutter/material.dart';

import '../domain/entities/meeting_task_candidate_entity.dart';
import '../domain/entities/meeting_entity.dart';
import '../domain/entities/raw_capture_entity.dart';
import '../domain/entities/task_entity.dart';
import '../domain/enums/meeting_review_state.dart';
import '../domain/enums/raw_capture_parse_status.dart';
import '../domain/enums/task_status.dart';
import 'app_runtime.dart';
import 'app_sections.dart';

class SectionBody extends StatelessWidget {
  const SectionBody({super.key, required this.section, required this.data});

  final AppSection section;
  final AppShellData data;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case AppSection.home:
        return HomeDashboard(data: data);
      case AppSection.inbox:
        return InboxScreen(data: data);
      case AppSection.projects:
        return ProjectsScreen(data: data);
      case AppSection.tasks:
        return TasksScreen(data: data);
      case AppSection.meetings:
        return MeetingsScreen(data: data);
      case AppSection.search:
        return const SearchScreen();
      case AppSection.reports:
        return ReportsScreen(data: data);
      case AppSection.importSection:
        return ImportScreen(data: data);
      case AppSection.exportSection:
        return ExportScreen(data: data);
      case AppSection.settings:
        return const SettingsScreen();
      case AppSection.archive:
        return ArchiveScreen(data: data);
    }
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key, required this.data});

  final AppShellData data;

  @override
  Widget build(BuildContext context) {
    final todayTasks = _todayTasks(data);
    final recentMeetings = _recentMeetings(data);
    final exchangeFeed = _recentExchangeFeed(data);

    return FeatureSectionScaffold(
      title: 'Daily operations at a glance',
      summary:
          'Prioritize pending review first, then move into today\'s work, recent meetings, and bundle exchange history.',
      accent: AppSection.home.accent,
      actions: const <ActionData>[
        ActionData(label: 'Paste Text', icon: Icons.content_paste_go_rounded),
        ActionData(label: 'Record Meeting', icon: Icons.mic_rounded),
        ActionData(label: 'New Task', icon: Icons.task_alt_rounded),
        ActionData(label: 'New Project', icon: Icons.apartment_rounded),
        ActionData(label: 'Import Bundle', icon: Icons.download_rounded),
        ActionData(label: 'Search', icon: Icons.manage_search_rounded),
      ],
      metrics: <MetricData>[
        MetricData(
            title: 'Inbox Pending',
            value: '${_pendingCaptures(data).length}',
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
            value: '${data.importRuns.length + data.exportRuns.length}',
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

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key, required this.data});

  final AppShellData data;

  @override
  Widget build(BuildContext context) {
    final pendingCaptures = _pendingCaptures(data);

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
            color: const Color(0xFFC06B37)),
        MetricData(
            title: 'Low Confidence',
            value:
                '${pendingCaptures.where((capture) => (capture.classificationConfidence ?? 1) < 0.7).length}',
            detail: 'Items that should stay visible until manually checked.',
            color: const Color(0xFFB34A3C)),
        MetricData(
            title: 'Duplicate Risks',
            value: '${_duplicateRiskCount(data)}',
            detail: 'Likely overlaps with recent projects or task records.',
            color: const Color(0xFF5A5E9A)),
      ],
      sections: <Widget>[
        DetailCard(
          title: 'Unreviewed Captures',
          subtitle: 'Source channel, confidence, and project guess',
          children: _buildCaptureQueue(pendingCaptures),
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
                        'Accept, replace, or leave unresolved without blocking provisional save.'),
                InfoRow(
                    label: 'Confidence',
                    value:
                        'Show field-level uncertainty before finalizing records.'),
                InfoRow(
                    label: 'Duplicates',
                    value: 'Offer merge instead of silent overwrite.'),
              ],
            ),
            DetailCard(
              title: 'Suggested Next Actions',
              subtitle: 'Fast correction loop',
              children: <Widget>[
                InfoRow(
                    label: '1',
                    value:
                        'Review all meeting captures with confidence below 0.70 first.'),
                InfoRow(
                    label: '2',
                    value:
                        'Merge duplicate task requests before creating new records.'),
                InfoRow(
                    label: '3',
                    value:
                        'Save ambiguous items as provisional instead of blocking intake.'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key, required this.data});

  final AppShellData data;

  @override
  Widget build(BuildContext context) {
    final activeProjects = data.projects
        .where((project) => project.archivedAt == null)
        .take(3)
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
                '${data.projects.where((project) => project.archivedAt == null).length}',
            detail: 'Local projects with current field work or follow-up.',
            color: const Color(0xFF4D5F8C)),
        MetricData(
            title: 'Open Tasks',
            value: '${_openTasks(data).length}',
            detail: 'Tasks linked across active project records.',
            color: const Color(0xFF2F6B63)),
        MetricData(
            title: 'Archived',
            value:
                '${data.projects.where((project) => project.archivedAt != null).length}',
            detail: 'Soft-archived projects kept searchable locally.',
            color: const Color(0xFF7A6B5A)),
      ],
      sections: <Widget>[
        const FilterStrip(labels: <String>[
          'OEM',
          'Coordinator',
          'Project Manager',
          'Open Tasks',
          'Recent Activity',
          'Archived'
        ]),
        ResponsiveGrid(children: _buildProjectCards(activeProjects, data)),
      ],
    );
  }
}

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.data});

  final AppShellData data;

  @override
  Widget build(BuildContext context) {
    final todayTasks = _todayTasks(data);
    final provisionalTasks = data.tasks
        .where((task) => task.isProvisional && task.archivedAt == null)
        .take(3)
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
            color: const Color(0xFF2F6B63)),
        MetricData(
            title: 'Upcoming',
            value: '${_upcomingTasks(data).length}',
            detail: 'Later scheduled tasks with assigned owners.',
            color: const Color(0xFF4D5F8C)),
        MetricData(
            title: 'Provisional',
            value:
                '${data.tasks.where((task) => task.isProvisional && task.archivedAt == null).length}',
            detail: 'Records still waiting on correction or confirmation.',
            color: const Color(0xFFC06B37)),
      ],
      sections: <Widget>[
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
                children: _buildTaskQueue(todayTasks)),
            DetailCard(
                title: 'Provisional Tasks',
                subtitle: 'Captured but not finalized',
                children: _buildTaskQueue(provisionalTasks, provisional: true)),
          ],
        ),
      ],
    );
  }
}

class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key, required this.data});

  final AppShellData data;

  @override
  Widget build(BuildContext context) {
    final candidateItems = _meetingCandidates(data);
    final pendingAiMeetings = _pendingAiMeetings(data);
    final manualFallbackMeetings = _manualFallbackMeetings(data);

    return FeatureSectionScaffold(
      title: 'Meeting Review Board',
      summary:
          'Audio-first intake, transcript review, linked projects, and task candidate resolution stay together so meetings do not flatten directly into final tasks.',
      accent: AppSection.meetings.accent,
      actions: const <ActionData>[
        ActionData(label: 'Record Meeting', icon: Icons.mic_rounded),
        ActionData(label: 'Finalize Minutes', icon: Icons.fact_check_rounded),
        ActionData(
            label: 'Export Minutes', icon: Icons.file_download_done_rounded),
      ],
      metrics: <MetricData>[
        MetricData(
            title: 'Draft Meetings',
            value:
                '${data.meetings.where((meeting) => meeting.reviewState == MeetingReviewState.draftRecording || meeting.reviewState == MeetingReviewState.recordedPendingTranscription).length}',
            detail: 'New recordings with local audio already stored.',
            color: const Color(0xFF7A5D42)),
        MetricData(
            title: 'AI Pending',
            value: '${pendingAiMeetings.length}',
            detail:
                'Meetings waiting on transcription or extraction, while remaining safe to continue manually.',
            color: const Color(0xFF3E7B7D)),
        MetricData(
            title: 'Manual Fallback',
            value: '${manualFallbackMeetings.length}',
            detail:
                'Meetings moved out of AI flow but still editable and reviewable locally.',
            color: const Color(0xFFC06B37)),
        MetricData(
            title: 'Review Required',
            value:
                '${data.meetings.where((meeting) => _reviewStateNeedsAction(meeting.reviewState)).length}',
            detail: 'Meetings blocked behind transcript or candidate review.',
            color: const Color(0xFF4D5F8C)),
        MetricData(
            title: 'Task Candidates',
            value: '${candidateItems.length}',
            detail: 'Extracted items waiting for accept, reject, or merge.',
            color: const Color(0xFF4D5F8C)),
      ],
      sections: <Widget>[
        ResponsiveGrid(
          children: <Widget>[
            DetailCard(
              title: 'Meeting Lifecycle Queue',
              subtitle:
                  'Pending AI, failed AI, and manual-only meetings stay editable',
              children: _buildMeetingLifecycleQueue(data),
            ),
            DetailCard(
                title: 'Extracted Task Candidates',
                subtitle: 'Review before promotion',
                children: _buildMeetingCandidateQueue(candidateItems)),
          ],
        ),
        DetailCard(
          title: 'Manual Review Path',
          subtitle: 'Keep moving when AI is unavailable or not trusted',
          children: _buildManualFallbackRows(data),
        ),
      ],
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureSectionScaffold(
      title: 'Global Search',
      summary:
          'Grouped discovery across projects, tasks, meetings, raw captures, and people with structured filters on top.',
      accent: AppSection.search.accent,
      actions: const <ActionData>[
        ActionData(label: 'Projects', icon: Icons.apartment_rounded),
        ActionData(label: 'Meetings', icon: Icons.groups_rounded),
        ActionData(label: 'Raw Captures', icon: Icons.perm_media_rounded),
      ],
      metrics: const <MetricData>[
        MetricData(
            title: 'Indexed Types',
            value: '5',
            detail: 'Projects, tasks, meetings, people, raw captures.',
            color: Color(0xFF5A5E9A)),
        MetricData(
            title: 'Scoped Filters',
            value: '8',
            detail:
                'Date, OEM, worker, coordinator, manager, source, type, status.',
            color: Color(0xFF2F6B63)),
      ],
      sections: const <Widget>[
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText:
                        'Search projects, tasks, meetings, raw captures, and people',
                    prefixIcon: Icon(Icons.manage_search_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                FilterStrip(labels: <String>[
                  'Date Range',
                  'Project Name',
                  'OEM',
                  'Worker',
                  'Coordinator',
                  'Project Manager',
                  'Task Type',
                  'Status'
                ]),
              ],
            ),
          ),
        ),
        ResponsiveGrid(
          children: <Widget>[
            DetailCard(
              title: 'Search Scope',
              subtitle: 'Grouped result sections',
              children: <Widget>[
                InfoRow(
                    label: 'Projects',
                    value: 'Preview recent activity and open tasks.'),
                InfoRow(
                    label: 'Tasks',
                    value:
                        'Match on notes, location, task title, and worker fields.'),
                InfoRow(
                    label: 'Meetings',
                    value: 'Show transcript and summary snippets for context.'),
              ],
            ),
            DetailCard(
              title: 'Recent Result Pattern',
              subtitle: 'Snippet-first review',
              children: <Widget>[
                QueueItem(
                    title: 'Meeting transcript match',
                    caption:
                        '"handover checklist" appears in corrected transcript and summary.',
                    status: 'Meetings'),
                QueueItem(
                    title: 'Task notes match',
                    caption:
                        'Maintenance note references the same shaft access issue.',
                    status: 'Tasks'),
                QueueItem(
                    title: 'Raw capture match',
                    caption:
                        'Original WhatsApp paste preserved for traceability.',
                    status: 'Raw captures'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.data});

  final AppShellData data;

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
            label: 'Meeting Minutes Pack', icon: Icons.library_books_rounded),
        ActionData(label: 'Project Summary', icon: Icons.summarize_rounded),
      ],
      metrics: <MetricData>[
        const MetricData(
            title: 'Templates',
            value: '6',
            detail:
                'Daily, by-project, worker summary, meeting pack, project summary, custom.',
            color: Color(0xFF6D4B73)),
        MetricData(
            title: 'Formats',
            value:
                '${data.reportRuns.map((run) => run.outputFormat).toSet().length.clamp(1, 4)}',
            detail: 'In-app summary, PDF placeholder, CSV, JSON.',
            color: const Color(0xFF3E7B7D)),
      ],
      sections: <Widget>[
        ResponsiveGrid(
          children: <Widget>[
            const DetailCard(
              title: 'Available Reports',
              subtitle: 'Core local outputs',
              children: <Widget>[
                InfoRow(
                    label: 'Daily task list',
                    value:
                        'Today and upcoming work across the local schedule.'),
                InfoRow(
                    label: 'Worker summary',
                    value: 'Assigned work grouped by worker and date range.'),
                InfoRow(
                    label: 'Meeting minutes pack',
                    value:
                        'Finalized meeting summaries and extracted decisions.'),
              ],
            ),
            DetailCard(
                title: 'Recent Runs',
                subtitle: 'Local history',
                children: _buildReportQueue(data)),
          ],
        ),
      ],
    );
  }
}

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key, required this.data});

  final AppShellData data;

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
            icon: Icons.playlist_add_check_circle_rounded),
      ],
      metrics: <MetricData>[
        MetricData(
            title: 'Imports',
            value: '${data.importRuns.length}',
            detail: 'Recent local bundle previews and applies.',
            color: const Color(0xFF3E7B7D)),
        MetricData(
            title: 'Duplicates',
            value: '${_duplicateRiskCount(data)}',
            detail: 'Likely overlaps that need merge or create decisions.',
            color: const Color(0xFFC06B37)),
      ],
      sections: <Widget>[
        const DetailCard(
          title: 'Import Flow',
          subtitle: 'Preview before write',
          children: <Widget>[
            InfoRow(label: '1', value: 'Pick bundle and parse manifest.'),
            InfoRow(
                label: '2',
                value: 'Preview projects, tasks, meetings, and people.'),
            InfoRow(
                label: '3',
                value:
                    'Review duplicate candidates and choose merge or create.'),
            InfoRow(
                label: '4',
                value: 'Apply import and store local result summary.'),
          ],
        ),
        DetailCard(
          title: 'Duplicate Candidates',
          subtitle: 'Review queue',
          children: _buildImportQueue(data),
        ),
      ],
    );
  }
}

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key, required this.data});

  final AppShellData data;

  @override
  Widget build(BuildContext context) {
    return FeatureSectionScaffold(
      title: 'Export Builder',
      summary:
          'Package selected local records into a canonical bundle with attachment manifest and optional secondary report outputs.',
      accent: AppSection.exportSection.accent,
      actions: const <ActionData>[
        ActionData(label: 'Choose Scope', icon: Icons.select_all_rounded),
        ActionData(label: 'Formats', icon: Icons.data_object_rounded),
        ActionData(label: 'Generate Bundle', icon: Icons.inventory_rounded),
      ],
      metrics: <MetricData>[
        MetricData(
            title: 'Recent Exports',
            value: '${data.exportRuns.length}',
            detail: 'Current export history from the local package.',
            color: const Color(0xFF9C6B3C)),
        MetricData(
            title: 'Selected Projects',
            value:
                '${data.projects.where((project) => project.archivedAt == null).take(2).length}',
            detail: 'Current export scope across local project data.',
            color: const Color(0xFF4D5F8C)),
      ],
      sections: const <Widget>[
        DetailCard(
          title: 'Selected Scope',
          subtitle: 'Examples from the current draft',
          children: <Widget>[
            InfoRow(
                label: 'Projects',
                value: 'Pompallier Ponsonby, City Rail Lift Modernization'),
            InfoRow(label: 'Date range', value: '2026-03-01 to 2026-03-09'),
            InfoRow(
                label: 'Meetings',
                value:
                    'Include finalized coordination and review meetings only'),
          ],
        ),
        DetailCard(
          title: 'Output Formats',
          subtitle: 'Canonical plus secondary outputs',
          children: <Widget>[
            FilterStrip(labels: <String>[
              'Bundle JSON',
              'CSV',
              'JSON Reports',
              'Attachments'
            ]),
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

class FeatureSectionScaffold extends StatelessWidget {
  const FeatureSectionScaffold({
    super.key,
    required this.title,
    required this.summary,
    required this.accent,
    required this.actions,
    required this.metrics,
    required this.sections,
  });

  final String title;
  final String summary;
  final Color accent;
  final List<ActionData> actions;
  final List<MetricData> metrics;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        HeroPanel(title: title, summary: summary, accent: accent),
        if (actions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions
                .map(
                  (action) => ActionChip(
                    avatar: Icon(action.icon, size: 18),
                    label: Text(action.label),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (metrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          ResponsiveGrid(
            children: metrics
                .map(
                  (metric) => MetricTile(
                    title: metric.title,
                    value: metric.value,
                    detail: metric.detail,
                    color: metric.color,
                  ),
                )
                .toList(growable: false),
          ),
        ],
        for (final section in sections) ...<Widget>[
          const SizedBox(height: 20),
          section,
        ],
      ],
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel(
      {super.key,
      required this.title,
      required this.summary,
      required this.accent});

  final String title;
  final String summary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: <Color>[
            accent,
            Color.lerp(accent, const Color(0xFFD9A25C), 0.65)!
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFFF2ECE0),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile(
      {super.key,
      required this.title,
      required this.value,
      required this.detail,
      required this.color});

  final String title;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14)),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(value,
                style: theme.textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 10),
            Text(detail,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class DetailCard extends StatelessWidget {
  const DetailCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.children});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class QueueItem extends StatelessWidget {
  const QueueItem(
      {super.key,
      required this.title,
      required this.caption,
      required this.status});

  final String title;
  final String caption;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2DDD4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(caption,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            StatusPill(label: status),
          ],
        ),
      ),
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

List<TaskEntity> _upcomingTasks(AppShellData data) {
  final now = DateTime.now();
  return data.tasks
      .where((task) =>
          task.archivedAt == null &&
          task.scheduledDate != null &&
          task.scheduledDate!
              .toLocal()
              .isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59)))
      .toList(growable: false);
}

List<TaskEntity> _openTasks(AppShellData data) {
  return data.tasks
      .where((task) =>
          task.archivedAt == null &&
          task.status != TaskStatus.completed &&
          task.status != TaskStatus.cancelled)
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

bool _reviewStateNeedsAction(MeetingReviewState state) {
  return state == MeetingReviewState.reviewRequired ||
      state == MeetingReviewState.reviewInProgress ||
      state == MeetingReviewState.taskCandidateResolution ||
      state == MeetingReviewState.manualReviewOnly ||
      state == MeetingReviewState.transcriptionFailed ||
      state == MeetingReviewState.extractionFailed;
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

List<Widget> _buildCaptureQueue(List pendingCaptures) {
  if (pendingCaptures.isEmpty) {
    return const <Widget>[
      QueueItem(
          title: 'Inbox is clear',
          caption: 'All local captures are reviewed or finalized.',
          status: 'Clear')
    ];
  }
  return pendingCaptures.map<Widget>((capture) {
    final confidence = capture.classificationConfidence == null
        ? 'n/a'
        : capture.classificationConfidence!.toStringAsFixed(2);
    final title = capture.rawText?.split('\n').first.trim().isNotEmpty == true
        ? capture.rawText!.split('\n').first.trim()
        : capture.transcriptText?.split('\n').first.trim().isNotEmpty == true
            ? capture.transcriptText!.split('\n').first.trim()
            : 'Captured ${capture.channel.name}';
    final caption =
        'Detected type: ${capture.classificationType} • Confidence $confidence • Captured ${_dateLabel(capture.captureTime)}';
    final status = capture.parseStatus == RawCaptureParseStatus.failed
        ? 'Failed'
        : (capture.classificationConfidence ?? 1) < 0.7
            ? 'Low confidence'
            : 'Review';
    return QueueItem(title: title, caption: caption, status: status);
  }).toList(growable: false);
}

List<Widget> _buildProjectCards(List projects, AppShellData data) {
  if (projects.isEmpty) {
    return const <Widget>[
      DetailCard(
        title: 'No projects yet',
        subtitle:
            'Local project records will appear here once created or imported.',
        children: <Widget>[
          InfoRow(
              label: 'Next step',
              value: 'Create a project or review a raw capture to promote one.')
        ],
      ),
    ];
  }
  return projects.map<Widget>((project) {
    final openTaskCount = data.tasks
        .where((task) =>
            task.projectId == project.id &&
            task.archivedAt == null &&
            task.status != TaskStatus.completed &&
            task.status != TaskStatus.cancelled)
        .length;
    return DetailCard(
      title: project.projectName,
      subtitle:
          'OEM: ${project.clientOem ?? 'Unknown'} • Open tasks: $openTaskCount • Last activity: ${_dateLabel(project.updatedAt)}',
      children: <Widget>[
        InfoRow(
            label: 'Location',
            value: project.siteLocation ?? 'No site location recorded'),
        InfoRow(
            label: 'Coordinator', value: project.coordinatorName ?? 'Not set'),
        InfoRow(
            label: 'Project manager',
            value: project.projectManagerName ?? 'Not set'),
      ],
    );
  }).toList(growable: false);
}

List<Widget> _buildTaskQueue(List<TaskEntity> tasks,
    {bool provisional = false}) {
  if (tasks.isEmpty) {
    return <Widget>[
      QueueItem(
          title:
              provisional ? 'No provisional tasks' : 'No tasks in this bucket',
          caption: provisional
              ? 'Nothing is waiting on final confirmation right now.'
              : 'Local task data will appear here when scheduled.',
          status: 'Empty')
    ];
  }
  return tasks.take(3).map((task) {
    final title = task.taskTitle?.trim().isNotEmpty == true
        ? task.taskTitle!
        : task.taskType.name;
    final caption = _joinParts(<String?>[
      'Project: ${task.projectId ?? 'Unlinked'}',
      'Worker: ${task.workerName ?? 'Unassigned'}',
      'Status: ${task.status.name}'
    ]);
    final status = provisional
        ? (task.needsReview ? 'Review' : 'Provisional')
        : task.status.name;
    return QueueItem(title: title, caption: caption, status: status);
  }).toList(growable: false);
}

List<MeetingTaskCandidateEntity> _meetingCandidates(AppShellData data) {
  return data.meetings
      .expand((meeting) => meeting.taskCandidates)
      .take(5)
      .toList(growable: false);
}

List<Widget> _buildMeetingCandidateQueue(
    List<MeetingTaskCandidateEntity> candidates) {
  if (candidates.isEmpty) {
    return const <Widget>[
      QueueItem(
          title: 'No task candidates yet',
          caption:
              'Candidates will appear here after extraction and before task promotion.',
          status: 'Empty')
    ];
  }
  return candidates.take(3).map((candidate) {
    final title = candidate.taskTitle?.trim().isNotEmpty == true
        ? candidate.taskTitle!
        : candidate.taskType.name;
    final caption =
        'Confidence ${candidate.confidence.toStringAsFixed(2)} • ${candidate.projectName ?? 'No project yet'}';
    return QueueItem(
        title: title, caption: caption, status: candidate.state.name);
  }).toList(growable: false);
}

List<Widget> _buildMeetingLifecycleQueue(AppShellData data) {
  final activeMeetings = data.meetings
      .where((meeting) => meeting.archivedAt == null)
      .where((meeting) =>
          _reviewStateNeedsAction(meeting.reviewState) ||
          _isPendingAiState(meeting.reviewState))
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
    final capture = _findCaptureForMeeting(data, meeting);
    final title = meeting.title?.trim().isNotEmpty == true
        ? meeting.title!
        : 'Untitled meeting';
    return QueueItem(
      title: title,
      caption: _meetingLifecycleCaption(meeting, capture),
      status: _meetingStatusLabel(meeting.reviewState),
    );
  }).toList(growable: false);
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
              'When AI is unavailable, move the meeting to manual review and continue editing summary, minutes, transcript, and project links locally.'),
      InfoRow(
          label: 'Finalize',
          value:
              'Meetings can still be finalized after manual notes are captured, without waiting for successful extraction.'),
      InfoRow(
          label: 'Retry',
          value:
              'Retry transcription or extraction later only when the operator decides it is worth it.'),
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

List<Widget> _buildReportQueue(AppShellData data) {
  if (data.reportRuns.isEmpty) {
    return const <Widget>[
      QueueItem(
          title: 'No report runs yet',
          caption:
              'Generated report history will appear here after local output is created.',
          status: 'Empty')
    ];
  }
  return data.reportRuns.take(3).map((run) {
    return QueueItem(
        title: run.reportType,
        caption:
            'Format: ${run.outputFormat} • Created ${_dateLabel(run.createdAt)}',
        status: run.outputFormat.toUpperCase());
  }).toList(growable: false);
}

List<Widget> _buildImportQueue(AppShellData data) {
  if (data.importRuns.isEmpty) {
    return const <Widget>[
      QueueItem(
          title: 'No import previews yet',
          caption:
              'Preview and apply activity will appear here after the first bundle review.',
          status: 'Empty')
    ];
  }
  return data.importRuns.take(3).map((run) {
    return QueueItem(
        title: run.bundleName,
        caption:
            'Status: ${run.status} • Imported ${_dateLabel(run.importTime)}',
        status: run.status);
  }).toList(growable: false);
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

String _meetingLifecycleCaption(
    MeetingEntity meeting, RawCaptureEntity? capture) {
  final details = <String>[];

  switch (meeting.reviewState) {
    case MeetingReviewState.recordedPendingTranscription:
      details.add(
          'Audio is saved locally and ready for transcription or manual review.');
      break;
    case MeetingReviewState.transcribing:
      details.add(
          'Transcription is in progress. The operator can still switch to manual review.');
      break;
    case MeetingReviewState.transcribedPendingExtraction:
      details.add(
          'Transcript is ready. Start extraction later or continue with manual notes now.');
      break;
    case MeetingReviewState.extracting:
      details.add(
          'Extraction is running. Manual editing remains available if the result is not usable.');
      break;
    case MeetingReviewState.transcriptionFailed:
    case MeetingReviewState.extractionFailed:
      details.add(capture?.transcriptionError?.trim().isNotEmpty == true
          ? capture!.transcriptionError!
          : 'The last AI step failed. Move to manual review to continue locally.');
      break;
    case MeetingReviewState.manualReviewOnly:
      details.add(_manualFallbackDetail(meeting));
      break;
    case MeetingReviewState.reviewRequired:
    case MeetingReviewState.reviewInProgress:
    case MeetingReviewState.taskCandidateResolution:
      details.add(
          '${meeting.taskCandidates.length} task candidates remain reviewable before final save.');
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

RawCaptureEntity? _findCaptureForMeeting(
    AppShellData data, MeetingEntity meeting) {
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

class ActionData {
  const ActionData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class MetricData {
  const MetricData(
      {required this.title,
      required this.value,
      required this.detail,
      required this.color});

  final String title;
  final String value;
  final String detail;
  final Color color;
}
