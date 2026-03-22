import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app_shell.dart';
import 'app/web_app_runtime.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    final controller = await createWebAppShellController();
    runApp(FieldWorkAgentApp(controller: controller));
  } else {
    runApp(const FieldWorkAgentApp());
  }
}
