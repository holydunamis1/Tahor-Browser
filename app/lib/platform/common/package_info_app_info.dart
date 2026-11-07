import 'package:package_info_plus/package_info_plus.dart';

import '../../core/contracts/app_info.dart';

/// [AppInfo] over `package_info_plus`. The values are read once at start-up.
class PackageInfoAppInfo implements AppInfo {
  const PackageInfoAppInfo._(this.version, this.buildNumber);

  /// Reads the installed version. Falls back to `0.0.0` if the platform
  /// cannot answer, so a failure here never stops the app.
  static Future<PackageInfoAppInfo> load() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return PackageInfoAppInfo._(info.version, info.buildNumber);
    } on Exception {
      return const PackageInfoAppInfo._('0.0.0', '0');
    }
  }

  @override
  final String version;

  @override
  final String buildNumber;
}
