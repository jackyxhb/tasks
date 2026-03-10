import 'package:flutter_test/flutter_test.dart';

import 'package:field_work_agent/src/app_runtime.dart';
import 'package:field_work_agent/src/app_shell.dart';

void main() {
  testWidgets('renders app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const FieldWorkAgentApp(
        controller: StaticAppShellController(AppShellData.empty()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily operations at a glance'), findsOneWidget);
  });
}
