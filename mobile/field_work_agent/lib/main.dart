import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app_shell.dart';
import 'app/app_shell_controller.dart';
import 'app/web_app_runtime.dart'
    if (dart.library.js_util) 'app/web_app_runtime_stub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    final controller = await createWebController();
    runApp(FieldWorkAgentApp(controller: controller));
  } else {
    runApp(const FieldWorkAgentApp());
  }
}
