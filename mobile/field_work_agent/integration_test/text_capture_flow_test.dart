import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:field_work_agent/app/app_runtime.dart';
import 'package:field_work_agent/app/app_shell.dart';
import 'package:field_work_agent/app/app_shell_controller.dart';
import 'package:field_work_agent/domain/entities/raw_capture_entity.dart';
import 'package:field_work_agent/domain/enums/raw_capture_channel.dart';
import 'package:field_work_agent/domain/enums/raw_capture_parse_status.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures text from home quick action', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      FieldWorkAgentApp(controller: _MutableTextCaptureController()),
    );
    await tester.pumpAndSettle();

    // Tap "Paste Text" quick action
    await tester.tap(find.widgetWithText(ActionChip, 'Paste Text'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Paste Text'), findsOneWidget);

    // Enter text in the dialog
    final textField = find.byType(TextField);
    await tester.enterText(textField, 'Inspect rainfall harvesting system');
    await tester.pumpAndSettle();

    // Tap "Capture" button
    await tester.tap(find.widgetWithText(FilledButton, 'Capture'));
    await tester.pumpAndSettle();

    // Verify success message
    expect(find.text('Text captured and added to Inbox.'), findsOneWidget);

    // Verify capture is in inbox
    await tester.tap(find.widgetWithText(InkWell, 'Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox Review Queue'), findsOneWidget);
    expect(find.text('Inspect rainfall harvesting system'), findsOneWidget);
  });
}

class _MutableTextCaptureController extends StaticAppShellController {
  _MutableTextCaptureController()
      : _currentData = const AppShellData.empty(),
        super(const AppShellData.empty());

  AppShellData _currentData;

  @override
  AppShellData get data => _currentData;

  @override
  Future<AppShellData> load() async => _currentData;

  @override
  Future<AppShellData> createRawTextCapture({
    required String textContent,
    String? actorName,
  }) async {
    final now = DateTime.now().toUtc();
    final id = 'capture-${DateTime.now().millisecondsSinceEpoch}';
    final capture = RawCaptureEntity(
      id: id,
      channel: RawCaptureChannel.manualText,
      captureTime: now,
      classificationType: 'unclassified',
      parseStatus: RawCaptureParseStatus.newCapture,
      createdAt: now,
      rawText: textContent,
    );
    _currentData = AppShellData(
      projects: _currentData.projects,
      tasks: _currentData.tasks,
      meetings: _currentData.meetings,
      rawCaptures: <RawCaptureEntity>[capture, ..._currentData.rawCaptures],
      reportRuns: _currentData.reportRuns,
      importRuns: _currentData.importRuns,
      exportRuns: _currentData.exportRuns,
    );
    return _currentData;
  }
}
