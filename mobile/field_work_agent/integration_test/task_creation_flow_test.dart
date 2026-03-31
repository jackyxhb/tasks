import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:field_work_agent/app/app_runtime.dart';
import 'package:field_work_agent/app/app_shell.dart';
import 'package:field_work_agent/domain/entities/task_entity.dart';
import 'package:field_work_agent/features/tasks/application/task_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates a task through the live shell flow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      FieldWorkAgentApp(controller: _MutableTaskController()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, 'Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Task Board'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'New Task').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'New Task'), findsOneWidget);

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Inspect storm drains');
    await tester.enterText(textFields.at(2), _todayLabel());
    await tester.enterText(textFields.at(9), 'Harper Fielding');

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Task created.'), findsOneWidget);
    expect(find.text('Inspect storm drains'), findsOneWidget);
  });
}

class _MutableTaskController extends StaticAppShellController {
  _MutableTaskController()
      : _currentData = const AppShellData.empty(),
        super(const AppShellData.empty());

  AppShellData _currentData;
  int _nextTaskId = 1;

  @override
  AppShellData get data => _currentData;

  @override
  Future<AppShellData> load() async => _currentData;

  @override
  Future<AppShellData> createTask({
    required TaskDraft draft,
    String? actorName,
  }) async {
    final now = DateTime.now().toUtc();
    final task = TaskEntity(
      id: 'integration-task-${_nextTaskId++}',
      projectId: draft.projectId,
      taskType: draft.taskType,
      taskTitle: draft.taskTitle,
      taskTitleNormalized: draft.taskTitle?.trim().toLowerCase(),
      description: draft.description,
      scheduledDate: draft.scheduledDate,
      startTimeLocal: draft.startTimeLocal,
      durationMinutes: draft.durationMinutes,
      locationSnapshot: draft.locationSnapshot,
      workerName: draft.workerName,
      workerPhone: draft.workerPhone,
      coordinatorName: draft.coordinatorName,
      projectManagerName: draft.projectManagerName,
      agenteeName: draft.agenteeName,
      status: draft.status,
      priority: draft.priority,
      sourceCaptureId: draft.sourceCaptureId,
      dedupKey: null,
      isProvisional: draft.isProvisional,
      needsReview: draft.needsReview,
      createdAt: now,
      updatedAt: now,
      archivedAt: null,
    );
    _currentData = _copyData(
      _currentData,
      tasks: <TaskEntity>[task, ..._currentData.tasks],
    );
    return _currentData;
  }
}

AppShellData _copyData(
  AppShellData data, {
  List<TaskEntity>? tasks,
}) {
  return AppShellData(
    projects: data.projects,
    tasks: tasks ?? data.tasks,
    meetings: data.meetings,
    rawCaptures: data.rawCaptures,
    reportRuns: data.reportRuns,
    importRuns: data.importRuns,
    exportRuns: data.exportRuns,
  );
}

String _todayLabel() {
  final now = DateTime.now();
  final year = now.year.toString().padLeft(4, '0');
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}