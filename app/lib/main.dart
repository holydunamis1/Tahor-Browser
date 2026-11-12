import 'package:flutter/widgets.dart';

import 'app/app_shell.dart';
import 'app/bootstrap.dart';
import 'core/app_scope.dart';
import 'core/error/global_error_handler.dart';

void main() {
  final GlobalErrorHandler errorHandler = GlobalErrorHandler();
  runGuarded(errorHandler, () async {
    final AppDependencies dependencies = await bootstrap(
      errorHandler: errorHandler,
    );
    runApp(AppScope(dependencies: dependencies, child: const AppShell()));
  });
}
