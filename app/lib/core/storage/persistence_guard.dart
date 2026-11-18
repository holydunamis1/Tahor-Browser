import 'package:flutter/foundation.dart';

import '../error/error_taxonomy.dart';

/// Turns any storage failure into a fallback value and a warning, so a broken
/// disk never breaks the app.
///
/// [failedAreas] names the parts of the app whose data may not survive a
/// restart; the interface shows a banner while it is not empty.
class PersistenceGuard {
  PersistenceGuard({void Function(AppError error)? onError})
    : _onError = onError;

  final void Function(AppError error)? _onError;

  /// The areas that have failed since the last [reset].
  final ValueNotifier<Set<String>> failedAreas = ValueNotifier<Set<String>>(
    const <String>{},
  );

  bool get isDegraded => failedAreas.value.isNotEmpty;

  /// Runs [action]. When it throws, records the failure for [area] and returns
  /// [fallback]. Pass [write] for operations that save.
  Future<T> run<T>(
    String area,
    Future<T> Function() action, {
    required T Function() fallback,
    bool write = false,
  }) async {
    try {
      return await action();
    } on Exception catch (error) {
      report(area, error, write: write);
    } on TypeError catch (error) {
      // Plugins throw this when a stored value has another type than asked for.
      report(area, error, write: write);
    } on StateError catch (error) {
      report(area, error, write: write);
    }
    return fallback();
  }

  /// Records a failure that was handled elsewhere.
  void report(String area, Object error, {bool write = false}) {
    final AppError classified = error is AppError
        ? error
        : (write
              ? StorageError.writeFailed(detail: '$area: $error')
              : StorageError.readFailed(detail: '$area: $error'));
    _onError?.call(classified);
    if (!failedAreas.value.contains(area)) {
      failedAreas.value = Set<String>.unmodifiable(<String>{
        ...failedAreas.value,
        area,
      });
    }
  }

  /// Forgets earlier failures, for example once the person has seen the banner.
  void reset() {
    if (failedAreas.value.isNotEmpty) {
      failedAreas.value = const <String>{};
    }
  }
}
