import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'error_taxonomy.dart';

/// One entry of the in-memory error log.
@immutable
class ErrorLogEntry {
  const ErrorLogEntry({
    required this.at,
    required this.error,
    this.stackSummary,
  });

  final DateTime at;
  final AppError error;

  /// The first lines of the stack trace.
  final String? stackSummary;
}

/// A bounded in-memory log. It is never written to disk and never sent
/// anywhere.
class ErrorLog {
  ErrorLog({this.capacity = 100}) : assert(capacity > 0);

  final int capacity;
  final Queue<ErrorLogEntry> _entries = Queue<ErrorLogEntry>();

  /// Oldest first.
  List<ErrorLogEntry> get entries => List<ErrorLogEntry>.unmodifiable(_entries);

  int get length => _entries.length;

  void add(ErrorLogEntry entry) {
    _entries.addLast(entry);
    while (_entries.length > capacity) {
      _entries.removeFirst();
    }
  }

  void clear() => _entries.clear();
}

typedef FatalErrorCallback = void Function(AppError error);

/// Catches every uncaught error, classifies it and records it.
class GlobalErrorHandler {
  GlobalErrorHandler({ErrorLog? log, DateTime Function()? clock, this.onFatal})
    : log = log ?? ErrorLog(),
      _clock = clock ?? DateTime.now;

  final ErrorLog log;
  final DateTime Function() _clock;

  /// Called for errors classified as fatal.
  final FatalErrorCallback? onFatal;

  /// Classifies, records and returns the error.
  AppError report(Object error, [StackTrace? stack, bool fromBuild = false]) {
    final AppError classified = AppError.classify(error, fromBuild: fromBuild);
    log.add(
      ErrorLogEntry(
        at: _clock(),
        error: classified,
        stackSummary: _summarize(stack),
      ),
    );
    if (!classified.isRecoverable) {
      onFatal?.call(classified);
    }
    return classified;
  }

  /// Hooks the framework and platform error callbacks.
  void install() {
    FlutterError.onError = (FlutterErrorDetails details) {
      report(details.exception, details.stack, true);
      assert(() {
        FlutterError.presentError(details);
        return true;
      }());
    };
    WidgetsBinding.instance.platformDispatcher.onError =
        (Object error, StackTrace stack) {
          report(error, stack);
          return true;
        };
  }

  static String? _summarize(StackTrace? stack) {
    if (stack == null) {
      return null;
    }
    return stack.toString().split('\n').take(12).join('\n');
  }
}

/// Runs [body] in a guarded zone with the handler installed, so no error
/// escapes unclassified.
void runGuarded(GlobalErrorHandler handler, Future<void> Function() body) {
  unawaited(
    runZonedGuarded<Future<void>>(() async {
      WidgetsFlutterBinding.ensureInitialized();
      handler.install();
      await body();
    }, (Object error, StackTrace stack) => handler.report(error, stack)),
  );
}
