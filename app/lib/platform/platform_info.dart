import 'dart:io' show Platform;

/// Which system the app is running on. The only place that asks `dart:io`.
class PlatformInfo {
  const PlatformInfo({required this.isAndroid, required this.isIOS});

  /// The system this process runs on.
  factory PlatformInfo.current() =>
      PlatformInfo(isAndroid: Platform.isAndroid, isIOS: Platform.isIOS);

  final bool isAndroid;
  final bool isIOS;
}
