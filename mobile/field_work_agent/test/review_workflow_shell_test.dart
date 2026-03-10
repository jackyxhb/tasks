import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_work_agent/domain/entities/export_run_entity.dart';
import 'package:field_work_agent/domain/entities/import_run_entity.dart';
import 'package:field_work_agent/domain/entities/import_export_bundle_entity.dart';
import 'package:field_work_agent/domain/entities/meeting_entity.dart';
import 'package:field_work_agent/domain/entities/meeting_task_candidate_entity.dart';
import 'package:field_work_agent/domain/entities/project_entity.dart';
import 'package:field_work_agent/domain/entities/raw_capture_entity.dart';
import 'package:field_work_agent/domain/entities/report_run_entity.dart';
import 'package:field_work_agent/domain/entities/task_entity.dart';
import 'package:field_work_agent/domain/enums/meeting_review_state.dart';
import 'package:field_work_agent/domain/enums/raw_capture_channel.dart';
import 'package:field_work_agent/domain/enums/raw_capture_parse_status.dart';
import 'package:field_work_agent/domain/enums/task_priority.dart';
import 'package:field_work_agent/domain/enums/task_status.dart';
import 'package:field_work_agent/domain/enums/task_candidate_state.dart';
import 'package:field_work_agent/domain/enums/task_type.dart';
import 'package:field_work_agent/features/exchange/application/exchange_models.dart';
import 'package:field_work_agent/features/meetings/application/meeting_review_models.dart';
import 'package:field_work_agent/features/projects/application/project_draft.dart';
import 'package:field_work_agent/features/reports/application/report_models.dart';
import 'package:field_work_agent/features/search/application/search_models.dart';
import 'package:field_work_agent/features/tasks/application/task_models.dart';
import 'package:field_work_agent/src/app_runtime.dart';
import 'package:field_work_agent/src/app_sections.dart';
import 'package:field_work_agent/src/section_screens.dart';

