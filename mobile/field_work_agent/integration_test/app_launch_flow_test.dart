import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:field_work_agent/app/app_runtime.dart';
import 'package:field_work_agent/app/app_shell.dart';
import 'package:field_work_agent/app/app_shell_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches app shell and navigates across core sections', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const FieldWorkAgentApp(
        controller: StaticAppShellController(AppShellData.empty()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily operations at a glance'), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, 'Inbox'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox Review Queue'), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, 'Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Task Board'), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, 'Meetings'));
    await tester.pumpAndSettle();
    expect(find.text('Meeting Review Board'), findsOneWidget);

    await tester.tap(find.widgetWithText(InkWell, 'Projects'));
    await tester.pumpAndSettle();
    expect(find.text('Projects At A Glance'), findsOneWidget);
  });
}
