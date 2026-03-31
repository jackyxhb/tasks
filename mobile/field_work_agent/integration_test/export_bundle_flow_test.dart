import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:field_work_agent/app/app_runtime.dart';
import 'package:field_work_agent/app/app_shell.dart';
import 'package:field_work_agent/app/app_shell_controller.dart';
import 'package:field_work_agent/domain/entities/export_run_entity.dart';
import 'package:field_work_agent/domain/entities/import_export_bundle_entity.dart';
import 'package:field_work_agent/domain/entities/import_run_entity.dart';
import 'package:field_work_agent/domain/entities/meeting_entity.dart';
import 'package:field_work_agent/domain/entities/project_entity.dart';
import 'package:field_work_agent/domain/entities/raw_capture_entity.dart';
import 'package:field_work_agent/domain/entities/report_run_entity.dart';
import 'package:field_work_agent/domain/entities/task_entity.dart';
import 'package:field_work_agent/features/exchange/application/exchange_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('generates an export bundle and records it in recent exports', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      FieldWorkAgentApp(controller: _MutableExportController()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, 'Export'));
    await tester.pumpAndSettle();

    expect(find.text('Export Builder'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Bundle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('March bundle'), findsOneWidget);
    expect(find.text('all'), findsOneWidget);
  });
}

class _MutableExportController extends StaticAppShellController {
  _MutableExportController()
      : _currentData = AppShellData(
          projects: const <ProjectEntity>[],
          tasks: const <TaskEntity>[],
          meetings: const <MeetingEntity>[],
          rawCaptures: const <RawCaptureEntity>[],
          reportRuns: const <ReportRunEntity>[],
          importRuns: const <ImportRunEntity>[],
          exportRuns: const <ExportRunEntity>[],
        ),
        super(const AppShellData.empty());

  AppShellData _currentData;

  @override
  AppShellData get data => _currentData;

  @override
  Future<AppShellData> load() async => _currentData;

  @override
  Future<ImportExportBundleEntity> createExportBundle({
    required ExportScopeRequest scope,
    String? actorName,
  }) async {
    final bundle = ImportExportBundleEntity(
      schemaVersion: 'v1',
      bundleId: 'bundle-001',
      exportedAt: DateTime.utc(2026, 3, 11, 9),
      sourceAppName: 'field_work_agent',
      sourceAppVersion: '0.1.0',
      scope: ExportScope(type: scope.type, value: scope.value),
      projects: const <Map<String, Object?>>[
        <String, Object?>{'id': 'project-1', 'name': 'Pompallier Wharf'},
      ],
      tasks: const <Map<String, Object?>>[
        <String, Object?>{'id': 'task-1', 'title': 'Inspect storm drains'},
      ],
      meetings: const <Map<String, Object?>>[],
      people: const <Map<String, Object?>>[
        <String, Object?>{'name': 'Harper Fielding'},
      ],
      attachmentsManifest: const <AttachmentManifestEntry>[],
    );

    _currentData = AppShellData(
      projects: _currentData.projects,
      tasks: _currentData.tasks,
      meetings: _currentData.meetings,
      rawCaptures: _currentData.rawCaptures,
      reportRuns: _currentData.reportRuns,
      importRuns: _currentData.importRuns,
      exportRuns: <ExportRunEntity>[
        ExportRunEntity(
          id: 'export-1',
          bundleName: 'March bundle',
          bundlePath: 'exports/bundle-001.json',
          exportScopeType: scope.type,
          exportScopeValue: scope.value,
          createdAt: DateTime.utc(2026, 3, 11, 9),
        ),
        ..._currentData.exportRuns,
      ],
    );

    return bundle;
  }
}
