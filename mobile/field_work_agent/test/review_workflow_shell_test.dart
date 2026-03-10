import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_work_agent/domain/entities/export_run_entity.dart';
import 'package:field_work_agent/domain/entities/import_run_entity.dart';
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
import 'package:field_work_agent/features/meetings/application/meeting_review_models.dart';
import 'package:field_work_agent/features/projects/application/project_draft.dart';
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
  String? acceptedMeetingId;
  String? acceptedCandidateId;
  String? acceptedAgenteeName;

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
  Future<AppShellData> markCaptureReviewed({required String captureId, String? actorName}) async => data;

  @override
  Future<AppShellData> moveMeetingToManualReview({required String meetingId, String? actorName}) async => data;

  @override
  Future<AppShellData> archiveProject({required String projectId, String? actorName}) async => data;

  @override
  Future<AppShellData> archiveTask({required String taskId, String? actorName}) async => data;

  @override
  Future<AppShellData> rejectMeetingCandidate({required String meetingId, required String candidateId, String? actorName}) async =>
      data;

  @override
  Future<AppShellData> saveMeetingCandidateAsProvisional({
    required String meetingId,
    required String candidateId,
    required String agenteeName,
    String? actorName,
  }) async => data;

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