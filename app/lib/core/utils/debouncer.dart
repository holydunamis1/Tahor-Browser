import 'dart:async';

/// Runs only the last of many quickly repeated calls.
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;
  void Function()? _pending;

  bool get isPending => _timer?.isActive ?? false;

  /// Schedules [action] after [delay], replacing any earlier scheduled one.
  void run(void Function() action) {
    _timer?.cancel();
    _pending = action;
    _timer = Timer(delay, _fire);
  }

  /// Drops the scheduled action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }

  /// Runs the scheduled action now, if there is one.
  void flush() {
    if (_pending != null) {
      _timer?.cancel();
      _fire();
    }
  }

  void dispose() => cancel();

  void _fire() {
    final void Function()? action = _pending;
    _pending = null;
    _timer = null;
    action?.call();
  }
}
