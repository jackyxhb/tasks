import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_work_agent/app/app_sections.dart';
import 'package:field_work_agent/app/app_shell.dart';
import 'package:field_work_agent/app/app_shell_controller.dart';
import 'package:field_work_agent/app/section_screens.dart';

void main() {
  testWidgets('renders app shell home dashboard', (WidgetTester tester) async {
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
    expect(find.text('Inbox Review Queue'), findsNothing);
  });

  testWidgets('home quick action navigates to a working section', (
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

    await tester.tap(find.widgetWithText(ActionChip, 'Search'));
    await tester.pumpAndSettle();
    expect(find.text('Global Search'), findsOneWidget);
  });

  testWidgets('renders reports section surface', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionBody(
            section: AppSection.reports,
            data: AppShellData.empty(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report Templates'), findsOneWidget);
  });
}