void main() {
  testWidgets('inbox review dialog submits task review draft', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 3, 10, 7, 30);
    final data = AppShellData(
      projects: <ProjectEntity>[
        ProjectEntity(
          id: 'project_1',
          projectName: 'Pompallier Ponsonby',
          projectNameNormalized: 'pompallier ponsonby',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      tasks: const <TaskEntity>[],
      meetings: const <MeetingEntity>[],
      rawCaptures: <RawCaptureEntity>[
        RawCaptureEntity(
          id: 'capture_1',
          channel: RawCaptureChannel.manualForm,
          rawText: 'Need on-site training support for Lin Yong tomorrow.',
          captureTime: now,
          classificationType: 'task',
          classificationConfidence: 0.83,
          parseStatus: RawCaptureParseStatus.parsed,
          createdAt: now,
        ),
      ],
      reportRuns: const <ReportRunEntity>[],
      importRuns: const <ImportRunEntity>[],
      exportRuns: const <ExportRunEntity>[],
    );

    final controller = _FakeAppShellController(data);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.inbox,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review Task'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Task Title'), 'Updated training support');
    await tester.enterText(find.widgetWithText(TextField, 'Scheduled Date (YYYY-MM-DD)'), '2026-03-11');
    await tester.tap(find.text('Create Task'));
    await tester.pumpAndSettle();

    expect(controller.captureTaskDraft, isNotNull);
    expect(controller.captureTaskDraft!.captureId, 'capture_1');
    expect(controller.captureTaskDraft!.taskTitle, 'Updated training support');
    expect(controller.captureTaskDraft!.scheduledDateText, '2026-03-11');
  });

  testWidgets('meeting review dialog submits candidate promotion', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 3, 10, 9, 0);
    final data = AppShellData(
      projects: const <ProjectEntity>[],
      tasks: const <TaskEntity>[],
      meetings: <MeetingEntity>[
        MeetingEntity(
          id: 'meeting_1',
          title: 'Pompallier Coordination',
          reviewState: MeetingReviewState.taskCandidateResolution,
          needsReview: true,
          transcriptText: 'Need on-site training support for Lin Yong tomorrow.',
          taskCandidates: const <MeetingTaskCandidateEntity>[
            MeetingTaskCandidateEntity(
              id: 'candidate_1',
              taskType: TaskType.maintenance,
              state: TaskCandidateState.newCandidate,
              confidence: 0.87,
              sourceSnippet: 'Support Lin Yong on-site tomorrow morning.',
              taskTitle: 'On-site training support',
              projectName: 'Pompallier Ponsonby',
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      ],
      rawCaptures: const <RawCaptureEntity>[],
      reportRuns: const <ReportRunEntity>[],
      importRuns: const <ImportRunEntity>[],
      exportRuns: const <ExportRunEntity>[],
    );

    final controller = _FakeAppShellController(data);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.meetings,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reviewButton = find.widgetWithText(FilledButton, 'Review Meeting');
    await tester.ensureVisible(reviewButton.first);
    await tester.tap(reviewButton.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Task').last);
    await tester.pumpAndSettle();

    expect(controller.acceptedCandidateId, 'candidate_1');
    expect(controller.acceptedMeetingId, 'meeting_1');
    expect(controller.acceptedAgenteeName, 'Local Agentee');
  });

  testWidgets('meeting review dialog submits candidate edits', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 3, 10, 9, 0);
    final data = AppShellData(
      projects: const <ProjectEntity>[],
      tasks: const <TaskEntity>[],
      meetings: <MeetingEntity>[
        MeetingEntity(
          id: 'meeting_1',
          title: 'Pompallier Coordination',
          reviewState: MeetingReviewState.taskCandidateResolution,
          needsReview: true,
          transcriptText: 'Need on-site training support for Lin Yong tomorrow.',
          taskCandidates: const <MeetingTaskCandidateEntity>[
            MeetingTaskCandidateEntity(
              id: 'candidate_1',
              taskType: TaskType.maintenance,
              state: TaskCandidateState.newCandidate,
              confidence: 0.87,
              sourceSnippet: 'Support Lin Yong on-site tomorrow morning.',
              taskTitle: 'On-site training support',
              projectName: 'Pompallier Ponsonby',
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      ],
      rawCaptures: const <RawCaptureEntity>[],
      reportRuns: const <ReportRunEntity>[],
      importRuns: const <ImportRunEntity>[],
      exportRuns: const <ExportRunEntity>[],
    );

    final controller = _FakeAppShellController(data);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.meetings,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reviewButton = find.widgetWithText(FilledButton, 'Review Meeting');
    await tester.ensureVisible(reviewButton.first);
    await tester.tap(reviewButton.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Candidate Task Title'),
      'Edited candidate title',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save Candidate'));
    await tester.pumpAndSettle();

    expect(controller.acceptedMeetingId, 'meeting_1');
    expect(controller.acceptedCandidateId, 'candidate_1');
    expect(controller.updatedCandidateDraft, isNotNull);
    expect(controller.updatedCandidateDraft!.taskTitle, 'Edited candidate title');
  });

  testWidgets('meeting review dialog submits candidate merge', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 3, 10, 9, 0);
    final data = AppShellData(
      projects: <ProjectEntity>[
        ProjectEntity(
          id: 'project_1',
          projectName: 'Pompallier Ponsonby',
          projectNameNormalized: 'pompallier ponsonby',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      tasks: <TaskEntity>[
        TaskEntity(
          id: 'task_1',
          projectId: 'project_1',
          taskType: TaskType.maintenance,
          taskTitle: 'Existing maintenance visit',
          agenteeName: 'Local Agentee',
          status: TaskStatus.planned,
          priority: TaskPriority.medium,
          isProvisional: false,
          needsReview: false,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      meetings: <MeetingEntity>[
        MeetingEntity(
          id: 'meeting_1',
          title: 'Pompallier Coordination',
          reviewState: MeetingReviewState.taskCandidateResolution,
          needsReview: true,
          transcriptText: 'Need on-site training support for Lin Yong tomorrow.',
          taskCandidates: const <MeetingTaskCandidateEntity>[
            MeetingTaskCandidateEntity(
              id: 'candidate_1',
              taskType: TaskType.maintenance,
              state: TaskCandidateState.newCandidate,
              confidence: 0.87,
              sourceSnippet: 'Support Lin Yong on-site tomorrow morning.',
              taskTitle: 'On-site training support',
              projectName: 'Pompallier Ponsonby',
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      ],
      rawCaptures: const <RawCaptureEntity>[],
      reportRuns: const <ReportRunEntity>[],
      importRuns: const <ImportRunEntity>[],
      exportRuns: const <ExportRunEntity>[],
    );

    final controller = _FakeAppShellController(data);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.meetings,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reviewButton = find.widgetWithText(FilledButton, 'Review Meeting');
    await tester.ensureVisible(reviewButton.first);
    await tester.tap(reviewButton.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Merge Task').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.pumpAndSettle();

    expect(controller.mergedMeetingId, 'meeting_1');
    expect(controller.mergedCandidateId, 'candidate_1');
    expect(controller.mergedTaskId, 'task_1');
  });

  testWidgets('meeting review dialog submits manual fallback with current draft', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 3, 10, 9, 0);
    final data = AppShellData(
      projects: <ProjectEntity>[
        ProjectEntity(
          id: 'project_1',
          projectName: 'Pompallier Ponsonby',
          projectNameNormalized: 'pompallier ponsonby',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      tasks: const <TaskEntity>[],
      meetings: <MeetingEntity>[
        MeetingEntity(
          id: 'meeting_1',
          title: 'Pompallier Coordination',
          reviewState: MeetingReviewState.transcriptionFailed,
          needsReview: true,
          summary: 'Initial summary',
          minutesMarkdown: '- Existing minute',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      rawCaptures: const <RawCaptureEntity>[],
      reportRuns: const <ReportRunEntity>[],
      importRuns: const <ImportRunEntity>[],
      exportRuns: const <ExportRunEntity>[],
    );

    final controller = _FakeAppShellController(data);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.meetings,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reviewButton = find.widgetWithText(FilledButton, 'Review Meeting');
    await tester.ensureVisible(reviewButton.first);
    await tester.tap(reviewButton.first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Summary'),
      'Manual fallback summary',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Minutes Markdown'),
      '- Manual minute',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Manual Fallback Reason'),
      'Offline provider unavailable',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Manual Review'));
    await tester.pumpAndSettle();

    expect(controller.manualFallbackReason, 'Offline provider unavailable');
    expect(controller.manualFallbackDraft, isNotNull);
    expect(controller.manualFallbackDraft!.summary, 'Manual fallback summary');
    expect(controller.manualFallbackDraft!.minutesMarkdown, '- Manual minute');
  });

  testWidgets('search screen runs grouped local search', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const data = AppShellData.empty();
    final controller = _FakeAppShellController(data);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.search,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Search Query'),
      'handover',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Run Search'));
    await tester.pumpAndSettle();

    expect(controller.searchRequest, isNotNull);
    expect(controller.searchRequest!.query, 'handover');
    expect(find.text('Meeting transcript match'), findsOneWidget);
  });

  testWidgets('reports screen generates a local report', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 3, 10, 9, 0);
    final data = AppShellData(
      projects: <ProjectEntity>[
        ProjectEntity(
          id: 'project_1',
          projectName: 'Pompallier Ponsonby',
          projectNameNormalized: 'pompallier ponsonby',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      tasks: const <TaskEntity>[],
      meetings: const <MeetingEntity>[],
      rawCaptures: const <RawCaptureEntity>[],
      reportRuns: const <ReportRunEntity>[],
      importRuns: const <ImportRunEntity>[],
      exportRuns: const <ExportRunEntity>[],
    );
    final controller = _FakeAppShellController(data);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.reports,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Report'));
    await tester.pumpAndSettle();

    expect(controller.generatedDailyReportDate, isNotNull);
    expect(find.text('Last Generated Report'), findsOneWidget);
    expect(find.textContaining('Daily task list ready'), findsOneWidget);
  });

  testWidgets('import and export screens call bundle workflows', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 3, 10, 9, 0);
    final data = AppShellData(
      projects: <ProjectEntity>[
        ProjectEntity(
          id: 'project_1',
          projectName: 'Pompallier Ponsonby',
          projectNameNormalized: 'pompallier ponsonby',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      tasks: const <TaskEntity>[],
      meetings: const <MeetingEntity>[],
      rawCaptures: const <RawCaptureEntity>[],
      reportRuns: const <ReportRunEntity>[],
      importRuns: const <ImportRunEntity>[],
      exportRuns: const <ExportRunEntity>[],
    );
    final controller = _FakeAppShellController(data);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.importSection,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Relative Import Path'),
      'imports/pompallier.json',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Preview Import'));
    await tester.pumpAndSettle();

    expect(controller.previewImportPath, 'imports/pompallier.json');
    expect(find.text('Preview Summary'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Apply Import'));
    await tester.pumpAndSettle();

    expect(controller.appliedImportPath, 'imports/pompallier.json');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.exportSection,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Bundle'));
    await tester.pumpAndSettle();

    expect(controller.exportScopeRequest, isNotNull);
    expect(find.text('Generated Bundle'), findsOneWidget);
  });

  testWidgets('project screen submits project draft', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const data = AppShellData(
      projects: <ProjectEntity>[],
      tasks: <TaskEntity>[],
      meetings: <MeetingEntity>[],
      rawCaptures: <RawCaptureEntity>[],
      reportRuns: <ReportRunEntity>[],
      importRuns: <ImportRunEntity>[],
      exportRuns: <ExportRunEntity>[],
    );

    final controller = _FakeAppShellController(data);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.projects,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addProjectButton = find.byIcon(Icons.add_business_rounded).last;
    await tester.ensureVisible(addProjectButton);
    await tester.tap(addProjectButton);
    await tester.pumpAndSettle();

    final projectFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(projectFields.at(0), 'Harbour Upgrade');
    await tester.enterText(projectFields.at(5), 'Mina');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(controller.createdProjectDraft, isNotNull);
    expect(controller.createdProjectDraft!.projectName, 'Harbour Upgrade');
    expect(controller.createdProjectDraft!.coordinatorName, 'Mina');
  });

  testWidgets('task screen submits task draft', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 3, 10, 9, 0);
    final data = AppShellData(
      projects: <ProjectEntity>[
        ProjectEntity(
          id: 'project_1',
          projectName: 'Harbour Upgrade',
          projectNameNormalized: 'harbour upgrade',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      tasks: const <TaskEntity>[],
      meetings: const <MeetingEntity>[],
      rawCaptures: const <RawCaptureEntity>[],
      reportRuns: const <ReportRunEntity>[],
      importRuns: const <ImportRunEntity>[],
      exportRuns: const <ExportRunEntity>[],
    );

    final controller = _FakeAppShellController(data);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.tasks,
            data: data,
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final newTaskButton = find.byIcon(Icons.add_task_rounded).last;
    await tester.ensureVisible(newTaskButton);
    await tester.tap(newTaskButton);
    await tester.pumpAndSettle();

    final taskFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(taskFields.at(0), 'Swap antenna feed');
    await tester.enterText(taskFields.at(2), '2026-03-12');
    await tester.enterText(taskFields.at(10), 'Field Agent');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(controller.createdTaskDraft, isNotNull);
    expect(controller.createdTaskDraft!.taskTitle, 'Swap antenna feed');
    expect(controller.createdTaskDraft!.agenteeName, 'Field Agent');
    expect(controller.createdTaskDraft!.status, TaskStatus.planned);
    expect(controller.createdTaskDraft!.priority, TaskPriority.medium);
  });
}

class _FakeAppShellController implements AppShellController {
  _FakeAppShellController(this.data);

  final AppShellData data;

  CaptureTaskReviewDraft? captureTaskDraft;
  ProjectDraft? createdProjectDraft;
  TaskDraft? createdTaskDraft;
  MeetingReviewDraft? savedMeetingDraft;
  MeetingReviewDraft? manualFallbackDraft;
  String? manualFallbackReason;
  MeetingTaskCandidateDraft? updatedCandidateDraft;
  String? acceptedMeetingId;
  String? acceptedCandidateId;
  String? acceptedAgenteeName;
  String? mergedMeetingId;
  String? mergedCandidateId;
  String? mergedTaskId;
  SearchRequest? searchRequest;
  DateTime? generatedDailyReportDate;
  String? generatedProjectReportId;
  ReportFilter? generatedMinutesFilter;
  String? previewImportPath;
  String? appliedImportPath;
  ExportScopeRequest? exportScopeRequest;

  @override
  Future<AppShellData> load() async => data;

  @override
  Future<AppShellData> acceptMeetingCandidateAsNewTask({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) async {
    acceptedMeetingId = meetingId;
    acceptedCandidateId = candidateId;
    acceptedAgenteeName = agenteeName;
    return data;
  }

  @override
  Future<AppShellData> beginMeetingReview({required String meetingId, String? actorName}) async => data;

  @override
  Future<AppShellData> beginMeetingTaskCandidateResolution({required String meetingId, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> createProject({required ProjectDraft draft, String? actorName}) async {
    createdProjectDraft = draft;
    return data;
  }

  @override
  Future<AppShellData> createTask({required TaskDraft draft, String? actorName}) async {
    createdTaskDraft = draft;
    return data;
  }

  @override
  Future<AppShellData> createTaskFromCapture({required CaptureTaskReviewDraft draft, String? actorName}) async {
    captureTaskDraft = draft;
    return data;
  }

  @override
  Future<AppShellData> finalizeMeeting({required String meetingId, String? actorName}) async => data;

  @override
  Future<AppShellData> mergeMeetingCandidateIntoTask({
    required String meetingId,
    required String candidateId,
    required String taskId,
    String? actorName,
  }) async {
    mergedMeetingId = meetingId;
    mergedCandidateId = candidateId;
    mergedTaskId = taskId;
    return data;
  }

  @override
  Future<AppShellData> markCaptureReviewed({required String captureId, String? actorName}) async => data;

  @override
  Future<AppShellData> moveMeetingToManualReview({
    required String meetingId,
    required String reason,
    MeetingReviewDraft? draft,
    String? actorName,
  }) async {
    manualFallbackReason = reason;
    manualFallbackDraft = draft;
    return data;
  }

  @override
  Future<AppShellData> archiveProject({required String projectId, String? actorName}) async => data;

  @override
  Future<AppShellData> archiveTask({required String taskId, String? actorName}) async => data;

  @override
  Future<AppShellData> applyImportBundle({
    required String relativeImportPath,
    String? actorName,
  }) async {
    appliedImportPath = relativeImportPath;
    return data;
  }

  @override
  Future<ImportExportBundleEntity> createExportBundle({
    required ExportScopeRequest scope,
    String? actorName,
  }) async {
    exportScopeRequest = scope;
    return ImportExportBundleEntity(
      schemaVersion: 'v1',
      bundleId: 'bundle_1',
      exportedAt: DateTime.utc(2026, 3, 10),
      sourceAppName: 'field_work_agent',
      sourceAppVersion: '0.1.0',
      scope: ExportScope(type: scope.type, value: scope.value),
      projects: const <Map<String, Object?>>[],
      tasks: const <Map<String, Object?>>[],
      meetings: const <Map<String, Object?>>[],
      people: const <Map<String, Object?>>[],
      attachmentsManifest: const <AttachmentManifestEntry>[],
    );
  }

  @override
  Future<GeneratedReport> generateDailyTaskListReport({
    required DateTime date,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    generatedDailyReportDate = date;
    return const GeneratedReport(
      reportType: 'daily_task_list',
      summary: 'Daily task list ready',
      payload: <String, Object?>{'task_count': 1},
    );
  }

  @override
  Future<GeneratedReport> generateMeetingMinutesPackReport({
    required ReportFilter filter,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    generatedMinutesFilter = filter;
    return const GeneratedReport(
      reportType: 'meeting_minutes_pack',
      summary: 'Meeting minutes pack ready',
      payload: <String, Object?>{'meeting_count': 1},
    );
  }

  @override
  Future<GeneratedReport> generateProjectSummaryReport({
    required String projectId,
    required ReportOutputFormat outputFormat,
    String? actorName,
  }) async {
    generatedProjectReportId = projectId;
    return const GeneratedReport(
      reportType: 'project_summary',
      summary: 'Project summary ready',
      payload: <String, Object?>{'project_count': 1},
    );
  }

  @override
  Future<AppShellData> rejectMeetingCandidate({required String meetingId, required String candidateId, String? actorName}) async =>
      data;

  @override
  Future<ImportPreviewResult> previewImportBundle({
    required String relativeImportPath,
    String? actorName,
  }) async {
    previewImportPath = relativeImportPath;
    return ImportPreviewResult(
      bundle: ImportExportBundleEntity(
        schemaVersion: 'v1',
        bundleId: 'preview_bundle',
        exportedAt: DateTime.utc(2026, 3, 10),
        sourceAppName: 'field_work_agent',
        sourceAppVersion: '0.1.0',
        scope: const ExportScope(type: 'all'),
        projects: const <Map<String, Object?>>[],
        tasks: const <Map<String, Object?>>[],
        meetings: const <Map<String, Object?>>[],
        people: const <Map<String, Object?>>[],
        attachmentsManifest: const <AttachmentManifestEntry>[],
      ),
      projectCount: 1,
      taskCount: 2,
      meetingCount: 1,
      peopleCount: 1,
      duplicateIds: const <String>['project_1'],
    );
  }

  @override
  Future<AppShellData> saveMeetingCandidateAsProvisional({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) async => data;

  @override
  Future<GroupedSearchResults> searchRecords({required SearchRequest request}) async {
    searchRequest = request;
    return const GroupedSearchResults(
      projects: <SearchHit>[],
      tasks: <SearchHit>[],
      meetings: <SearchHit>[
        SearchHit(
          recordType: 'meeting',
          recordId: 'meeting_1',
          title: 'Meeting transcript match',
          snippet: 'handover checklist appears in corrected transcript and summary.',
        ),
      ],
      rawCaptures: <SearchHit>[],
      people: <SearchHit>[],
    );
  }

  @override
  Future<AppShellData> updateMeetingCandidate({
    required String meetingId,
    required String candidateId,
    required MeetingTaskCandidateDraft draft,
    String? actorName,
  }) async {
    updatedCandidateDraft = draft;
    acceptedMeetingId = meetingId;
    acceptedCandidateId = candidateId;
    return data;
  }

  @override
  Future<AppShellData> updateMeetingDraft({
    required String meetingId,
    required MeetingReviewDraft draft,
    String? actorName,
  }) async {
    savedMeetingDraft = draft;
    return data;
  }

  @override
  Future<AppShellData> updateProject({required String projectId, required ProjectDraft draft, String? actorName}) async {
    createdProjectDraft = draft;
    return data;
  }

  @override
  Future<AppShellData> updateTask({required String taskId, required TaskDraft draft, String? actorName}) async {
    createdTaskDraft = draft;
    return data;
  }
}