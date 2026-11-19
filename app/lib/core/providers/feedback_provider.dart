import 'dart:async';

import 'package:flutter/foundation.dart';

/// A short message shown after something the person did: copied, saved,
/// failed.
@immutable
class FeedbackMessage {
  const FeedbackMessage(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  bool operator ==(Object other) =>
      other is FeedbackMessage &&
      other.text == text &&
      other.isError == isError;

  @override
  int get hashCode => Object.hash(text, isError);
}

/// The message showing now, or null. Each one disappears by itself.
class FeedbackProvider extends ValueNotifier<FeedbackMessage?> {
  FeedbackProvider({this.visibleFor = const Duration(milliseconds: 2500)})
    : super(null);

  final Duration visibleFor;
  Timer? _timer;

  /// Shows [text], replacing any message already showing.
  void show(String text, {bool isError = false}) {
    _timer?.cancel();
    value = FeedbackMessage(text, isError: isError);
    _timer = Timer(visibleFor, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    value = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
