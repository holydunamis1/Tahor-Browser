import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';
import 'package:tahorbrowser/core/error/global_error_handler.dart';

void main() {
  group('ErrorLog', () {
    test('keeps the newest entries up to its capacity', () {
      final ErrorLog log = ErrorLog(capacity: 3);
      for (int i = 0; i < 5; i++) {
        log.add(
          ErrorLogEntry(
            at: DateTime(2026, 11, 1, 0, i),
            error: UnexpectedError.async('e$i'),
          ),
        );
      }
      expect(log.length, 3);
      expect(log.entries.map((ErrorLogEntry e) => e.error.detail), <String?>[
        'e2',
        'e3',
        'e4',
      ]);
    });

    test('defaults to 100 entries and can be cleared', () {
      final ErrorLog log = ErrorLog();
      expect(log.capacity, 100);
      for (int i = 0; i < 150; i++) {
        log.add(
          ErrorLogEntry(
            at: DateTime(2026),
            error: const NetworkError.offline(),
          ),
        );
      }
      expect(log.length, 100);
      log.clear();
      expect(log.length, 0);
    });

    test('the entries list cannot be modified from outside', () {
      final ErrorLog log = ErrorLog();
      expect(
        () => log.entries.add(
          ErrorLogEntry(
            at: DateTime(2026),
            error: const NetworkError.offline(),
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('GlobalErrorHandler', () {
    test('report classifies, stamps and records', () {
      final DateTime stamp = DateTime(2026, 11, 1, 9);
      final GlobalErrorHandler handler = GlobalErrorHandler(clock: () => stamp);
      final AppError e = handler.report(StateError('boom'), StackTrace.current);
      expect(e.code, 'unexpected.async');
      expect(handler.log.length, 1);
      expect(handler.log.entries.single.at, stamp);
      expect(handler.log.entries.single.stackSummary, isNotEmpty);
    });

    test('the stack summary is limited to twelve lines', () {
      final GlobalErrorHandler handler = GlobalErrorHandler();
      handler.report(
        StateError('x'),
        StackTrace.fromString(
          List<String>.generate(40, (int i) => 'frame $i').join('\n'),
        ),
      );
      expect(handler.log.entries.single.stackSummary!.split('\n').length, 12);
    });

    test('onFatal fires for fatal errors only', () {
      final List<AppError> fatal = <AppError>[];
      final GlobalErrorHandler handler = GlobalErrorHandler(onFatal: fatal.add);
      handler.report(StateError('background'));
      handler.report(const NetworkError.offline());
      handler.report(StateError('build'), null, true);
      expect(fatal.map((AppError e) => e.code), <String>['unexpected.build']);
      expect(handler.log.length, 3);
    });

    testWidgets('install hooks the framework error callback', (
      WidgetTester tester,
    ) async {
      final GlobalErrorHandler handler = GlobalErrorHandler();
      final void Function(FlutterErrorDetails)? originalFlutter =
          FlutterError.onError;
      final dynamic dispatcher = WidgetsBinding.instance.platformDispatcher;
      final dynamic originalDispatcher = dispatcher.onError;
      try {
        handler.install();
        FlutterError.onError!(
          FlutterErrorDetails(exception: StateError('boom')),
        );
        expect(handler.log.length, 1);
        expect(handler.log.entries.single.error.code, 'unexpected.build');
      } finally {
        FlutterError.onError = originalFlutter;
        dispatcher.onError = originalDispatcher;
      }
    });
  });
}
